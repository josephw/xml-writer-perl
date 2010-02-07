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

my $index = new IO::File(File::Spec->catfile($FindBin::Bin, 'index.html'), '<') or die "Unable to open index.html: $!";

my $htmlChanges = '';
my $latest;

my $changes = new IO::File(File::Spec->catfile($FindBin::Bin, 'XML', 'Changes'), '<') or die "Unable to open Changes: $!";

while (<$changes>) {
	if (my ($vs) = /^(\d+\.\d+(?:\.\d+)?)\s+/) {
		$vs = new version($vs);
		if (!$latest || ($vs > $latest)) {
			$latest = $vs;
		}
	}

	s/\S+\@\S+/<xxx\@xxx>/;
	last if /^0\.4\s+/;

	$htmlChanges .= encode_entities($_);
}

$changes->close() or die "Unable to close Changes: $!";

print STDERR "Latest version: $latest\n";

my $rtag = "release-$latest";
$rtag =~ s/\./_/g;

open(STATUS, '-|', 'svn info XML/Writer.pm') or die "Unable to get SVN info: $!";

my $revision;

while (<STATUS>) {
	chomp;

	if (my ($r) = /^Last Changed Rev: (\d+)$/) {
		$revision = $r;
	}
}

close(STATUS) or die "Unable to close CVS status: $!";

die "Unable to find current SVN revision" unless $revision;

print STDERR "Revision: $revision\n";

my $baseRevision = 27; # xml-writer_0_4

my $diffUrl = encode_entities('http://svn.berlios.de/viewcvs/xml-writer-perl/trunk/XML/Writer.pm?r1='.$baseRevision.'&r2='.$revision);

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
	} else {
		print $_;
	}
}

$index->close() or die "Unable to close index.html: $!";
