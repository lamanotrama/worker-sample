package WorkerSample;
use 5.008005;
use strict;
use warnings;
use Parallel::Prefork;
use Sub::Throttle qw(throttle);
use Log::Minimal;
use POSIX ":sys_wait_h";
use Proc::Killfam;

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

    # run in foreground
    $SIG{INT} = sub {
        $pm->signal_all_children('TERM');
        $pm->wait_all_children;
        exit 0;
    };

    while ( $pm->signal_received ne 'TERM' ) {
        $pm->start and next;

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

    my $timeout = 10;
    my $time_required = int(rand($timeout + 5));

    infof("working($time_required)");

    eval {
        local $SIG{ALRM} = sub {
            $SIG{ALRM} = "IGNORE";
            killfam('ALRM', $$);
            while ( waitpid(-1, WNOHANG) >= 0 ) {}
            die("timed out");
        };

        alarm $timeout;
        system "sleep $time_required";
        alarm 0;
    };
    alarm 0;

    if ( my $e = $@ ) {
        chomp $@;
        warnf("faild: $@");
        die 'die';
    } else {
        infof("finish");
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

WorkerSample - It's new $module

=head1 SYNOPSIS

    carton exec bin/worker.pl

    //or

    start_server -- carton exec bin/worker.pl
    pkill -HUP start_server

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

