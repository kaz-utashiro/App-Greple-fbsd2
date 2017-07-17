package Bombay::RoffDoc;

use utf8;
use strict;
use warnings;
use Encode;
use Encode::Guess;
Encode::Guess->set_suspects(qw/euc-jp/);

use Carp;
use Data::Dumper;
use List::Util qw(min max);

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

our $debug;

END { }

{
    package LabeledRegionList;
    use Data::Dumper;

    sub new {
	my $class = shift;
	my $obj = bless { }, $class;
	$obj->create(@_) if @_;
	$obj;
    }
    sub create {
	my $obj = shift;
	map { $obj->{$_} = [] } @_;
	$obj;
    }
    sub getRef {
	my($obj, $tag) = @_;
	$obj->{$tag};
    }
    sub expandTag {
	my $obj = shift;
	map {
	    if (ref $_ eq 'Regexp') {
		my $re = $_;
		grep { /$re/ } $obj->tags;
	    } else {
		$_;
	    }
	} @_;
    }
    sub getList {
	my $obj = shift;
	my @tags = $obj->expandTag(@_);
	map { @{$obj->getRef($_)} } @tags;
    }
    sub getTaggedList {
	my $obj = shift;
	my @tags = $obj->expandTag(@_);
	my @list;
	for my $tag (@tags) {
	    my @l = $obj->getList($tag);
	    @l = map { [ @$_, $tag ] } @l;
	    push @list, @l;
	}
	@list;
    }
    sub getItem {
	my($obj, $tag, $index) = @_;
	$obj->getRef($tag)->[$index];
    }
    sub getSortedList {
	my $obj = shift;
	do {
	    sort { $a->[0] <=> $b->[0] }
	    map  { $obj->getList($_) }
	    @_;
	};
    }
    sub enhance ($$$) {
	my($obj, $tag, $ent) = @_;
	my $ref = $obj->getRef($tag);
	if (@$ref == 0) {
	    push @$ref, $ent;
	} else {
	    $ref->[-1] = [ $ref->[-1][0], $ent->[1] ];
	}
    }
    sub push {
	my $obj = shift;
	my $tag = shift;
	my $list = $obj->getRef($tag) or die "$tag: invalid name\n";
	CORE::push @$list, @_;
    }
    sub clean {
	my $obj = shift;
	for my $key (keys %$obj) {
	    @{$obj->{$key}} = ();
	}
    }
    sub tags {
	sort keys %{+shift};
    }
}

my @regions = qw(macro mark e j comment retain gap egjp eg jp com1 com2 com3);
my @all =     qw(macro mark e j comment retain gap);

sub new {
    my $class = shift;
    my %arg = @_;
    my $obj = bless { }, $class;
    my $text;

    if (my $file = $arg{FILE}) {
	open F, $file or croak "$file: $!";
	binmode F, "encoding(guess)";
	$text = do { local $/; <F> };
	close F;
    }
    elsif ($arg{TEXT}) {
	$text = $arg{TEXT};
    }

    if (my $name = $arg{NAME} // $arg{FILE}) {
	my $prefix = $arg{PREFIX} // "";
	$name =~ s/\.\w+$//;
	$name =~ s{/}{:}g;
	$arg{LABEL} = "${prefix}${name}:%04d";
    }

    $obj->{TEXT} = $text;
    $obj->{REGION} = new LabeledRegionList @regions;
    $obj->set_data(LABEL => $arg{LABEL});

    $obj;
}

sub region {
    my $obj = shift;
    $obj->{REGION};
}

sub text {
    my $obj = shift;
    $obj->{TEXT};
}

