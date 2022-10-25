requires 'perl', '5.014';

requires 'App::Greple', '8.58';
requires 'App::Greple::update', '0.03';
requires 'App::Greple::xp', '0.04';
requires 'Try::Tiny';
requires 'JSON';
requires 'Unicode::EastAsianWidth';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

