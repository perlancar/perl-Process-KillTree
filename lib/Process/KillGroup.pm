package Process::KillGroup;

use 5.010;
use strict;
use warnings;

use Data::Clone;
use Exporter::Lite;
use Process::KillTree;

our @EXPORT_OK = qw(kill_group);

# VERSION

our %SPEC;

$SPEC{kill_group} = clone($Process::KillTree::SPEC{kill_tree});
$SPEC{kill_group}{summary} = "Kill process and all other belonging to ".
    "the same process group";
sub kill_group {
    Process::KillTree::kill_tree(@_, _pgrp=>1);
}

1;
# ABSTRACT: Kill process and all other belonging to the same process group
__END__

=head1 SYNOPSIS

 use Process::KillGroup qw(kill_group);

 my $pid = ...;
 kill_group pid => $pid, signal => 'KILL';


=head1 DESCRIPTION

This module provides kill_group().


=head1 SEE ALSO

L<Process::KillTree>

=cut