sub part {
    my $obj = shift;
    my %arg = @_;

    if (exists $arg{all}) {
	my $val = delete $arg{all};
	map { $arg{$_} = $val } @all;
    }

    my @posi = grep $arg{$_}, grep /^[\w:]+$/, keys %arg;
    my @nega = map { s/^-//r } grep /^-/, keys %arg;

    my @part = do {
	if (@nega) {
	    my %nega = map { ($_, 1) } @nega;
	    grep { not $nega{$_} } @posi ? @posi : @all;
	} else {
	    @posi;
	}
    };

    $obj->{REGION}->getSortedList(@part);
}

sub get_text {
    my $obj = shift;
    my %arg = @_;

    my $part = $arg{PART} or die;

    my @r = $obj->{REGION}->getList($part);
    map {
	my($offset, $length) = ($_->[0], $_->[1] - $_->[0]);
	substr $obj->{TEXT}, $offset, $length;
    } @r;
}

{
    package LABEL;
    use Data::Dumper;
    sub new {
	my $class = shift;
	my $obj = bless { SENTENCE => 1, @_ }, $class;
	$obj;
    }
    sub incr { shift->{SENTENCE}++ }
    sub decr { shift->{SENTENCE}-- }
    sub new_label {
	my $obj = shift;
	sprintf $obj->{FORMAT}, $obj->{SENTENCE}++;
    }
    sub last_label {
	my $obj = shift;
	sprintf $obj->{FORMAT}, $obj->{SENTENCE} - 1;
    }
}

sub set_data {
    my $obj = shift;
    my %arg = @_;
    my $region = $obj->{REGION};
    my $pos = 0;

    local *_ = \$obj->{TEXT};

    my $labeler = $arg{LABEL} && new LABEL ( FORMAT => $arg{LABEL} );
    my $label;
    while (m{	\G
		(?<macro>    (?s:.*?) )
		(?<start_eg> ^\.EG.*\n) (?<eg> (?s:.*?\n))
		(?<start_jp> ^\.JP.*\n) (?<jp> (?s:.*?\n))
		(?<end>      ^\.EJ.*    (?:\n|\z))
	}mgx) {

	$pos = pos();

	$region->push("macro", [ $-[1], $+[1] ]) if $-[1] != $+[1];
	$region->push("mark",
		      [ $-[2], $+[2] ], [ $-[4], $+[4] ], [ $-[6], $+[6] ]);

	my $eg = [ $-[3], $+[3] ];
	my $jp = [ $-[5], $+[5] ];
	my $trans = $+{jp};

	if ($trans !~ /\n\n/) {
	    $region->push("egjp", [ $eg->[0], $jp->[1] ]);
	    $region->push("e", $eg);
	    $region->push("j", $jp);
	    $region->push("eg", $eg);
	    $region->push("jp", $jp);
	    if ($labeler) {
		$label = $labeler->new_label;
		$region->create($label, "$label:e", "$label:j");
		$region->push("$label:e", $eg);
		$region->push("$label:j", $jp);
		$region->push($label, $eg, $jp);
	    }
	    next;
	}

	$region->push("retain", $eg);

	my($s, $e) = @$jp;
	my $i = 0;
	my $lang = sub { qw(e j)[$i] };
	my $part = sub { qw(eg jp)[$i] };
	my $toggle = sub { $i ^= 1 };
	while ($trans =~ /^((?<kome>(?>※*)).*?\n)(\n+|\z)/smg) {
	    my $ent = [ $s + $-[1], $s + $+[1] ];
	    my $gap = [ $s + $-[3], $s + $+[3] ];
	    $region->push("gap", $gap) if $gap->[0] != $gap->[1];
	    if ($+{kome}) {
		my $level = min(length $+{kome}, 3);
		&$toggle;
		$region->push("comment", $ent);
		$region->push("com".$level, $ent);
		$region->enhance(&$part, $ent);
		$region->enhance("egjp", $ent);
		$region->push($label, $ent) if $label;
		$region->push(join(':', $label, &$lang), $ent) if $label;
	    } else {
		$region->push(&$lang, $ent);
		$region->push(&$part, $ent);
		if (&$lang eq 'e') {
		    $region->push("egjp", $ent);
		    if ($labeler) {
			$label = $labeler->new_label;
			$region->create($label, "$label:e", "$label:j");
		    }
		    $region->push($label, $ent) if $label;
		    $region->push("$label:e", $ent) if $label;
		} else {
		    $region->enhance("egjp", $ent);
		    $region->push($label, $ent) if $label;
		    $region->push("$label:j", $ent) if $label;
		}
	    }
	    &$toggle;
	}
    }

    if ($pos > 0 and $pos != length) {
	$region->push("macro", [ $pos, length ]);
    }
}

1;
