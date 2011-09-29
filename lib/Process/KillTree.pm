package Process::KillTree;

use 5.010;
use strict;
use warnings;

use Exporter::Lite;
our @EXPORT_OK = qw(kill_tree);

# VERSION

our %SPEC;

$SPEC{kill_tree} = {
    summary => 'Kill process and all its descendants '.
        '(children, grandchildren, ...)',
    description => <<'_',

To find out about child processes, Sys::Statistics::Linux::Processes is used on
Linux. Croaks on other operating systems.

Returns the killed PIDs.

_
    args => {
        pid => ['int' => {
            summary => 'Process ID to kill',
            description => 'Either pid or pids must be specified',
        }],
        pids => ['array' => {
            of => 'int*',
            summary => 'Process IDs to kill',
            description => 'Either pid or pids must be specified',
        }],
        signal => ['str' => {
            summary => 'Signal to use, either numeric (e.g. 1), '.
                'or string (e.g. KILL)',
            default => 'TERM',
        }],
        action => ['code' => {
            summary => 'If specified, will call action instead of killing '.
                'the processes',
            description => <<'_',

Code will be supplied $pids, an arrayref containing all the PIDs to kill.

_
        }],
    },
    result_naked => 1,
    features => {
        dry_run => 1,
    },
};
sub kill_tree {
    my %args = @_;
    my @pids0;
    push @pids0, $args{pid} if $args{pid};
    push @pids0, @{$args{pids}} if $args{pids};
    @pids0 or die "Please specify at least 1 PID";
    my $signal = $args{signal} // "TERM";

    my %parents; # key = pid, val = ppid
    my %pgrps; # key = pid, val = pgrp
    if ($^O =~ /linux/i) {
        eval { require Sys::Statistics::Linux::Processes };
        die "Can't load Sys::Statistics::Linux::Processes, ".
            "please install it first" if $@;
        my $lxs = Sys::Statistics::Linux::Processes->new;
        $lxs->init;
        my $psinfo = $lxs->get;
        for my $pid (keys %$psinfo) {
            $parents{$pid} = $psinfo->{$pid}{ppid};
            $pgrps{$pid} = $psinfo->{$pid}{pgrp};
        }
    } else {
        die "Unknown OS ($^O), can't get process table for this OS";
    }

    my @pids;
    if ($args{_pgrp}) {
        my @pgrps = map { $pgrps{$_} } @pids0;
        for my $pid (keys %pgrps) {
            push @pids, $pid if $pgrps{$pid} ~~ @pgrps;
        }
    } else {
        my %pids;
        my $_push;
        $_push = sub {
            for my $a (@_) {
                next if $pids{$a};
                push @pids, $a;
                $pids{$a} = 1;
                for my $c (keys %parents) {
                    next if $pids{$c};
                    $_push->($c) if $parents{$c} && $parents{$c} == $a;
                }
            }
        };
        $_push->(@pids0);
        @pids = reverse @pids; # kill child first, then parent
    }

    unless ($args{-dry_run}) {
        if ($args{action}) {
            $args{action}->(\@pids);
        } else {
            kill $signal, @pids;
        }
    }

    return \@pids;
}

$SPEC{kill_tree} = {
    summary => 'Kill process and all its descendants '.
        '(children, grandchildren, ...)',
    description => <<'_',

To find out about child processes, Sys::Statistics::Linux::Processes is used on
Linux. Croaks on other operating systems.

Returns the killed PIDs.

_
    args => {
        pid => ['int' => {
            summary => 'Process ID to kill',
            description => 'Either pid or pids must be specified',
        }],
        pids => ['array' => {
            of => 'int*',
            summary => 'Process IDs to kill',
            description => 'Either pid or pids must be specified',
        }],
        signal => ['str' => {
            summary => 'Signal to use, either numeric (e.g. 1), '.
                'or string (e.g. KILL)',
            default => 'TERM',
        }],
        action => ['code' => {
            summary => 'If specified, will call action instead of killing '.
                'the processes',
            description => <<'_',

Code will be supplied $pids, an arrayref containing all the PIDs to kill.

_
        }],
    },
    result_naked => 1,
    features => {
        dry_run => 1,
    },
};

1;
# ABSTRACT: Kill process and all its descendants (children, grandchildren, ...)
__END__

=head1 SYNOPSIS

 use Process::KillTree qw(kill_tree);

 my $pid = ...;
 kill_tree pid => $pid, signal => 'KILL';


=head1 DESCRIPTION

This module provides kill_tree().


=head1 FUNCTIONS

None are exported by default, but they are exportable.


=head1 SEE ALSO

L<Process::KillGroup>

=cut
