package Bombay::Compare;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw($sap_max
		      &sap_score &sap_matchlist &open_dict
		      &open_lmap
		      );
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use utf8;
use Encode;

use Carp;
$Data::Dumper::Terse = 1;
use Data::Dumper;
use List::Util qw( min max sum reduce );
use JSON;
use Data::Dumper;

use Bombay;

our $sap_max = 10;
our $sap_promote = 1;
our $sap_uniqlist = 1;

use constant {
    INDEX_LABEL  => 0,
    INDEX_TEXT   => 1,
    INDEX_NUMBER => 2,
    INDEX_LIST   => 3,
    INDEX_DICT   => 4,
};

sub new {
    my($proto, %arg) = @_;
    my $class = ref($proto) || $proto;
    my $self = bless [], $class;

    $self->label($arg{Label});
    $self->text($arg{Text});

    if ($arg{Dict}) {
	my @list = wordlist($arg{Text});
	my $number = scalar @list;
	my $dict = worddict($arg{Text});
	$self->number($number);
	$self->list(\@list);
	$self->dict($dict);
    }

    $self;
}

sub label {
    my $self = shift;
    @_  ? $self->[INDEX_LABEL] = shift
	: $self->[INDEX_LABEL];
}

sub text {
    my $self = shift;
    @_  ? $self->[INDEX_TEXT] = shift
	: $self->[INDEX_TEXT];
}

sub number {
    my $self = shift;
    @_  ? $self->[INDEX_NUMBER] = shift
	: $self->[INDEX_NUMBER];
}

sub list {
    my $self = shift;
    @_  ? $self->[INDEX_LIST] = shift
	: @{$self->[INDEX_LIST]};
}

sub dict {
    my $self = shift;
    @_  ? $self->[INDEX_DICT] = shift
	: $self->[INDEX_DICT];
}

sub lookup {
    my $self = shift;
    my $key = shift;
    $self->dict->{$key};
}

sub sap_score {
    my($a, $b) = @_;
    my @list = distance_list($a, $b);
    if (@list == 0) {
	warn Dumper $a, $b;
	die;
    }

    if ($sap_promote and @list > 1) {
	@list = promote_seriese(@list);
    }

    my $n = max($a->number, $b->number);
    my $score = sum( map
		     { defined $_ ? $n - abs($_) : 0 }
		     @list );

    die if not defined $score;
    int($score * 100 / ($n * $n));
}

sub promote_seriese {
    ##
    ## 前の要素と値が同じであれば 0 にする
    ##
    map { $_[$_] = 0 }
    grep {
	defined $_[$_-1] and defined $_[$_] and $_[$_-1] == $_[$_]
    }
    1 .. $#_;
    @_;
}

sub dumplist {
    my $obj = shift;
    local $_ = Dumper $obj;
    s/\n(?!\z)/ /g;
    s/undef/-/g;
    $_;
}

sub distance_list {
    goto &distance_list_nouniq;
}

sub distance_list_nouniq {
    my($x, $y) = @_;
    my @list = $x->list;
    map {
	my $lookup = $y->lookup($list[$_]);
	my $i = $_;
	if (defined $lookup) {
	    my $j;
	    if (ref($lookup) eq 'ARRAY') {
		##
		## インデックスが複数あれば差が最小のものを選択
		##
		$j = reduce {
		    abs($i - $a) < abs($i - $b) ? $a : $b
		} @{$lookup};
	    } else {
		$j = $lookup;
	    }
	    $i - $j;
	} else {
	    undef;
	}
    } 0 .. $#list;
}

sub distance_list_uniq {
    my($a, $b) = @_;
    map {
	defined($b->lookup($_))
	    ? $a->lookup($_) - $b->lookup($_)
	    : undef;
    }
    $a->list;
}

