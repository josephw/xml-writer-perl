use strict;
use warnings;

use Test::More tests => 2;

use XML::Writer;

my $output;

my $writer = XML::Writer->new( OUTPUT => \$output, NAMESPACES => 1 );

$writer->startTag( 'doc' );

my $ns = 'http://foo';

$writer->addPrefix( $ns => 'foo' );

$writer->dataElement( [ $ns => 'bar' ], 'yadah', [ $ns => 'baz' ] => 'x' );

$writer->endTag( 'doc' );

like $output => qr/foo:bar/, 'element has namespace';
like $output => qr/foo:baz/, 'attribute has namespace';





