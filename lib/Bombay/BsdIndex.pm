package Bombay::BsdIndex;

use v5.14;
use warnings;
use utf8;
use open IO => 'utf8', ':std';

use Carp;
use Data::Dumper;
use App::tbl2latex::Util;

my @jindex;
my @phonetic;

my $myself = $0;
my $mydir  = $myself =~ s|/[^/]+$||r;

my $indexdir  = "$mydir/../c17.index";
my $indexlist = "$indexdir/INDEX_LIST";
my $indexmap  = "$indexdir/INDEX_MAP";

my $gindex;
my %yomi;	# 日本語項目とそれの読みを格納するハッシュ

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $index = bless {}, $class;

    $gindex = $index;
    bless $gindex, $class;

    open(LIST, $indexlist) or die "No $indexlist file.\n";
    open(MAP, $indexmap) or die "No $indexmap file.\n";

    my @list = <LIST>; chomp @list;
    my @map = <MAP>; chomp @map;
    if (@list != @map) {
	croak "wrong entry number";
    }

    for my $i (keys @map) {
	my @map = split /\t+/, $map[$i];
	push @jindex, $map[0];
	push @phonetic, $map[1];
	$index->{$list[$i]} = new IndexObj($list[$i], @map);
    }

    for (@map) {
	my($jindex, $yomi) = split /\t+/, $_;
	my @jindex = $jindex =~ /(\P{ASCII}+)/g;
	$yomi //= $jindex;
	my @yomi = $yomi =~ /(\P{ASCII}+)/g;

	if (@jindex != @yomi) {
	    warn "number unmatch \"$_\"\n";
	}
	@yomi{@jindex} = @yomi;
    }
    $index;
}

sub keys {
    my $obj = shift;
    keys %$obj;
}

sub index {
    my $obj = shift;
    my $s;
    my $range = '';

    my @arg = @_;

    if ($arg[0] eq 'istart' or $arg[0] eq 'iend') {
	$range = shift @arg;
    }

    for (@arg) {
	s/\\\&//g;
	s/\\s-?\d//g;
    }

    if (@arg == 1) {
	local($_) = $arg[0];
	if (/^([A-Z][a-z]+),~([A-Z][a-z]+)$/) {		# 人名
	    $s = bsdindex("$1, $2");
	}
	elsif (/^Babao.*,*Ozalp$/) {			# 特別!!!
	    $s = bsdindex("Babao\\~glu, Ozalp");
	}
	elsif ($arg[0] =~ /^(.*),~(.*)$/) {
	    my($l1, $l2) = ($1, $2);
	    $s = _index2($l1, $l2);
	} else {
	    $s = _index1($arg[0]);
	}
    }
    elsif (@arg == 2) {
	carp "unexpected .IX args" if $arg[0] =~ /,~/;
	if ($range eq 'iend') {
	    $s .= _index2(@arg[1,0]);
	    $s .= _index2(@arg[0,1]);
	} else {
	    $s .= _index2(@arg[0,1]);
	    $s .= _index2(@arg[1,0]);
	}
    }
    else {
	carp "too many argument in .IX: @_";
    }

    if ($range eq 'istart') {
	$s =~ s://}:|(//}:g;
    } elsif ($range eq 'iend') {
	$s =~ s://}:|)//}:g;
    }

    $s;
}

