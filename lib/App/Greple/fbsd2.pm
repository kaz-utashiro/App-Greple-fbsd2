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

    --check-word             check against dictionary
    --check-word --stat      show statistics only
    --check-word --with-stat print with statistics

    --subst-word --diff    show diff with corrected content
    --subst-word --create  create new file with .new suffix
    --subst-word --replace replace file with backup

    --json       produce ".j" equivalent JSON data


=head1 DESCRIPTION

Text is devided into following parts.

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

So C<macro> + C<e> recovers original text, and C<macro> + C<j>
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

With part names (m: macro, g: gap, r: retain, p: para, c: comment).

=head2 Pattern 1

Simple Translation

       m .\" Copyright 2004 M. K. McKusick
       m .Dt $Date: 2013/12/23 09:04:26 $
       m .Vs $Revision: 1.3 $
       m .EG \"---------------------------------------- ENGLISH
    eg e .H 2 "\*(Fb Facilities and the Kernel"
       m .JP \"---------------------------------------- JAPANESE
    jp j .H 2 "\*(Fb の機能とカーネルの役割"
       m .EJ \"---------------------------------------- END

=head2 Pattern 2

Sentence-by-sentence Translation

           m .PP
           m .EG \"---------------------------------------- ENGLISH
           r The \*(Fb kernel provides four basic facilities:
           r processes,
           r a filesystem,
           r communications, and
           r system startup.
           r This section outlines where each of these four basic services
           r is described in this book.
           m .JP \"---------------------------------------- JAPANESE
    p egjp e The \*(Fb kernel provides four basic facilities:
    p egjp e processes,
    p egjp e a filesystem,
    p egjp e communications, and
    p egjp e system startup.
    p egjp g 
    p egjp j \*(Fb カーネルは、プロセス、ファイルシステム、通信、
    p egjp j システムの起動という4つの基本サービスを提供する。
    p      g 
    p egjp e This section outlines where each of these four basic services
    p egjp e is described in this book.
    p egjp g 
    p egjp j 本節では、これら4つの基本サービスが本書の中のどこで扱われるかを解説する。
              m .EJ \"---------------------------------------- END

=head2 COMMENT

Block start with ※ (kome-mark) character is comment block.

              .JP \"---------------------------------------- JAPANESE
    p ej eg e The
    p ej eg e .GL kernel
    p ej eg e is the part of the system that runs in protected mode and mediates
    p ej eg e access by all user programs to the underlying hardware (e.g.,
    p ej eg e .Sm CPU ,
    p ej eg e keyboard, monitor, disks, network links)
    p ej eg e and software constructs
    p ej eg e (e.g., filesystem, network protocols).
    p  |    
    p ej jp j .GL カーネル
    p ej jp j は、システムの一部として特権モードで動作し、
    p ej jp j すべてのユーザプログラムがハードウェア (\c
    p ej jp j .Sm CPU 、
    p ej jp j モニタ、ディスク、ネットワーク接続等) や、ソフトウェア資源
    p ej jp j (ファイルシステム、ネットワークプロトコル等)
    p ej jp j にアクセスするための調停を行う。
    p    jp   
    p    jp c ※
    p    jp c protected mode は、ここでしか使われていないため、
    p    jp c protection mode と誤解されないために特権モードと訳すことにする。

=head1 ENVIRONMENTS

=over 7

=item B<FreeBSDbook>

Git リポジトリのディレクトリ

=back

=head1 FILES

F<$ENV{FreeBSDbook}/WORDLIST.txt>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2017- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::fbsd2;

our $VERSION = '3.00';

use v5.14;
use utf8;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use Carp;
use Data::Dumper;
use List::Util qw(min max);
use App::Greple::Common;
use Bombay::RoffDoc;
use Bombay::Dict;

use Exporter 'import';
our @EXPORT      = qw(&wlist $opt_prefix &clean_square);
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw();

$ENV{FreeBSDbook} //= $ENV{FreeBSDBook};

my $target = -1;
my $region;
my $file;
my @boundary;

sub setup {
    if ($target != \$_) {
	$region = new Bombay::RoffDoc ( TEXT => $_, NAME => $file );
	@boundary = sub { push @_, pos() while /^/mg; @_ }->();
	$target = \$_;
    }
    1;
}

sub part {
    my %arg = @_;
    $file = delete $arg{&FILELABEL};
    setup && $region->part(%arg);
}

sub line {
    use List::BinarySearch qw(binsearch_pos);
    my $pos = binsearch_pos { $a <=> $b } +shift, @boundary;
    $pos + 1;
}

######################################################################
# lint
######################################################################

sub check_not_translated{
    return 0 if /(?!■)\P{ASCII}++/;
    return 0 if m{\A(
		      ■.*\n
		      | \.(?:\\"|CO|sp|ds|nf|fi|nh|so|nr|hy|H|CT|IX|Ls|Ll|RN|SM|ZZ).*\n
		      | \.\[       \n (.+\n)+? \.\] \n
		      | \.CI    .* \n (.+\n)+? \.Ce \n
		      | \.EQ    .* \n (.+\n)+? \.EN \n
		      | \.T[Il] .* \n (.+\n)+? \.Te \n
		      | \.F[Il] .* \n (.+\n)+? \.Fe \n
		      | \.vS       \n (.+\n)+? \.vE \n
		    )* \z }x;
    return 1;
}

sub lint {
    my %attr = @_;
    my $file = $attr{&FILELABEL};

    # skip c00.preface/0.j
    return if /by Pearson Education/;

    for my $param (
	{ part => 'e',
	  test => sub { /\P{ascii}/ },
	  mesg => "Multibyte character in English part."
	},
	{ part => [ qw(e j) ],
	  test => sub { /※/ },
	  mesg => "Possibly comment in text part."
	},
	{ part => [ qw(eg jp) ],
	  test => sub { /\n\n\z/ },
	  mesg => "End with empty line."
	},
	{ part => 'j',
	  test =>  \&check_not_translated,
	  mesg => "Possibly not translated."
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
		printf("%s:%d: %s\n",
		       $file, line($from),
		       main::color('RS', " $mesg "));
		$text =~ s/^/\t/mg;
		print $text;
	    }
	}
    }
}

#
# option: --clean-square
# 翻訳済みの日本語部分に残っている ■ を取り除く
#
sub clean_square {
    return $_ if &check_not_translated,;
    s/\A■(?!■).*\n//;
    s/[^■\n]+\K■(?!■)\s*//;
    $_;
}

######################################################################
# progress
######################################################################

our $opt_progress_each = 0;
my %progress;
my @progress_files;

sub begin_progress {
    my %attr = @_;
    my $file = $attr{&FILELABEL};

    my $progress = $progress{$file} //= do {
	push @progress_files, $file;
	{ TOTAL => 0, DONE => 0 };
    };
    if (0) {}
    elsif (/^\.CT \s+ (?<chap>\d+) \s+ (?:(?<qq>["])|)(?<title>.*?)(?(<qq>)["]?|)$/mx) {
	$progress->{CHAPTER} = sprintf "Chap %2d %s", $+{chap}, $+{title};
    }
    elsif (/^\.H \s+ 2 \s+ (?:(?<qq>")|)(?<title>.*)(?(<qq>)["]|)$/mx) {
	$progress->{SECTION} = $+{title};
    }
}

sub count_progress {
    my %attr = @_;
    my $file = $attr{&FILELABEL};

    my $progress = $progress{$file} // die;
    $progress->{TOTAL}++;
    $progress->{DONE}++ unless /■/;

    return '';
}

sub comp {
    my($done, $total) = @_;
    sprintf("%4d/%4d (%3d%%)",
	    $done,
	    $total,
	    $done / $total * 100);
}

sub show_progress {
    my($progress_total, $progress_done) = (0, 0);
    my $chapter_title;

    for my $file (@progress_files) {
	my $hash = $progress{$file};
	$chapter_title = $hash->{CHAPTER} if $hash->{CHAPTER};
	$progress_total += $hash->{TOTAL};
	$progress_done  += $hash->{DONE};
	if ($opt_progress_each) {
	    print comp $hash->{DONE}, $hash->{TOTAL};
	    print " $file";
	    print " $hash->{SECTION}" if $hash->{SECTION};
	    print "\n";
	}
    }

    return if $progress_total == 0;

    print comp $progress_done, $progress_total;
    printf " in %3d files", 0+@progress_files if @progress_files > 1;
    printf "  %s", $chapter_title if $chapter_title;
    print "\n";
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
    my $json = JSON
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

######################################################################
# json
######################################################################

our $opt_json_format = 'atomic';

sub json_begin {
    my @ignore = (
	[ qr/^\.ig/m   => qr/^\.\.\R/m  ],
	[ qr/^\.if 0/m => qr/^\.\\}\R/m ],
	);
    for my $ignore (@ignore) {
	my($s, $e) = @$ignore;
	s/$s (?s:.*?) $e//gx;
    }
}

sub json {

    state $json = JSON
	->new
	->convert_blessed
	->pretty
	->canonical
	->allow_nonref(0);

    my %attr = @_;
    my $file = $attr{&FILELABEL};
    my $doc = new Bombay::RoffDoc TEXT => $_;
    my @list = do {
	if ($opt_json_format eq 'atomic') {
	    $doc->roff_atomic_list;
	}
	elsif ($opt_json_format eq 'struct') {
	    $doc->structured_list;
	}
	elsif ($opt_json_format eq 'plain') {
	    $doc->plain_list;
	}
	else {
	    die "Unknown JSON format: $opt_json_format\n";
	}
    };
    unshift @list, {
	file => $file,
    };
    $json->encode(\@list);
}

1;

__DATA__

option default --icode=guess

define &part &__PACKAGE__::part

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

option --in-jp      --in j --roffsafe --nocomment
option --in-eg      --in e --roffsafe --nocomment
option --in-ej      --in e,j --roffsafe --nocomment

define :pat-tbl:  ^\.TI(?s:.*?)^\.Te
define :pat-fig:  ^\.F[LI](?s:.*?)^\.Fe
define :pat-code: ^\.CI(?s:.*?)^\.Ce
define :pat-ref:  ^\.\[(?s:.*?)^\.\]

option --in-tbl     --inside  :pat-tbl:
option --in-fig     --inside  :pat-fig:
option --ex-tbl     --exclude :pat-tbl:
option --ex-fig     --exclude :pat-fig:
option --ex-code    --exclude :pat-code:
option --ex-ref     --exclude :pat-ref:

option --retrieve   -h --nocolor --le &part($<shift>)

option --colorcode  --need 1 --regioncolor \
		    --le &part(comment) --cm R \
		    --le &part(macro)   --cm C \
		    --le &part(e)       --cm B \
		    --le &part(j)       --cm N \
		    --le &part(retain)  --cm W \
		    --le &part(mark)    --cm Y \
		    --le &part(gap)     --cm N

option --ed1: --chdir $ENV{FreeBSDbook}/1st_FreeBSD/daemon3 --glob c$<shift>.*/?.j
option --ed1 --ed1: ??

option --ed2: --chdir $ENV{FreeBSDbook}/2nd_FreeBSD/ --glob c$<shift>.*/?.j
option --ed2 --ed2: ??

option --gloss1 --chdir $ENV{FreeBSDbook}/1st_FreeBSD/daemon3/c15.gloss --glob */*.j
option --gloss2 --chdir $ENV{FreeBSDbook}/2nd_FreeBSD/c16.gloss --glob defs-*/*.j

help --jp           print Japanese chunk
help --eg           print English chunk
help --egjp         print Japanese/English chunk
help --comment      print comment block

help --injp         search Japanese text
help --ineg         search English text
help --inej         search English/Japanese text

help --retrieve     retrieve given part in plain text
help --colorcode    show each part in color-coded

builtin prefix=s $opt_prefix
option --mkdict \
	--all --le &part(eg) \
	--print $PKG::dict_print

builtin json-format=s $opt_json_format;

option --json \
	--all --re '\A' \
	--begin &__PACKAGE__::json_begin \
	--print &__PACKAGE__::json

builtin progress_each! $opt_progress_each

option --progress-each \
    	--progress --progress_each

option --progress \
	--no-filename --only-matching --no-newline \
	--le &part(j) \
	--begin    &__PACKAGE__::begin_progress \
	--print    &__PACKAGE__::count_progress \
	--epilogue &__PACKAGE__::show_progress

option --lint --begin __PACKAGE__::lint --re \A(?=never)match

option --clean-square --le &part(j) --cm &clean_square

# 英語テキストに非ASCII文字があるのはおかしい
option --check-nonascii \
	-n --separate -e '\P{ascii}+' --in e

# テキストブロックに「※」があってはおかしい
option --check-comm \
	-n --separate -e ※+ --in e,j --by e,j

# 日本語ブロックに4語以上のアルファベットが続くのはおかしい
# 4語以上だと、若干 false positive が出る
option --english-in-jp \
	# 特定のファイルを序外
	-Mselect --x-select-path c00.preface/0.j \
		 --x-select-path c17.index/Trailer.j \
	--re '(?a)^\w+([\n ]\w+){3,}' \
	# 参考文献は序外
	--exclude '^\.\[(?s:.*?)\n\.\]' \
	# すべての単語が大文字か数字で始まるものは序外
	--exclude '(?a)^[A-Z]\w*([\n ][A-Z\d]\w*){3,}' \
	--exclude 'University of Cambridge Computer Laboratory' \
	--exclude 'Advanced Configuration and Power Interface' \
	--in j

define $WORDLIST $ENV{FreeBSDbook}/2nd_FreeBSD/WORDLIST.txt
define $EXCLUDE $ENV{FreeBSDbook}/2nd_FreeBSD/EXCLUDE.txt

option --wordlist -Msubst --dict $WORDLIST

option --exclude-words -Mxp --exclude-pattern $EXCLUDE

option --check-word \
	--wordlist \
	--exclude-words \
	--in j

option --subst-word         --check-word --subst
option --subst-word-diff    --check-word --diff
option --subst-word-create  --check-word --create
option --subst-word-replace --check-word --replace


# .JP セクションの最初の ■ 1つを探す
define (?#first-single-square) <<END
    (?x)
    (?> ^\.JP .*\n )
    (?> (?: (?!\.EJ|■) .*\n
            |
            ■■ .*\n
        ) * ) \K
    ■
END
option --todo --re (?#first-single-square)
help --todo find first single square mark in .JP section

# .JP セクションの最初の ■ を探す
define (?#first-square) <<END
    (?x)
    (?> ^\.JP .*\n )
    (?: (?!\.EJ) [^■\n]* \n )*+
    (?!\.EJ)[^■\n]*+ \K
    ■+
END
option --todo-all --re (?#first-square)
help --todo-all find first square mark in .JP section

option --todo-everything --re ■+ --in jp

option --too-many-index \
	-nE '^\.IX( +(istart|iend))?+( +\S+){3,}' --in jp,macro
