# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::Writer;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use IO::File;
use strict;

my $output = IO::File->new_tmpfile || die "Cannot write to temporary file";
my $writer = new XML::Writer($output) || die "Cannot create XML writer";

#
# Reset the environment for an additional test.
#
sub resetEnv {
  $output->close();
  $output = IO::File->new_tmpfile;
  $writer = new XML::Writer($output);
}

#
# Check the results in the temporary output file.
#
# $number - the test number
# $expected - the exact output expected
#
sub checkResult {
  my ($number, $expected) = (@_);
  my $data = '';
  $output->seek(0,0);
  $output->read($data, 1024);
  if ($expected eq $data) {
    print "ok $number\n";
  } else {
    print "not ok $number\n";
  }
  resetEnv();
}

#
# Expect an error of some sort, and check that the message matches.
#
# $number - the test number
# $pattern - a regular expression that must match the error message
# $value - the return value from an eval{} block
#
sub expectError {
  my ($number, $pattern, $value) = (@_);
  if (defined($value)) {
    print "not ok $number\n";
  } elsif ($@ !~ $pattern) {
    print STDERR $@;
    print "not ok $number\n";
  } else {
    print "ok $number\n";
  }
  resetEnv();
}



# Test 2: Empty element tag.
TEST: {
  $writer->emptyTag("foo");
  $writer->end();
  checkResult(2, "<foo />\n");
};



# Test 3: Empty element tag with XML decl.
TEST: {
  $writer->xmlDecl();
  $writer->emptyTag("foo");
  $writer->end();
  checkResult(3, <<"EOS");
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<foo />
EOS
};



# Test 4: Start/end tag.
TEST: {
  $writer->startTag("foo");
  $writer->endTag("foo");
  $writer->end();
  checkResult(4, "<foo></foo>\n");
};



# Test 5: Attributes
TEST: {
  $writer->emptyTag("foo", "x" => "1>2");
  $writer->end();
  checkResult(5, "<foo x=\"1&gt;2\" />\n");
};



# Test 6: Character data
TEST: {
  $writer->startTag("foo");
  $writer->characters("<tag>&amp;</tag>");
  $writer->endTag("foo");
  $writer->end();
  checkResult(6, "<foo>&lt;tag&gt;&amp;amp;&lt;/tag&gt;</foo>\n");
};



# Test 7: Comment outside document element
TEST: {
  $writer->comment("comment");
  $writer->emptyTag("foo");
  $writer->end();
  checkResult(7, "<!-- comment -->\n<foo />\n");
};



# Test 8: Processing instruction without data (outside document element)
TEST: {
  $writer->pi("pi");
  $writer->emptyTag("foo");
  $writer->end();
  checkResult(8, "<?pi?>\n<foo />\n");
};


# Test 9: Processing instruction with data (outside document element)
TEST: {
  $writer->pi("pi", "data");
  $writer->emptyTag("foo");
  $writer->end();
  checkResult(9, "<?pi data?>\n<foo />\n");
};


# Test 10: comment inside document element
TEST: {
  $writer->startTag("foo");
  $writer->comment("comment");
  $writer->endTag("foo");
  $writer->end();
  checkResult(10, "<foo><!-- comment --></foo>\n");
};


# Test 11: processing instruction inside document element
TEST: {
  $writer->startTag("foo");
  $writer->pi("pi");
  $writer->endTag("foo");
  $writer->end();
  checkResult(11, "<foo><?pi?></foo>\n");
};


# Test 12: WFE for mismatched tags
TEST: {
  $writer->startTag("foo");
  expectError(12, "^Attempt to end element \"foo\" with \"bar\" tag", eval {
    $writer->endTag("bar");
  });
};


# Test 13: WFE for unclosed elements
TEST: {
  $writer->startTag("foo");
  $writer->startTag("foo");
  $writer->endTag("foo");
  expectError(13, "^Document ended with unmatched start tag\\(s\\)", eval {
    $writer->end();
  });
};


# Test 14: WFE for no document element
TEST: {
  $writer->xmlDecl();
  expectError(14, "^Document cannot end without a document element", eval {
    $writer->end();
  });
};


# Test 15: WFE for multiple document elements (non-empty)
TEST: {
  $writer->startTag('foo');
  $writer->endTag('foo');
  expectError(15, "^Attempt to insert start tag after close of", eval {
    $writer->startTag('foo');
  });
};


# Test 16: WFE for multiple document elements (empty)
TEST: {
  $writer->emptyTag('foo');
  expectError(16, "^Attempt to insert empty tag after close of", eval {
    $writer->emptyTag('foo');
  });
};


# Test 17: DOCTYPE mismatch with empty tag
TEST: {
  $writer->doctype('foo');
  expectError(17, "^Document element is \"bar\", but DOCTYPE is \"foo\"", eval {
    $writer->emptyTag('bar');
  });
};


# Test 18: DOCTYPE mismatch with start tag
TEST: {
  $writer->doctype('foo');
  expectError(18, "^Document element is \"bar\", but DOCTYPE is \"foo\"", eval {
    $writer->startTag('bar');
  });
};


# Test 19: Multiple DOCTYPE declarations
TEST: {
  $writer->doctype('foo');
  expectError(19, "^Attempt to insert second DOCTYPE", eval {
    $writer->doctype('bar');
  });
};


# Test 20: Misplaced DOCTYPE declaration
TEST: {
  $writer->startTag('foo');
  expectError(20, "^The DOCTYPE declaration must come before", eval {
    $writer->doctype('foo');
  });
};


# Test 21: Multiple XML declarations
TEST: {
  $writer->xmlDecl();
  expectError(21, "^The XML declaration is not the first thing", eval {
    $writer->xmlDecl();
  });
};


# Test 22: Misplaced XML declaration
TEST: {
  $writer->comment();
  expectError(22, "^The XML declaration is not the first thing", eval {
    $writer->xmlDecl();
  });
};

1;
