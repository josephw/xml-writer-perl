use strict;
use XML::Writer;

foreach my $step (1..1000)
{
	print "step $step\n";
	my $batch_xml = '';

	foreach my $id ( 1..250 )
	{
		my $item_xml;
		my $writer = XML::Writer->new(
			OUTPUT => \$item_xml,
			DATA_MODE => 1,
			ENCODING => 'utf-8',
			DATA_INDENT => 2,
		);
	
		my $ad_hash = ();
	
		#-----------------------------------------------------------------------
		$writer->startTag('item');
	
		$writer->cdataElement( 'title', 'lala');
		$writer->cdataElement( 'id', $id );
		$writer->cdataElement( 'url', 'lala' );
		$writer->cdataElement( 'date', 'lala' );
	
		$writer->endTag('item');
	
		$batch_xml .= "$item_xml\n\n";
	}
}
