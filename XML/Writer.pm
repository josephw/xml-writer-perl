########################################################################
# Writer.pm - write an XML document.
# Copyright (c) 1999 by Megginson Technologies.
# No warranty.  Commercial and non-commercial use freely permitted.
########################################################################

package XML::Writer;

use strict;
use vars qw($VERSION);
use Carp;

$VERSION = "0.1";

sub new {
  my ($class, $output, $useUnsafe) = (@_);

  unless (defined($output)) {
    $output = new IO::Handle();
    $output->fdopen(fileno(STDOUT), "w") ||
      croak("Cannot write to standard output");
  }

  my $self;

  my @elementStack = ();
  my $elementLevel = 0;

  my %seen = ();

  my $end = sub {
    $output->print("\n");
  };

  my $showAttributes = sub {
    my (%atts) = (@_);
    my $aname;
    foreach $aname (keys(%atts)) {
      $output->print(" $aname=\""
		     . _escapeLiteral($atts{$aname})
		     . '"');
    }
  };

  my $SAFE_end = sub {
    if (!$seen{ELEMENT}) {
      croak("Document cannot end without a document element");
    } elsif ($elementLevel > 0) {
      croak("Document ended with unmatched start tag(s): @elementStack");
    } else {
      @elementStack = ();
      $elementLevel = 0;
      %seen = ();
      &{$end};
    }
  };

  my $xmlDecl = sub {
    my ($standalone) = (@_);
    $output->print("<?xml version=\"1.0\" encoding=\"UTF-8\"");
    if ($standalone) {
      $output->print(" standalone=\"$standalone\"");
    }
    $output->print("?>\n");
  };

  my $SAFE_xmlDecl = sub {
    if ($seen{ANYTHING}) {
      croak("The XML declaration is not the first thing in the document");
    } else {
      $seen{ANYTHING} = 1;
      $seen{XMLDECL} = 1;
      &{$xmlDecl};
    }
  };

  my $pi = sub {
    my ($target, $data) = (@_);
    if ($data) {
      $output->print("<?$target $data?>");
    } else {
      $output->print("<?$target?>");
    }
    if ($elementLevel == 0) {
      $output->print("\n");
    }
  };

  my $SAFE_pi = sub {
    my ($name, $data) = (@_);
    $seen{ANYTHING} = 1;
    if ($name =~ /xml/i) {
      carp("Processing instruction target begins with 'xml'");
    } 

    if ($name =~ /\?\>/ || $data =~ /\?\>/) {
      croak("Processing instruction may not contain '?>'");
    } else {
      &{$pi};
    }
  };

  my $comment = sub {
    my ($data) = (@_);
    $output->print("<!-- $data -->");
    if ($elementLevel == 0) {
      $output->print("\n");
    }
  };

  my $SAFE_comment = sub {
    my ($data) = (@_);
    if ($data =~ /--/) {
      carp("Interoperability problem: \"--\" in comment text");
    }

    if ($data =~ /-->/) {
      croak("Comment may not contain '-->'");
    } else {
      $seen{ANYTHING} = 1;
      &{$comment};
    }
  };

  my $doctype = sub {
    my ($name, $publicId, $systemId) = (@_);
    $output->print("<!DOCTYPE $name");
    if ($publicId) {
      $output->print(" PUBLIC \"$publicId\" \"$systemId\"");
    } elsif ($systemId) {
      $output->print(" SYSTEM \"$systemId\"");
    }
    $output->print(">\n");
  };

  my $SAFE_doctype = sub {
    my $name = $_[0];
    if ($seen{DOCTYPE}) {
      croak("Attempt to insert second DOCTYPE declaration");
    } elsif ($seen{ELEMENT}) {
      croak("The DOCTYPE declaration must come before the first start tag");
    } else {
      $seen{ANYTHING} = 1;
      $seen{DOCTYPE} = $name;
      &{$doctype};
    }
  };

  my $startTag = sub {
    my ($name, @atts) = (@_);
    $output->print("<$name");
    &{$showAttributes}(@atts);
    $output->print('>');
  };

  my $SAFE_startTag = sub {
    my ($name, @atts) = (@_);

    _checkAttributes(@atts);

    if ($seen{ELEMENT} && $elementLevel == 0) {
      croak("Attempt to insert start tag after close of document element");
    } elsif ($elementLevel == 0 && $seen{DOCTYPE} && $name ne $seen{DOCTYPE}) {
      croak("Document element is \"$name\", but DOCTYPE is \""
	    . $seen{DOCTYPE}
	    . "\"");
    } else {
      $seen{ANYTHING} = 1;
      $seen{ELEMENT} = 1;
      $elementLevel++;
      push @elementStack, $name;
      &{$startTag};
    }
  };

  my $emptyTag = sub {
    my ($name, @atts) = (@_);
    $output->print("<$name");
    &{$showAttributes}(@atts);
    $output->print(" />");
  };

  my $SAFE_emptyTag = sub {
    my ($name, @atts) = (@_);

    _checkAttributes(@atts);

    if ($seen{ELEMENT} && $elementLevel == 0) {
      croak("Attempt to insert empty tag after close of document element");
    } elsif ($elementLevel == 0 && $seen{DOCTYPE} && $name ne $seen{DOCTYPE}) {
      croak("Document element is \"$name\", but DOCTYPE is \""
	    . $seen{DOCTYPE}
	    . "\"");
    } else {
      $seen{ANYTHING} = 1;
      $seen{ELEMENT} = 1;
      &{$emptyTag};
    }
  };

  my $endTag = sub {
    my ($name) = (@_);
    $output->print("</$name>");
  };

  my $SAFE_endTag = sub {
    my $name = $_[0];
    my $oldName = pop @elementStack;
    $elementLevel--;
    if ($elementLevel < 0) {
      croak("End tag \"$name\" does not close any open element");
    } elsif ($name ne $oldName) {
      croak("Attempt to end element \"$oldName\" with \"$name\" tag");
    } else {
      &{$endTag};
    }
  };

  my $characters = sub {
    my ($data) = (@_);
    if ($data =~ /[\&\<\>]/) {
      $data =~ s/\&/\&amp\;/g;
      $data =~ s/\</\&lt\;/g;
      $data =~ s/\>/\&gt\;/g;
    }
    $output->print($data);
  };

  my $SAFE_characters = sub {
    if ($elementLevel < 1) {
      croak("Attempt to insert characters outside of document element");
    } else {
      &{$characters};
    }
  };

  if ($useUnsafe) {
    $self = {END => $end,
	     XMLDECL => $xmlDecl,
	     PI => $pi,
	     COMMENT => $comment,
	     DOCTYPE => $doctype,
	     STARTTAG => $startTag,
	     EMPTYTAG => $emptyTag,
	     ENDTAG => $endTag,
	     CHARACTERS => $characters};
  } else {
    $self = {END => $SAFE_end,
	     XMLDECL => $SAFE_xmlDecl,
	     PI => $SAFE_pi,
	     COMMENT => $SAFE_comment,
	     DOCTYPE => $SAFE_doctype,
	     STARTTAG => $SAFE_startTag,
	     EMPTYTAG => $SAFE_emptyTag,
	     ENDTAG => $SAFE_endTag,
	     CHARACTERS => $SAFE_characters};
  }

  return bless $self, $class;
}

