package WorkerSample;
use 5.008005;
use strict;
use warnings;
use Parallel::Prefork;
use Sub::Throttle qw(throttle);
use Log::Minimal;

our $VERSION = "0.01";

$Log::Minimal::PRINT = sub {
    my ( $time, $type, $message, $trace,$raw_message) = @_;
    my $pgid = getpgrp($$);
    print( "$time [$type] $pgid $$ $message\n");
};

sub run {
    my $pm = Parallel::Prefork->new({
        max_workers  => 6,
        fork_delay   => 1,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });

    while ( $pm->signal_received ne 'TERM' ) {
        $pm->start and next;

        setpgrp();
        infof( "spawn" );

        my $reqs_before_exit = 3;
        $SIG{TERM} = sub { $reqs_before_exit = 0 };

        while ( $reqs_before_exit > 0 ) {
            if ( throttle(1, \&work ) ) {
                --$reqs_before_exit
            } else {
                sleep 3;
            }
        }

        infof( "close" );
        $pm->finish;
    }

    $pm->wait_all_children;
    infof( "$0 CLOSED" );
}


sub work {
    infof("working");
    sleep 20;
    infof("finish");
}


1;
__END__

=encoding utf-8

=head1 NAME

WorkerSample - It's new $module

=head1 SYNOPSIS

    carton exec bin/worker.pl

=head1 SETUP

    cd /path/to/project_root
    cpanm carton
    carton insall

=head1 DESCRIPTION

ワーカの挙動調べる用のサンプル

=head1 LICENSE

Copyright (C) lamanotrama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

lamanotrama E<lt>lamanotrama@gmail.comE<gt>

=cut