my %var_table;
BEGIN {
    %var_table = (
	'$Bs' => 'BSD',
	'$Bv' => '3BSD',
	'$Bx' => '4BSD',
	'$b0' => '4.0BSD',
	'$b1' => '4.1BSD',
	'$b2' => '4.2BSD',
	'$b3' => '4.3BSD',
	'$b4' => '4.4BSD',
	'$4L' => '4.4BSD-Lite',
	'$Ob' => 'OpenBSD',
	'$Nb' => 'NetBSD',
	'$Fb' => 'FreeBSD',
	'$F3' => 'FreeBSD 3',
	'$F4' => 'FreeBSD 4',
	'$F5' => 'FreeBSD 5',
	'$F6' => 'FreeBSD 6',
	'$F7' => 'FreeBSD 7',
	'$F8' => 'FreeBSD 8',
	'$F9' => 'FreeBSD 9',
	'$F0' => 'FreeBSD 10',
	'$s5' => 'System V',
	'$Ps' => 'POSIX',
	'$Px' => 'POSIX',
	'$UX' => 'UNIX',
	'$VX' => 'VAX',
	'$PC' => 'PC',
	'$X8' => 'x86',
	'$Zf' => 'ZFS',
	'$Lx' => 'Linux',
    );
}

sub replace_vars {
    my $sp = shift;
    $$sp =~ s/(\$..)/$var_table{$1} || $1/ge;
}

sub _index1 {
    local($_) = @_;
    s/^!//;
    $_ = j($_);
    if (/^(.+),~?(.+)$/) {
	_index2($1, $2);
    }
    else {
	bsdindex(index_entry(j($_)));
    }
}

sub _index2 {
    my($l1, $l2) = @_;
    bsdindex(sprintf("%s!%s", index_entry(j($l1)), index_entry(j($l2))));
}

sub bsdindex {
    sprintf("\\index{%s}", @_);
}

sub j {
    my $term = shift;
    my $iobj = $gindex->{$term};

    if ($iobj) {
	$iobj->jindex || $term;
    } else {
	$term;
    }
}

my($sub_it, $sub_bf);
BEGIN {

#   $sub_it = sub { sprintf("\\textit{%s}", @_) };
#   $sub_bf = sub { sprintf("{\\gt{}%s}", @_) };

    $sub_it = sub {
	local $_ = shift;
	if (/\P{ASCII}/) {
	    $_;
	} else {
	    "{\\it{$_}}";
	}
    };
    $sub_bf = sub { sprintf("\\textbf{%s}", @_) };
}

sub index_entry {
    my $name = shift;
    my($label, $yomi);
    $label = $yomi = $name;

    for ($label) {
	replace_vars \$_;
	tr/,/~/;
	s/{(\P{ASCII}#*?)}/$1/g;
	s/{(.*?)}/&$sub_it($1)/ge;
	s/\[(.*?)\]/&$sub_bf($1)/ge;
	s/<(.*?)>/$1/g;
	s/(?<=\p{ASCII})~(?=\p{ASCII})/ /g;
	s/~//g;
	s/(?<=\P{ASCII}) +(?=\P{ASCII})//g;
	s/([_&])/\\$1/g;

	# "#!" を索引に入れるのは難しいので全角にして前後の空白を調整
	s/#/♯/g;
	s/!/\\hspace{-0.2em}！\\hspace{-0.2em}/g;

	my $space = '$\,$';
	s/\(\)$/${space}(${space})/;
    }

    for ($yomi) {
	replace_vars \$_;
	tr/,/~/;
	s/(\P{ASCII}+)/$yomi{$1} || $1/ge;
	s/[{}\[\]<>~! ]//g;
	tr[A-Z][a-z];
	tr[がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ]
	  [かきくけこさしすせそたちつてとはひふへほはひふへほあいうえおつやゆよわ];
	tr[ー][]d;
    }

    if ($yomi eq '' or $yomi eq $label) {
	$label;
    } else {
	sprintf("%s\@%s", $yomi, $label);
    }
}

1;

######################################################################
package IndexObj;

use strict;
use warnings;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $obj = bless {}, $class;

    my($index, $jindex, $phonetic) = @_;
    if ($index) {
	$obj->{index} = $index;
	if ($jindex) {
	    $obj->{jindex} = $jindex;
	    if ($phonetic) {
		$obj->{phonetic} = $phonetic;
	    }
	}
    }
    $obj;
}

sub jindex {
    my $obj = shift;
    if (@_) {
	$obj->{jindex} = shift;
    } else {
	$obj->{jindex};
    }
}

1;