sub end {
  my $self = shift;
  &{$self->{END}};
}

sub xmlDecl {
  my $self = shift;
  &{$self->{XMLDECL}};
}

sub pi {
  my $self = shift;
  &{$self->{PI}};
}

sub comment {
  my $self = shift;
  &{$self->{COMMENT}};
}

sub doctype {
  my $self = shift;
  &{$self->{DOCTYPE}};
}

sub startTag {
  my $self = shift;
  &{$self->{STARTTAG}};
}

sub emptyTag {
  my $self = shift;
  &{$self->{EMPTYTAG}};
}

sub endTag {
  my $self = shift;
  &{$self->{ENDTAG}};
}

sub characters {
  my $self = shift;
  &{$self->{CHARACTERS}};
}

sub _checkAttributes {
  my %anames;
  while ($#_ != -1) {
    my $name = shift; shift;
    if ($anames{$name}) {
      croak("Two attributes named \"$name\"");
    } else {
      $anames{$name} = 1;
    }
  }
}

    

sub _escapeLiteral {
  my $data = shift;
  if ($data =~ /[\&\<\>\"]/) {
    $data =~ s/\&/\&amp\;/g;
    $data =~ s/\</\&lt\;/g;
    $data =~ s/\>/\&gt\;/g;
    $data =~ s/\"/\&quot\;/g;
  }
  return $data;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::Writer - Perl extension for writing XML documents.

=head1 SYNOPSIS

  use XML::Writer;
  use IO;

  my $output = new IO::File(">output.xml");

  my $writer = new XML::Writer($output);
  $writer->startTag("greeting", 
                    "class" => "simple");
  $writer->characters("Hello, world!");
  $writer->endTag("greeting");
  $writer->end();
  $output->close();


=head1 DESCRIPTION

XML::Writer is a helper module for Perl programs that write an XML
document.  The module handles all escaping for attribute values and
character data and constructs different types of markup, such as tags,
comments, and processing instructions.

[[TODO]]


=head1 METHODS

=over 4

=item new([$output, $noErrorChecking])

Create a new XML::Writer object.  The $output argument should be an
object blessed into IO::Handle or one of its subclasses (such as
IO::File); if it is null, the module will automatically use standard
output.

The second argument, if true, turns off error checking.

=item end()

Finish creating an XML document.  This method will check that the
document has exactly one document element, and that all start tags are
closed.

=item xmlDecl([$standalone])

Add an XML declaration to the beginning of an XML document.  The
version will always be "1.0", and the encoding will always be "UTF-8".
If you provide the $standalone argument, the module will include it as
the value of the 'standalone' pseudo-attribute.

=item comment($text)

Add a comment to an XML document.  If the comment appears outside the
document element (either before the first start tag or after the last
end tag), the module will add a carriage return after it to improve
readability.

=item pi($target [, $data])

Add a processing instruction to an XML document.  If the processing
instruction appears outside the document element (either before the
first start tag or after the last end tag), the module will add a
carriage return after it to improve readability.

The $target argument must be a single XML name.  If you provide the
$data argument, the module will insert its contents following the
$target argument, separated by a single space.

=item startTag($name [, $aname1 => $value1, ...])

Add a start tag to an XML document.  Any arguments after the element
name are assumed to be name/value pairs for attributes: the module
will escape all '&', '<', '>', and '"' characters in the attribute
values using the predefined XML entities.

All start tags must eventually have matching end tags.

=item emptyTag($name [, $aname1 => $value1, ...])

Add an empty tag to an XML document.  Any arguments after the element
name are assumed to be name/value pairs for attributes: the module
will escape all '&', '<', '>', and '"' characters in the attribute
values using the predefined XML entities.

=item endTag($name)

Add an end tag to an XML document.  The end tag must match the closest
open start tag.

=item characters($data)

Add character data to an XML document.  All '<', '>', and '&'
characters in the $data argument will automatically be escaped using
the predefined XML entities.

You may invoke this method only within the document element
(i.e. after the first start tag and before the last end tag).

=back


=head1 ERROR REPORTING

With the default settings, the XML::Writer module can detect several
basic XML well-formedness errors:

=over 4

=item *

Lack of a (top-level) document element, or multiple document elements.

=item *

Unclosed start tags.

=item *

Misplaced delimiters in the contents of processing instructions or
comments.

=item *

Misplaced or duplicate XML declaration(s).

=item *

Misplaced or duplicate DOCTYPE declaration(s).

=item *

Mismatch between the document type name in the DOCTYPE declaration and
the name of the document element.

=item *

Mismatched start and end tags.

=item *

Attempts to insert character data outside the document element.

=item *

Duplicate attributes with the same name.

=back

To ensure full error detection, a program must also invoke the end
method when it has finished writing a document:

  $writer->startElement('greeting');
  $writer->characters("Hello, world!");
  $writer->endElement('greeting');
  $writer->end();

This error reporting can catch many hidden bugs in Perl programs that
create XML documents; however, if necessary, it can be turned off by
providing a true value as the second argument of the constructor:

  my $writer = new XML::Writer($output, 1);


=head1 AUTHOR

David Megginson, david@megginson.com

=head1 SEE ALSO

XML::Parser

=cut
