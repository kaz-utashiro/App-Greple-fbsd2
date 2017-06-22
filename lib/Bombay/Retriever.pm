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
    $obj;
}

sub get_text {
    my $obj = shift;
    my %arg = @_;

    my $label = $arg{LABEL} or die;

    my($book, $chap, @rest) = split ':', $label;
    my $doc = $obj->{DOCS}->{"$book:$chap"} //= do {
	my $file = sprintf "%s%s/%s.j", $obj->{BASEDIR}, $book, $chap;
	new Bombay::RoffDoc ( FILE => $file ) or die;
    };

    my @list = $doc->get_text(PART => $label);
    wantarray ? @list : join '', @list;
}

1;
