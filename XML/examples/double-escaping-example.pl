#!/usr/bin/perl -w

# Demonstrate that ampersands are double-escaped

# Even if your text looks like already-escaped XML, it will be escaped
#  again to make sure that the same text arrives at the other end.

use strict;

use XML::Writer;

my $w = new XML::Writer();

$w->startTag('doc');
$w->characters('In HTML and XML, an ampersand must be escaped as &amp;');
$w->endTag('doc');
$w->end();
