#!/usr/pkg/bin/perl

# The following code extracts all function names that are mentioned in the
# SYNOPSIS section of an mdoc file, and for each one of them it calls man(1)
# to (indirectly) check whether there is an MLINK to them.

use strict;

use constant MANPATH => "/usr/bin/man";	# man(1) path
use constant VERBOSE => 0;		# verbose level

# Predeclare subs.
sub extract_functions;
sub test_mlinks;

my @functions = extract_functions($ARGV[0]);
test_mlinks(($ARGV[0], @functions));

sub extract_functions {
    my $fname = @_[0];

    # Open file for parsing.
    open(FILE, "<", $fname) or die "Can't open $fname";

    # Parse file.
    my $syn = 0;
    my @functions;
    while (my $line = <FILE>) {
	# Mark the beginning of the SYNOPSIS section.
	if ($line =~ m/.Sh SYNOPSIS/) {
	    $syn = 1;
	    next;
	}

	# We are beyond the SYNOPSIS section, therefore done.
	last if ($syn == 1 && $line =~ m/.Sh/);

	if ($syn == 1) {
	    # We are inside the SYNOPSIS section of the man page, which
	    # is the only part of the file we care about. Here are the
	    # function definitions, starting with the .Fn (or .Fo) macro.
	    if ($line =~ m/^(\.F[no]) (?!\*|\\|\(|\")/) {
		my @tokens = split(" ", $line);
		push(@functions, $tokens[1]);
	    }
	}
    }
    close(FILE);

    # Return the list of cross referenced functions.
    return @functions;
}

# For every function, a specially crafted man(1) invocation
# is constructed, ran and has its return code examined.
sub test_mlinks {
    my $fname = @_[0];
    my @flist = @_[1..$#_];

    foreach(@flist) {
	# Merge the arguments into a single command, or else `system' won't
	# provide us with a shell, disabling the use of redirection operators.
	# Mind that system command invokes the /bin/sh shell.
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
	    print "Possibly missing MLINK for $_ ($fname)\n";
	}
    }
}
