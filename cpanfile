requires 'perl', '5.014';

requires 'App::Greple', '9.08';
requires 'App::Greple::git', '0.04';
requires 'App::Greple::subst', '2.32';
requires 'App::Greple::update', '1.00';
requires 'App::Greple::xp', '0.04';
requires 'App::Greple::frame', '0.07';
requires 'App::sdif', '4.28';
requires 'Try::Tiny';
requires 'JSON';

requires 'Moo';
requires 'Text::VisualPrintf';
requires 'Getopt::EX::Hashed';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

