[![Actions Status](https://github.com/kaz-utashiro/App-Greple-fbsd2/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-Greple-fbsd2/actions)
# NAME

fbsd2 - Module for translation of the book "The Design and Implementation of the FreeBSD Operating System 2nd Edition"

# SYNOPSIS

greple -Mfbsd2 \[ options \]

    --sxs        show English/Japanese text side-by-side

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

# DESCRIPTION

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

So `macro` + `e` recovers original text, and `macro` + `j`
produces Japanese version of book text.  You can do it by next
command.

    $ greple -Mfbsd2 --retrieve macro,e

    $ greple -Mfbsd2 --retrieve macro,j

# OPTION

- **--by** _part_

    Makes _part_ as a unit of output.  Multiple part can be given
    connected by commma.

- **--in** _part_

    Search pattern only from specified _part_.

- **--roffsafe**

    Exclude pattern included in roff comment and index.

- **--retrieve** _part_

    Retrieve specified part as a plain text.

    Special word _all_ means _macro_, _mark_, _e_, _j_, _comment_,
    _retain_, _gap_.  Next command produces original text.

        greple -Mfbsd2 --retrieve all

    If the _part_ start with minus ('-') character, it is removed from
    specification.  Without positive specification, _all_ is assumed. So
    next command print all lines other than _retain_ part.

        greple -Mfbsd2 --retrieve -retain

- **--colorcode**

    Produce color-coded result.

- **--ed1**, **--ed2**, **--gloss1**, **--gloss2**

    Seach edtion 1 and edtion 2 text files, and glossary files of each.

- **--lint**

    Execute sanity check for eg-jp document format.

- **--side-by-side**
- **--sxs**

    Print English and Japanese text in side-by-side format.  Requires
    [sdif(1)](http://man.he.net/man1/sdif) command installed.  Indirectly uses **--cmark** option which
    produces conflict-markder style output.

# EXAMPLE

Produce original text.

    $ greple -Mfbsd2 --retrieve macro,e

Search sequence of "system call" in Japanese text and print _egjp_
part including them.  Note that this print lines even if "system" and
"call" is devided by newline.

    $ greple -Mfbsd2 -e "system call" --by egjp --in j

Seach English text block which include all of "socket", "system",
"call", "error" and print _egjp_ block including them.

    $ greple -Mfbsd2 "socket system call error" --by egjp --in e

Look the file conents each part colored in different color.

    $ greple -Mfbsd2 --colorcode

Look the colored contents with all other staff

    $ greple -Mfbsd2 --colorcode --all

Compare produced result to original file.

    $ diff -U-1 <(lv file) <(greple -Mfbsd2 --retrieve macro,j) | sdif

# TEXT FORMAT

With part names (m: macro, g: gap, r: retain, p: para, c: comment).

## Pattern 1

Simple Translation

       m .\" Copyright 2004 M. K. McKusick
       m .Dt $Date: 2013/12/23 09:04:26 $
       m .Vs $Revision: 1.3 $
       m .EG \"---------------------------------------- ENGLISH
    eg e .H 2 "\*(Fb Facilities and the Kernel"
       m .JP \"---------------------------------------- JAPANESE
    jp j .H 2 "\*(Fb の機能とカーネルの役割"
       m .EJ \"---------------------------------------- END

## Pattern 2

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

## COMMENT

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

# ENVIRONMENTS

- **FreeBSDbook**

    Git リポジトリのディレクトリ

# FILES

`$ENV{FreeBSDbook}/WORDLIST.txt`

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2017- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
