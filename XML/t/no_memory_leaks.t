#!/usr/bin/perl

# Run with:
#   ulimit -v 102400
# to speed up resource exhaustion.

use strict;

use Test::More tests => 1;

use XML::Writer;

foreach my $step (1..1000)
{
	print STDERR "step $step\n";

	foreach my $id ( 1..250 )
	{
		my $item_xml;
		my $writer = XML::Writer->new(
			OUTPUT => \$item_xml,
			DATA_MODE => 1,
			ENCODING => 'utf-8',
			DATA_INDENT => 2,
		);
	
		$writer->startTag('item');
	
		$writer->endTag('item');
	}
}

ok(1, 'Complete without exhausting memory');
