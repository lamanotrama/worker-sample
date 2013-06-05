requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

requires 'Parallel::Prefork';
requires 'Sub::Throttle';
requires 'Log::Minimal';
requires 'FindBin::libs';


