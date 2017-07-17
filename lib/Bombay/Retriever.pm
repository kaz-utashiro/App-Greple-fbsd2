package Bombay::Retriever;

use utf8;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Bombay::RoffDoc;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

sub new {
    my $class = shift;
    my %param = @_;
    my $obj = bless {
	BASEDIR => "",
	DOCS => {},
    }, $class;

    $obj->configure(@_) if @_;

    $obj;
}

sub configure {
    my $obj = shift;
    while ((my($k, $v) = splice @_, 0, 2) >= 2) {
	$obj->{$k} = $v;
    }
}

sub get_text {
    my $obj = shift;
    my %arg = @_;

    my $label = $arg{LABEL} or die;

    my $docname = $label =~ s/: \d+ (?: :[ej] )?$//xr;
    my $doc = $obj->{DOCS}->{$docname} //= do {
	$docname =~ s/:/\//g;
	my $file = sprintf "%s%s.j", $obj->{BASEDIR}, $docname;
	new Bombay::RoffDoc ( FILE => $file ) or die;
    };

    my @list = $doc->get_text(PART => $label);
    wantarray ? @list : join '', @list;
}

1;
