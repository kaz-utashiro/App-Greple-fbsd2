package Bombay::Dict;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw(
	$sap_max $sap_promote $sap_uniqlist
	&open_slist &sap_matchlist
);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

use utf8;
use Encode;

use Carp;
$Data::Dumper::Terse = 1;
use Data::Dumper;
use List::Util qw( min max sum reduce );

use Bombay::Dict::BsdRoff qw(wordlist);

our $json_version = do {
    0 or eval {
	require JSON;
	import  JSON;
	"JSON";
    } or eval {
	require JSON::PP;
	import  JSON::PP;
	"JSON::PP";
    } or eval {
	require Cpanel::JSON::XS;
	import  Cpanel::JSON::XS;
	"Cpanel::JSON::XS";
    } or do {
	die;
    };
};

our $sap_max = -1;
our $sap_promote = 1;
our $sap_uniqlist = 0;

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
	return 0;
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

sub worddict {
    my $text = shift;
    my @words = wordlist($text);
    my %dict;
    for (0 .. $#words) {
	my $word = $words[$_];
	$dict{$word} //= [];
	push @{$dict{$word}}, $_;
    }
    \%dict;
}

sub open_slist {
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

    return [] if $json_text eq "";

    my $obj = decode_json($json_text) or die;

    $obj;
}

sub TO_JSON {
    my $self = shift;
    [ @$self ];
}

1;
