=encoding utf8

=head1 NAME

fbsd2 - Module for translation of the book "The Design and Implementation of the FreeBSD Operating System 2nd Edition"

=head1 SYNOPSIS

greple -Mfbsd2 [ options ]

    --by <part>  makes <part> as a data record
    --in <part>  search from <part> section
		 
    --jp         print Japanese chunk
    --eg         print English chunk
    --egjp       print Japanese/English chunk
    --comment    print comment block
    --injp       search from Japanese text
    --ineg       search from English text
    --inej       search from English/Japanese text
    --retrieve   retrieve given part in plain text
    --colorcode  show each part in color-coded

    --ed{1,2}    edtion 1 & 2 files
    --gloss{1,2} glossary files of edition 1 & 2

    --check-word check against dictionary

    --subst-word --all    get substituted content
    --subst-word-diff     show diff with corrected content
    --subst-word-newfile  careate new file with .new suffix


=head1 DESCRIPTION

Text is devided into forllowing parts.

    e        English  text
    j        Japanese text
    eg       English  text and comment
    jp       Japanese text and comment
    para     paragraph including multiple eg+jp
    macro    Common roff macro
    retain   Retained original text
    comment  Comment block
    com1     Level 1 comment
    com2     Level 2 comment
    com3     Level 3 comment
    mark     .EG, .JP, .EJ mark lines
    gap      empty line between English and Japanese

So [ macro ] + [ e ] recovers original text, and [ macro ] + [ j ]
produces Japanese version of book text.  You can do it by next
command.

    $ greple -Mfbsd2 --retrieve macro,e

    $ greple -Mfbsd2 --retrieve macro,j


=head1 OPTION

=over 7

=item B<--by> I<part>

Makes I<part> as a unit of output.  Multiple part can be given
connected by commma.

=item B<--in> I<part>

Search pattern only from specified I<part>.

=item B<--roffsafe>

Exclude pattern included in roff comment and index.

=item B<--retrieve> I<part>

Retrieve specified part as a plain text.

Special word I<all> means I<macro>, I<mark>, I<e>, I<j>, I<comment>,
I<retain>, I<gap>.  Next command produces original text.

    greple -Mfbsd2 --retrieve all

If the I<part> start with minus ('-') character, it is removed from
specification.  Without positive specification, I<all> is assumed. So
next command print all lines other than I<retain> part.

    greple -Mfbsd2 --retrieve -retain

=item B<--colorcode>

Produce color-coded result.

=item B<--ed1>, B<--ed2>, B<--gloss1>, B<--gloss2>

Seach edtion 1 and edtion 2 text files, and glossary files of each.

=item B<--lint>

Execute sanity check for eg-jp document format.

=back


=head1 EXAMPLE

Produce original text.

    $ greple -Mfbsd2 --retrieve macro,e

Search sequence of "system call" in Japanese text and print I<egjp>
part including them.  Note that this print lines even if "system" and
"call" is devided by newline.

    $ greple -Mfbsd2 -e "system call" --by egjp --in j

Seach English text block which include all of "socket", "system",
"call", "error" and print I<egjp> block including them.

    $ greple -Mfbsd2 "socket system call error" --by egjp --in e

Look the file conents each part colored in different color.

    $ greple -Mfbsd2 --colorcode

Look the colored contents with all other staff

    $ greple -Mfbsd2 --colorcode --all

Compare produced result to original file.

    $ diff -U-1 <(lv file) <(greple -Mfbsd2 --retrieve macro,j) | sdif

=head1 TEXT FORMAT

=head2 Pattern 1

Simple Translation

    .\" Copyright 2004 M. K. McKusick
    .Dt $Date: 2013/12/23 09:04:26 $
    .Vs $Revision: 1.3 $
    .EG \"---------------------------------------- ENGLISH
    .H 2 "\*(Fb Facilities and the Kernel"
    .JP \"---------------------------------------- JAPANESE
    .H 2 "\*(Fb の機能とカーネルの役割"
    .EJ \"---------------------------------------- END

=head2 Pattern 2

