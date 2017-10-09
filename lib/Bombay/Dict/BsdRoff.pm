package Bombay::Dict::BsdRoff;

use strict;
use warnings;

#use Bombay::Dict;
my $sap_uniqlist = 0;
my $sap_max = -1;

use Exporter 'import';
#our @ISA         = 'Bombay::Dict';
our @ISA;
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(wordlist);

use utf8;
use Encode;

use List::Util qw(pairmap);
use Data::Dumper;

my $ignore_re;
my $allow_re;
my $decorate_re;
my @fromto_re;

sub mkpat {
    my @macro = @_;
    my $pat = join '|', @macro;
    qr/$pat/;
}

BEGIN {
    $ignore_re = mkpat(
	qw(EG JP EG),
	qw(IX ss Bl Xs CP RT bp Xc Xs Px ZZ EQ EN CO),
	qw(Te Fe),
	qw(nh ce sp ps fi nf nr ds rm hy hw so in pl br mk rt rn ft ti),
	);
    $decorate_re = mkpat(
	qw(RN Rn SC Sc FN Fn NM Nm PN Pn GL Gl AM SM Sm Vr VR NS Ns),
	qw(Ls Ll),
	qw(I B R ES TI FI FL TL FG Xl),
	'(?:H|CT)\s+\d+',
	);
    $allow_re = mkpat(
	qw(SE)
	);
    @fromto_re = pairmap {
	qr/^\.\Q${a}\E .*\n (?:.*\n)*? ^\.\Q${b}\E .*\n/xm
    }
    qw(
	ig .   de .   if \}  [  ]
	CI Ce  Fl Fe  Tl Te  TS TE  DS DE
    );
}

sub uniq {
    my %seen;
    grep { not $seen{$_}++ } @_;
}

sub cleanup {
    local $_ = shift;
    my $keep = $_;

    for my $re (@fromto_re) {
	s/$re//g;
    }
    s/^\.(?:$ignore_re).*\n//mg;
    s{
	^\. (?:$decorate_re) \b [ \t]*
	(?:
	  " ([^"]*) "	# "..."
	  |
	  (\S*)		# 空白以外の連続
	  .*
	  |
	  .*
	)
    }{
	$1 // $2 // ""
    }xgme;

    s/\\[cp]$//mg;		# \c, \p
    s/^(?!.*GLOSSARY TERM)\.\\".*\n//mg;		
				# .\" コメント
				# ただし GLOSSARY 情報を除く
    s/\\\([a-z]{2}//g;		# \(em, \(en ...
    s/\\f(?:\w|\(\w\w)//g;	# \fR, \f(BI ...
    s/\\s[-+]?\d+//g;		# \s10, \s-1, \s+1

    if (/^\.\w\w?\b/m and !/^\.(?:$allow_re)/m) {
	print $keep, "\n-->\n\n", $_;
	die;
    }

    $_;
}

sub wordlist {
    my $text = shift;
    local $_ = cleanup($text);
    my @words = map { lc $_ } /(\w+)/g;
    @words = uniq @words if $sap_uniqlist;
    if ($sap_max > 0 and @words > $sap_max) {
	@words = sort { length $b <=> length $a or $a cmp $b } @words;
	splice @words, $sap_max;
    }
    @words;
}

1;
