#!/usr/bin/perl -w

# Write to a string, then print the output

use strict;

use XML::Writer;

my $s;

my $w = new XML::Writer(OUTPUT => \$s);

$w->startTag('doc');
$w->characters('text');
$w->endTag('doc');
$w->end();

# Print the string contents
print $s