sub sap_matchlist {
    my($item, $list, %arg) = @_;
    my $min = $arg{Min} // 1;
    my $max = $arg{Max} // 100;

    sort { $b->[0] <=> $a->[0] }
    grep { $min <= $_->[0] and $_->[0] <= $max }
    map  { [ sap_score($item, $_), $_ ] }
    @$list;
}

my $ignore_re;
my $decorate_re;

sub mkpat {
    my @macro = @_;
    my $pat = join '|', @ignore;
    qr/$pat/;
}

BEGIN {
    $ignore_re = mkpat qw(EG JP EG IX ss Bl);
    $decorate_re = mkpat qw(RN Rn Sm GL Gl SC);
}

my uniq {
    my %seen;
    grep { not $seen{$_}++ } @_;
}

sub roff_wordlist {
    my $text = shift;

    for ($text) {
	s/^\.\\".*\n//gm;
	s/^\.(?:$ignore_re).*\n//gm;
	s{
	    ^\. (?:$decorate_re) \b \s*
	    " ([^"]*) "		# "..."
	    |
	    (\S*)		# 空白以外の連続
	    .*\n
	}{
	    $1 // $2 // ""
	}xgme;
    }

    my @words = map({ lc $_ } $text =~ /(\w+)/g);

    @words = uniq @words if $sap_uniqlist;

    if ($sap_max > 0 and @words > $sap_max) {
	@words = sort { length $b <=> length $a or $a cmp $b } @words;
	splice(@words, $sap_max) if @words > $sap_max;
    }

    @words;
}

sub wordlist {
    goto roff_wordlist;
}

sub worddict {
    my $text = shift;
    my @words = wordlist $text;
    my %dict;
    for (0 .. $#words) {
	my $word = $words[$_];
	$dict{$word} //= [];
	push @{$dict{$word}}, $_;
    }
    \%dict;
}

sub sap_slist {
    my $node = shift;
    my %arg = @_;
    my $attr = $node->attr;
    my @list;
    my $label;

    return undef if ref $node ne "Bombay::Node";

    if ($label = $attr->{Label}) {
	my $text = join '', map { $_->gettext() } $node->childlist;

	##
	## remove and remember foontotes
	##
	my @footnote;
	while ($text =~ s{<footnote>\s*(.*?)\s*</footnote>}{}g) {
	    push @footnote, $1;
	}

	##
	## push the node
	##
	push @list, __PACKAGE__->new(Label => $label,
				     Text => $text,
				     Dict => $arg{Dict});

	##
	## push footnotes
	##
	for my $i (0 .. $#footnote) {
	    my $fnlabel = sprintf "%s:FN%d", $label, $i;
	    push @list, __PACKAGE__->new(Label => $fnlabel,
					 Text => $footnote[$i],
					 Dict => $arg{Dict});
	}
    }
    else {
	for my $child ($node->childlist) {
	    next if $child->istext;
	    my $listp = sap_slist($child, %arg);
	    push @list, @$listp;
	}
    }

    \@list;
}

sub open_dict {
    my $file = shift;
    my $slist = get_json($file);
    for (@$slist) {
	bless $_, __PACKAGE__;
    }
    $slist;
}

sub get_json {
    my $file = shift;

    open(JSON, $file) or die "$file: $!\n";
    my $json_text = do { local $/; <JSON> } ;
    close JSON;

    my $obj = from_json($json_text, { utf8 => 1 }) or die;

    $obj;
}

sub TO_JSON {
    my $self = shift;
    [ @$self ];
}

sub open_lmap {
    my $file = shift;
    open FH, $file or croak "$file: $!";
    my @result;
    while (<FH>) {
	my @l = split;
	my $label = @l > 0 ? shift @l : die Dumper \@l;
	my @data;
	if (@l > 0) {
	    @l % 2 == 0 or die "Data error: $_";
	    @data = map { [ splice @l, 0, 2 ] } 0 .. $#l / 2 ;
	}
	push @result, [ $label, @data ];
    }
    close FH;
    @result;
}

1;
