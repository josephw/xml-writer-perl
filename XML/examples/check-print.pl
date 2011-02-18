#!/usr/bin/perl -w

# Demonstrate CHECK_PRINT to catch output failures

use strict;

use XML::Writer;

my $output;

print "Open a file handle where all writes will fail.\n";

# A file handle where all writes will fail immediately
open($output, '>:unix', '/dev/full') or die "Unable to open output file: $!";

my $writer;

print "Writing without CHECK_PRINT will appear to succeed...\n";

$writer = XML::Writer->new(OUTPUT => $output);
$writer->emptyTag('document');
$writer->end();

print "...no errors.\n";


print "With CHECK_PRINT the write failure causes a croak...\n";

$writer = XML::Writer->new(OUTPUT => $output, CHECK_PRINT => 1);
$writer->emptyTag('document');
$writer->end();

print "...this shouldn't happen!\n";

close($output) or die "Failed to close output file: $!";
