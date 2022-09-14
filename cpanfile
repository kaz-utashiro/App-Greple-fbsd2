requires 'perl', '5.014';

requires 'App::Greple', '8.58';
requires 'App::Greple::update', '0.02';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

