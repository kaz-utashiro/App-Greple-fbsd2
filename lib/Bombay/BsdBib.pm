package Bombay::BsdBib;

use v5.14;
use warnings;
use Data::Dumper;

use utf8;
use open IO => ':utf8', ':std';
use Encode;

use Exporter 'import';
our @EXPORT = qw(&bib_getmark &bib_makeref &bib_data &bib_tex);
our @EXPORT_OK = qw($bibsort);

use Carp;
use vars qw($myself $mydir $refdir $bibdir $bibindex %bibmark $bibsort);

$myself = $0;
$mydir = $myself;
$mydir =~ s|/[^/]+$||;

$refdir = "$mydir/../Refs";
$bibdir = "$refdir/TEX";
$bibindex = "$refdir/00INDEX";

my %sortkeys;
if (open my $index, $bibindex) {
    while (<$index>) {
	chomp;
	s/.*%%%//;
	my($mark, $keyword) = split /\t/, $_, 2;
	$bibmark{$keyword} = $mark;
	($sortkeys{$mark} = uc($mark)) =~ s/\W//g;
    }
} else {
    croak "$!: $bibindex";
}

$bibsort = sub {
    $sortkeys{$::a} cmp $sortkeys{$::b}
};

sub bib_getmark {
    my $ref = shift;
    $bibmark{$ref};
}

sub bib_makeref {
    my @word = do {
	grep { /[A-Za-z0-9]/ }
	map { split }
	map { s/\\s-\d([^\\]*?)\\s0/$1/gr }
	@_;
    };
    join ' ', @word;
}

sub bib_key2file {
    my $key = shift;
    $key =~ s/\W//g;
    "$bibdir/$key";
}

sub bib_data {
    my $key = shift;
    my $file = bib_key2file($key);
    my $data;

    unless (open(DATA, $file)) {
	carp "$!: $file";
	return;
    }
    else {
	local($/) = undef;
	$data = <DATA>;
	close DATA;
    }
    $data;
}

sub bib_tex {
    my $key = shift;
    my %bib;
    my @result;

    my $data;
    if ($key =~ /^%/) {
	$data = $key;
    } else {
	$data = bib_data($key);
    }

    unless ($data) {
	carp "no data: $key";
	return undef;
    }

    $data =~ s/\\s-(\d)([^\\]*?)\\s\+\1/$2/g;
    $data =~ s/\\s-\d([^\\]*?)\\s0/$1/g;
    $data =~ s/\\f[IRP]//g;
    $data =~ s/\\p//g;
    #$data =~ s%//%////%g;

    while ($data =~ /^\%(\S+)\s+(.*(?:\n[^%\s].*)*)/mg) {
	my($k, $v) = ($1, $2);
	$v =~ s/\n/ /g;
	if (defined $bib{$k}) {
	    if ($k !~ /^[AOI]$/) {
		carp "Duplicated entry $1 in \"$key\"";
		next;
	    }
	    if (not ref $bib{$k}) {
		$bib{$k} = [ $bib{$k} ];
	    }
	    push(@{$bib{$k}}, $v);
	}
	else {
	    $bib{$k} = $v;
	}
    }

    ## author
    my($author);
    if (defined $bib{A}) {
	my $a = $bib{A};
	my @author = ref $a ? @$a : ($a);
	while (my $a = shift(@author)) {
	    if ($author) {
		$author .= @author ? ", " : " & ";
	    }
	    $author .= $a;
	}
    }
    elsif (defined $bib{Q}) {
	$author = $bib{Q};
    }
    else {
	carp "no author: $key";
    }
    push(@result, $author);
    ## title
    if (defined($bib{T})) {
	my $title = $bib{T};
	if ($bib{J} or $bib{R} or $bib{B}) {
	    $title = "``$title''";
	} else {
	    $title = "\\fI$title\\fP";
	}
	push(@result, $title);
    }
    ## book
    if ($bib{B}) {
	push(@result, sprintf("in \\fI%s\\fP", $bib{B}));
    }
    ## technical report
    push(@result, $bib{R});
    ## journal
    if ($bib{J}) {
	push(@result, sprintf("\\fI%s\\fP", $bib{J}));
    }
    ## vol.
    if (my $v = $bib{V}) {
	if ($v =~ /^\d+$/) {
	    $v = "vol.$v";
	}
	push(@result, $v);
    }
    ## no.
    if (my $n = $bib{N}) {
	if ($n =~ /^[,\d]+$/) {
	    $n = "no.$n";
	}
	push(@result, $n);
    }
    ## pp.
    if ($bib{P}) {
	push(@result, sprintf("pp.%s", $bib{P}));
    }
    ## issuer
    if (my $I = $bib{I}) {
	my @issuer = ref $I ? @$I : ($I);
	for (@issuer) {
	    s/(available from )?(?<url>(https?|ftp): *\/\/.*)$/\\url{$+{url}}/;
	    push(@result, $_);
	}
    }
    ## city
    push(@result, $bib{C});
    ## date
    push(@result, $bib{D});

    @result = grep defined, @result;

    my $bibtxt = join(", ", @result) . ".";

    ## other info.
    if ($bib{O}) {
	my @other = ref $bib{O} ? @{$bib{O}} : $bib{O};
	foreach my $o (@other) {
	    $o =~ s"( https?://(?: \\_ | [./\w\-] )+ )"\\url{$1}"xi;
	    $bibtxt .= " $o";
	}
    }

    $bibtxt;
}

1;
