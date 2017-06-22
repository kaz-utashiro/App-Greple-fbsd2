package Bombay::Lmap;

use utf8;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util qw(min max first);

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

sub new {
    my $class = shift;
    my %param = @_;
    my $obj = bless {
	INDEX => 0,
	LIST => [],
    }, $class;
    my $map;

    $param{FILE} = $param{BASE} . ".lmap" if $param{BASE};
    if (my $file = $param{FILE}) {
	open MAP, $file or die;
    }
    elsif ($param{TEXT}) {
	open MAP, \$param{TEXT} or die;
    }
    else {
	croak;
    }

    while (<MAP>) {
	my @list = split;
	my @ent;
	push @ent, shift @list;
	while (@list >= 2) {
	    push @ent, [ splice @list, 0, 2 ];
	}
	push @{$obj->{LIST}}, \@ent;
    }
    close MAP;

    if ($param{CUT}) {
	$obj->cut($param{CUT});
    }

    $obj;
}

sub reset {
    my $obj = shift;
    $obj->{INDEX} = 0;
    $obj;
}

sub next {
    my $obj = shift;
    my $index = $obj->{INDEX}++;
    if ($#{$obj->{LIST}} > $index) {
	$obj->reset;
	return undef;
    }
    $obj->{LIST}->[$index];
}

sub labels {
    my $obj = shift;
    map { $_->[0] } @{$obj->{LIST}};
}

sub findlabel {
    my $obj = shift;
    my $label = shift;
    first { $_->[0] eq $label } @{$obj->{LIST}};
}

sub cut {
    my $obj = shift;
    my $min = shift;
    
    for my $list (@{$obj->{LIST}}) {
	for my $i (1 .. $#{$list}) {
	    if ($list->[$i]->[0] < $min) {
		splice @$list, $i;
		last;
	    }
	}
    }
    $obj;
}

1;
