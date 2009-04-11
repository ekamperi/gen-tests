#!/usr/pkg/bin/perl

use strict;

use constant MANPATH => "/usr/bin/man";	# man(1) path
use constant VERBOSE => 0;		# verbose level

# Predeclare subs
use subs qw(extract_functions);

extract_functions $ARGV[0];

sub extract_functions {
    my $fname = @_[0];

    # Open file for parsing
    open(FILE, "<", $fname) or die "Can't open $fname";

    #
    my $syn = 0;
    my $desc = 0;
    while (my $line = <FILE>) {
	my @functions;

	# Mark the beginning of the SYNOPSIS section.
	if ($line =~ m/.Sh SYNOPSIS/) {
	    $syn = 1;
	}

	# Mark the beginning of the DESCRIPTION section.
	if ($line =~ m/.Sh DESCRIPTION/) {
	    $desc = 1;
	}

	if ($syn == 1 && $desc == 0) {
	    # We are inside a SYNOPSIS-DESCRIPTION block, which is the only part
	    # of the file we care about.
	    if ($line =~ m/^.Fn/) {
		my @tokens = split(" ", $line);
		push(@functions, $tokens[1]);
	    }
	} else {
	    # We reached beyond the DESCRIPTION section.
	    last if $desc == 1;
	}

	# Traverse the list of cross referenced functions and check if there exists
	# an MLINK to it.
	test_mlinks(@functions);
    }

    close(FILE);
}

# For every function, a specially crafted man(1) invocation
# is constructed, ran and has its return code examined.
sub test_mlinks {
    my @flist = @_;
 
    foreach(@flist) {
	# Merge the arguments into a single command, or else `system' won't
	# provide us with a shell, disabling the use of redirection operators.
	my $cmd = join (' ', MANPATH, "-w", $_, "1>&-", "2>&-");

	# Run the command and check its return status.
	if (VERBOSE) {
	    print "Executing command: " . $cmd . "\n";
	}
	system($cmd);
	if ($? == -1) {
	    print "Failed to execute: $!\n";
	}
	elsif ($? & 127) {
	    printf "Child died with signal %d, %s coredump\n",
	    ($? & 127), ($? & 128) ? 'with' : 'without';
	}
	elsif ($? != 0) {
	    print "Possibly missing MLINK for $_\n";
	}
    }
}

