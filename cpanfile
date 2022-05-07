requires 'perl', '5.014';

requires 'App::Greple', '8.5702';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

