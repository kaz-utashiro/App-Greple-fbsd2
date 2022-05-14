package BsdIndex;

use strict;

use Data::Dumper;

my @jindex;
my @phonetic;

BEGIN {
    use Carp;
    use vars qw($gindex $myself $mydir $indexdir $indexlist $indexmap %yomi);

    $myself = $0;
    $mydir = $myself;
    $mydir =~ s|/[^/]+$||;

    $indexdir = "$mydir/../c17.index";
    $indexlist = "$indexdir/INDEX_LIST";
    $indexmap = "$indexdir/INDEX_MAP";
}

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
	croak "wrong entory number";
    }

    for my $i (0..$#map) {
	my @map = split(/\t+/, $map[$i]);
	push(@jindex, $map[0]);
	push(@phonetic, $map[1]);
	$index->{$list[$i]} = new IndexObj($list[$i], @map);
    }

    for (@map) {
	my($jindex, $yomi) = split(/\t+/, $_);
	my @jindex = $jindex =~ /([\200-\377]+)/g;
	my @yomi = $yomi =~ /([\200-\377]+)/g;

	if (@jindex != @yomi) {
	    print stderr "number unmatch \"$_\"\n";
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
    my $range;

    my @arg = @_;

    if ($arg[0] eq 'istart' or $arg[0] eq 'iend') {
	$range = shift @arg;
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
	carp "too much argument in .IX";
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
	'$Bv' => '3BSD',
	'$Bx' => '4BSD',
	'$b0' => '4.0BSD',
	'$b1' => '4.1BSD',
	'$b2' => '4.2BSD',
	'$b3' => '4.3BSD',
	'$b4' => '4.4BSD',
	'$4L' => '4.4BSD Lite',
	'$Fb' => 'FreeBSD',
	'$Ob' => 'OpenBSD',
	'$Nb' => 'NetBSD',
	'$Bs' => 'BSD',
	'$Lx' => 'Linux',
	'$s5' => 'System~V',
	'$UX' => 'UNIX',
	'$VX' => 'VAX',
	'$PC' => 'PC',
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
    sprintf("//bsdindex{%s//}", @_);
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
if (0) {
    $sub_it = sub { sprintf("\\textit{%s}", @_) };
    $sub_bf = sub { sprintf("{\\gt{}%s}", @_) };
}
    $sub_it = sub { sprintf("{\\it{}%s}", @_) };
    $sub_bf = sub { sprintf("\\textbf{%s}", @_) };
}

sub index_entry {
    my $name = shift;
    my($label, $yomi);
    $label = $yomi = $name;

    replace_vars(\$label);
    $label =~ tr/,/~/;
    $label =~ s/{([\200-\377]*?)}/$1/g;
    $label =~ s/{(.*?)}/&$sub_it($1)/ge;
    $label =~ s/\[(.*?)\]/&$sub_bf($1)/ge;
    $label =~ s/<(.*?)>/$1/g;
    $label =~ s/(?<=[\0-\177])~(?=[\0-\177])/ /g;
    $label =~ s/~//g;
    $label =~ s/(?<=[\200-\377]) +(?=[\200-\377])//g;
    $label =~ s/([_#&])/\\$1/g;
    my $space = '$\,$';
    $label =~ s/\(\)$/${space}(${space})/;

    replace_vars(\$yomi);
    $yomi =~ tr/,/~/;
    $yomi =~ s/([\200-\377]+)/$yomi{$1} || $1/ge;
    $yomi =~ s/[{}\[\]<>~! ]//g;
    $yomi =~ tr[A-Z][a-z];

    if ($label eq $yomi) {
	sprintf("%s", $label);
    } else {
	sprintf("%s\@%s", $yomi, $label);
    }
}

1;

######################################################################
package IndexObj;

use strict;

BEGIN {
    use Carp;
}

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
