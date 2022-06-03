package Bombay::EGJP;

use strict;
use warnings;
use utf8;

BEGIN {
    use Carp;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $newi = bless {}, $class;
    my @lines;

    my($file) = @_;
    if (defined $file) {
	$newi->{file} = $file;
	unless (open(F, "<:encoding(utf8)", $file)) {
	    croak "$file: $!";
	} else {
	    local($/) = undef;
	    my $text = <F>;
	    $newi->original($text);
	    close F;
	}
    }
    $newi;
}

sub original {
    my $obj = shift;
    if (@_) {
	$obj->{original} = shift;
    } else {
	$obj->{original};
    }
}

sub jp {
    my $obj = shift;
    if (not defined $obj->{jp}) {
	if (not defined $obj->{original}) {
	    carp "original text is not defined yet";
	}
	$obj->{jp} = process_text($obj->original);
    }
    $obj->{jp};
}

my %prevstate;
BEGIN {
    %prevstate = ('EG' => 'EJ', 'JP' => 'EG', 'EJ' => 'JP');
}

sub process_text {
    my($text) = @_;

    my $offset = 0;
    my @exclude = ();
    my $state = 'EJ';
    my $line = 1;
    my @body = split(/(^\.(?:EG|JP|EJ).*\n?)/m, $text);
    my @result;
    use vars qw(%prevstate);

    foreach my $s (@body) {
	if ($s =~ /\A\.(EG|JP|EJ)/) {
	    my $new = $1;
	    if ($prevstate{$new} ne $state) {
		carp "format error (line $line)\n";
		return undef;
	    }
	    $state = $new;
	}
	else {
	    if ($state eq 'EG') {
		next;
	    }
	    if ($state eq 'EJ') {
		push(@result, $s);
		next;
	    }
	    elsif ($state eq 'JP') {
		if ($s !~ /\n\n/) {
		    push(@result, $s);
		} else {
		    my $i = 0;
		    while ($s =~ /(?s)(.*?\n)(?:\n+|\n*\Z)/mg) {
			my $jpart = $1;
			if ($jpart =~ /^※/) {
			    next;
			}
			if ($i % 2 == 1) {
			    push(@result, $jpart);
			}
			$i++;
		    }
		}
	    }
	}
    } continue {
	$line += $s =~ tr/\n/\n/;
    }
    join('', @result);
}
