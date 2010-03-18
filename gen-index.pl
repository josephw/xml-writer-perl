#!/usr/bin/perl -w

use strict;

# Process index.html, to include the current post-0.4 changelog

# To publish:
# ./gen-index.pl >generated-index.html && scp generated-index.html shell.berlios.de:/home/groups/xml-writer-perl/htdocs/index.html

use version;

use IO::File;
use FindBin;
use File::Spec;
use HTML::Entities;

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %m2n;
@m2n{@months} = (1 .. scalar(@months));

my $index = new IO::File(File::Spec->catfile($FindBin::Bin, 'index.html'), '<') or die "Unable to open index.html: $!";

my $htmlChanges = '';
my $latest;
my $latestDate;

my $changes = new IO::File(File::Spec->catfile($FindBin::Bin, 'XML', 'Changes'), '<') or die "Unable to open Changes: $!";

while (<$changes>) {
	my $datestr;

	if (my ($m, $d, $y) = /^[0-9].*([A-Z][a-z]{2})\s+(\d+).*\s([0-9]{4})\s/) {
		my $mn = $m2n{$m};
		$datestr = sprintf('%04d-%02d-%02d', $y, $mn, $d);
	}

	if (my ($vs) = /^(\d+\.\d+(?:\.\d+)?)\s+/) {
		$vs = new version($vs);
		if (!$latest || ($vs > $latest)) {
			$latest = $vs;
			$latestDate = $datestr;
		}
	}

	s/\S+\@\S+/<xxx\@xxx>/;
	last if /^0\.4\s+/;

	$htmlChanges .= encode_entities($_);
}

$changes->close() or die "Unable to close Changes: $!";

print STDERR "Latest version: $latest\n";

my $rtag = "xml-writer-$latest";

print STDERR "Tag: $rtag\n";

my $baseTag = 'xml-writer-0.4';

my $diffUrl = encode_entities('http://git.berlios.de/cgi-bin/cgit.cgi/xml-writer-perl/diff/XML/Writer.pm?id2='.$baseTag.'&id='.$rtag.'&ss=1');

while (<$index>) {
	if (/<!-- CHANGELOG -->/) {
print <<"EOP";
<h3>Changes</h3>
<p>If you want to check the precise changes,
<a href="${diffUrl}" title="[xml-writer-perl] Diff of /trunk/XML/Writer.pm">this colourised diff</a>
may be useful.</p>

EOP

		print "<pre>";
		print $htmlChanges;
		print "</pre>\n";
	} elsif (my ($b, $a) = /^(.*)<!-- LATEST -->.*<!-- LATEST -->(.*)$/) {
		if ($latest) {
			print "${b}Release $latest${a}\n";
		}
	} elsif (my ($bef, $d, $aft) = /^(<p>Last modified: )(\d+-\d+-\d+)(<\/p>)/) {
		if ($latestDate gt $d) {
			$d = $latestDate;
		}
		print $bef, $d, $aft, "\n";
	} else {
		print $_;
	}
}

$index->close() or die "Unable to close index.html: $!";