Sentence-by-sentence Translation

    .PP
    .EG \"---------------------------------------- ENGLISH
    The \*(Fb kernel provides four basic facilities:
    processes,
    a filesystem,
    communications, and
    system startup.
    This section outlines where each of these four basic services
    is described in this book.
    .JP \"---------------------------------------- JAPANESE
    The \*(Fb kernel provides four basic facilities:
    processes,
    a filesystem,
    communications, and
    system startup.
    
    \*(Fb カーネルは、プロセス、ファイルシステム、通信、
    システムの起動という4つの基本サービスを提供する。
    
    This section outlines where each of these four basic services
    is described in this book.
    
    本節では、これら4つの基本サービスが本書の中のどこで扱われるかを解説する。
    .EJ \"---------------------------------------- END

=head2 COMMENT

Block start with ※ (kome-mark) character is comment block.

    .JP \"---------------------------------------- JAPANESE
    The
    .GL kernel
    is the part of the system that runs in protected mode and mediates
    access by all user programs to the underlying hardware (e.g.,
    .Sm CPU ,
    keyboard, monitor, disks, network links)
    and software constructs
    (e.g., filesystem, network protocols).
    
    .GL カーネル
    は、システムの一部として特権モードで動作し、
    すべてのユーザプログラムがハードウェア (\c
    .Sm CPU 、
    モニタ、ディスク、ネットワーク接続等) や、ソフトウェア資源
    (ファイルシステム、ネットワークプロトコル等)
    にアクセスするための調停を行う。
    
    ※
    protected mode は、ここでしか使われていないため、
    protection mode と誤解されないために特権モードと訳すことにする。

=head2 FILES

    $ENV{FreeBSDBook}/WORDLIST.txt

=cut

package App::Greple::fbsd2;

use utf8;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util qw(min max);
use App::Greple::Common;
use Bombay::RoffDoc;
use Bombay::Dict;

use Exporter 'import';
our @EXPORT      = qw(&part &wlist $opt_prefix);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

END { }


my $target = -1;
my $region;
my $file;

sub setup {
    if ($target != \$_) {
	$region = new Bombay::RoffDoc ( TEXT => $_, NAME => $file );
	$target = \$_;
    }
}

sub part {
    my %arg = @_;
    $file = delete $arg{&FILELABEL};

    setup;
    _part(%arg);
}

sub _part {
    $region->part(@_);
}

######################################################################
# lint
######################################################################

sub lint {
    my %attr = @_;
    my $file = $attr{&FILELABEL};

    for my $param (
	{ part => 'e',
	  test => sub { /\P{ascii}/ },
	  mesg => "Multibyte character in English part."
	},
	{ part => [ qw(e j) ],
	  test => sub { /※/ },
	  mesg => "Possibly comment in text part."
	},
	)
    {
	my @part = ref $param->{part} eq 'ARRAY' ? @{$param->{part}} : $param->{part};
	my $test = $param->{test};
	my $mesg = $param->{mesg};
	my @p = part(map { $_ => 1 } @part);
	for my $r (@p) {
	    my($from, $to) = @{$r};
	    my $text = substr $_, $from, $to - $from;
	    if (do {local *_ = \$text; $test->() }) {
		printf "$file: %s\n", main::color('RS', " $mesg ");
		$text =~ s/^/\t/mg;
		print $text;
	    }
	}
	
    }
}

######################################################################
# progress
######################################################################

our $opt_progress_each = 0;
my $progress_files = 0;
my $progress_total = 0;
my $progress_done = 0;

sub count_progress {
    my %attr = @_;
    my $file = $attr{&FILELABEL};
    my $text = $_;

    my @matched = @{$attr{matched}};
    my $total = @matched;
    my $done = grep {
	substr($text, $_->[0], $_->[1] - $_->[0]) !~ /■/;
    } @matched;

    $progress_files ++;
    $progress_total += $total;
    $progress_done  += $done;

    @{$attr{matched}} = ();
    $opt_progress_each ? comp($done, $total) : "";
}

sub show_progress {
    return if $progress_total == 0;
    print comp($progress_done, $progress_total);
    printf(" in %2d files", $progress_files) if $progress_files > 1;
    print "\n";
}

sub comp {
    my($done, $total) = @_;
    sprintf("%4d/%4d (%3d%%)",
	    $done,
	    $total,
	    $done / $total * 100);
}

######################################################################
# dictionary
######################################################################

use JSON::PP;

our $opt_prefix = '';

sub dict_print {
    my %attr = @_;
    my $file = $attr{&FILELABEL};
    my($label) = $file =~ /([\w\d_]+)\.j/ or die $file;
    my $json = JSON::PP
	->new
	->convert_blessed
	->pretty
	->canonical
	->indent_length(2)
	->allow_nonref(0);

    my @dict;
    my @matched = @{$attr{matched}};
    for my $i (0 .. $#matched) {
	my $r = $matched[$i];
	my($offset, $length) = ($r->[0], $r->[1] - $r->[0]);
	my $txt = substr $_, $offset, $length;
	push @dict, Bombay::Dict->new(
	    Label => sprintf("%s%s:%04d", $opt_prefix, $label, $i + 1),
	    Text => $txt,
	    Dict => 1,
	    );
    }
    $json->encode(\@dict);
}

1;

__DATA__

option default --icode=guess

define $PKG &App::Greple::fbsd2
define &part $PKG::part

define :comment: ^※.*\n(?:(?!\.(?:EG|JP|EJ)).+\n)*
option --nocomment --exclude :comment:

define :roffcomment: ^\.\\\".*
define :roffindex:   ^\.(IX|CO).*
option --roffsafe --exclude :roffcomment: --exclude :roffindex:

option --part     &part($<shift>)
option --by       --block  &part($<shift>)
option --in       --inside &part($<shift>)

option --jp       --by jp
option --eg       --by eg
option --egjp     --by egjp
option --para     --by para
option --comment  --by comment

option --injp      --in j --roffsafe --nocomment
option --ineg      --in e --roffsafe --nocomment
option --inej      --in e,j --roffsafe --nocomment

option --retrieve   -h --nocolor --le &part($<shift>)

option --colorcode  --need 1 --regioncolor \
		    --le &part(comment) --cm R \
		    --le &part(macro)   --cm C \
		    --le &part(e)       --cm B \
		    --le &part(j)       --cm X \
		    --le &part(retain)  --cm W \
		    --le &part(mark)    --cm Y \
		    --le &part(gap)     --cm X

option --ed1 --chdir $ENV{FreeBSDBook}/1st_FreeBSD/daemon3 --glob c??.*/*.j
option --ed2 --chdir $ENV{FreeBSDBook}/2nd_FreeBSD/ --glob c??.*/*.j

option --gloss1 --chdir $ENV{FreeBSDBook}/1st_FreeBSD/daemon3/c15.gloss --glob */*.j
option --gloss2 --chdir $ENV{FreeBSDBook}/2nd_FreeBSD/c16.gloss --glob defs-*/*.j

help --jp           print Japanese chunk
help --eg           print English chunk
help --egjp         print Japanese/English chunk
help --comment      print comment block

help --injp         search Japanese text
help --ineg         search English text
help --inej         search English/Japanese text

help --retrieve     retrieve given part in plain text
help --colorcode    show each part in color-coded

builtin --prefix=s $opt_prefix
option --mkdict \
	--all --le &part(eg) \
	--print $PKG::dict_print

builtin --progress_each! $opt_progress_each

option --progress-each \
    	--progress --progress_each

option --progress \
	--all --le &part(j) \
	--continue \
	--print $PKG::count_progress \
	--epilogue $PKG::show_progress

option --lint --begin $PKG::lint --re (?=never)match


# 英語テキストに非ASCII文字があるのはおかしい
option --check-nonascii \
	-n --separate -e '\P{ascii}+' --in e

# テキストブロックに「※」があってはおかしい
option --check-comm \
	-n --separate -e ※+ --in e,j --by e,j

define $WORDLIST $ENV{FreeBSDBook}/2nd_FreeBSD/WORDLIST.txt

option --check-word \
	-n --uniqcolor --in j \
	--exclude 'GLOSSARY PHONETIC.*\n' \
	-f $WORDLIST

option --subst-f-file -f $<1> --subst_file $<shift>

option --option-subst \
	-Msubst --subst \
	--in j --exclude 'GLOSSARY PHONETIC.*\n'

option --subst-word \
	--option-subst --subst-f-file $WORDLIST

option --subst-word-diff    --subst-word --diff
option --subst-word-newfile --subst-word --create


# .JP セクションの最初の ■ 1つを探す
define (?#first-single-square) (?x)	\
    (?> ^\.JP .*\n )			\
    (?> (?: (?!\.EG|■) .*\n		\
            |				\
            ■■ .*\n			\
        ) * ) \K			\
    ■
option --todo --re (?#first-single-square)
help --todo find first single square mark in .JP section

# .JP セクションの最初の ■ を探す
define (?#first-square) (?>^\.JP.*\n)(?:(?!\.EG|■).*\n)*.*?\K■+
option --todo-all --re (?#first-square)
help --todo-all find first square mark in .JP section
