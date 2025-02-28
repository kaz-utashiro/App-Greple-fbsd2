requires 'perl', '5.014';

requires 'App::Greple', '9.22';
requires 'App::Greple::git', '1.00';
requires 'App::Greple::subst', '2.36';
requires 'App::Greple::update', '1.04';
requires 'App::Greple::xp', '1.00';
requires 'App::Greple::frame', '1.03';
requires 'App::Greple::charcode';
requires 'App::sdif', '4.41';
requires 'Try::Tiny';
requires 'JSON';

requires 'Moo';
requires 'Text::VisualPrintf';
requires 'Getopt::EX::Hashed';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

