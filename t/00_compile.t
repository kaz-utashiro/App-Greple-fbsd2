use strict;
use Test::More 0.98;

use_ok $_ for grep /^\w/, qw(
    App::Greple::fbsd2
   #Bombay::Compare
    Bombay::Dict
    Bombay::Dict::BsdRoff
    Bombay::Lmap
    Bombay::Retriever
    Bombay::RoffDoc
);

done_testing;

