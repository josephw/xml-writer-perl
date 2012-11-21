use strict;
use warnings;

use Test::More tests => 6;

use XML::Writer;

my $normal = XML::Writer->new( OUTPUT => \my $normal_output );
my $contained = XML::Writer->new( OUTPUT => 'self' );

$normal->dataElement( normal => 'good old classic way' );
$contained->dataElement( selfcontained => 'new and shiny' );

is $normal_output => '<normal>good old classic way</normal>',
    'classic OUTPUT behaves the same way';

my $contained_result = "<selfcontained>new and shiny</selfcontained>\n";

is $contained->end => $contained_result, "end()";

is $contained->to_string => $contained_result, 'to_string() on self-contained';

eval { $normal->to_string };
like $@ => qr/'to_string' can only be used with self-contained output/,
    "to_string on normal OUTPUT";

is "$contained" => $contained_result,
    'auto-stringification on self-contained';

like "$normal" => qr/^XML::Writer=HASH/,
    'auto-stringification on normal';





