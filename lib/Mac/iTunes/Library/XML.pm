package Mac::iTunes::Library::XML;

use 5.006;
use warnings;
use strict;
use Carp;

use Mac::iTunes::Library;
use Mac::iTunes::Library::Item;
use Mac::iTunes::Library::Playlist;
use XML::Parser 2.36;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.7';

=head1 NAME

Mac::iTunes::Library::XML - Perl extension for parsing an iTunes XML library

=head1 SYNOPSIS

  use Mac::iTunes::Library::XML;

  my $library = Mac::iTunes::Library::XML->parse( 'iTunes Music Library.xml' );
  print "This library has only " . $library->num() . "item.\n";

=head1 DESCRIPTION

Tools for dealing with iTunes XML libraries.

=head1 EXPORT

None by default.

=head1 METHODS

=head2 parse( $libraryFile )

Parses an iTunes XML library and returns a Mac::iTunes::Library object.

=cut

# The current 'key' of an item information that we're in
my $curKey = undef;
# A Mac::iTunes::Library::Item that will be built and added to the library
my $item = undef;
# A Mac::iTunes::Library that will be built
my $library;
# Characters that we collect
my $characters = undef;
# Keep track of where we are; push on each element name as we hit it
my (@stack);
my ($inTracks, $inPlaylists, $inMajorVersion, $inMinorVersion,
        $inApplicationVersion, $inFeatures, $inMusicFolder,
        $inLibraryPersistentID) = undef;

sub parse {
    my $self = shift;
    my $xmlFile = shift;
    $library = Mac::iTunes::Library->new();

    my $parser = XML::Parser->new( Handlers => {
                        Start => \&start_element,
                        End => \&end_element,
                        Char => \&characters,
                    });
    $parser->parsefile( $xmlFile );
    return $library;
} #parse

### Parser start element
sub start_element {
    my ($expat, $element, %attrs) = @_;

    # Keep a trail of our depth
    push @stack, $element;
    my $depth = scalar(@stack);

    if ( $depth == 0 ) {
    } elsif ( $depth == 1 ) {
        # Hit the initial <plist version=""> tag
        if (defined $attrs{'version'}) {
            $library->version($attrs{'version'});
        }
    } elsif ( $depth == 2 ) {
    } elsif ( $depth == 3 ) {
        if( $inPlaylists ){
        } else {
            if (($element eq 'true') or ($element eq 'false')) {
                $library->showContentRatings($element);
            }
        }
    } elsif ( $depth == 4 ) {
        # We hit a new item in the XML; create a new object
        if( $inPlaylists ){
            $item = Mac::iTunes::Library::Playlist->new() if ($element eq 'dict');
        } else {
            $item = Mac::iTunes::Library::Item->new() if ($element eq 'dict');
        }
    } elsif( $depth == 5 ){
    }
} #start_element

### Parser end element
sub end_element {
    my ($expat, $element) = @_;

    # Prune the trail
    my $depth = scalar(@stack);
    pop @stack;

    if ( $depth == 0 ) {        # plist version
    } elsif ( $depth == 1 ) {   # dict
    } elsif ( $depth == 2 ) {
    } elsif ( $depth == 3 ) {
        # Exiting a major section
        $inTracks = 0 if ($element eq 'dict');
        $inPlaylists = 0 if ($element eq 'array');

        if ($inMusicFolder and ($element eq 'string')) {
            $library->musicFolder($characters);
            $inMusicFolder = undef;
            $characters = undef;
        }
    } elsif ( $depth == 4 ) {
        # Ending an item; add it to the library and clean up
        if( $inPlaylists ){
            if ( $item ) {
                $library->addPlaylist($item);
            }
        } else {
            if ( $item ) {
                $library->add($item);
            }
        }

        $item = undef if ($element eq 'dict');
    } elsif ( $depth == 5 ) {
        # Set the attributes of the Mac::iTunes::Library::Item directly
        if ( $element =~ /(integer|string|date)/ ) {
            if( $inPlaylists ){
                # print "$curKey = $characters\n";
            }
            $item->{$curKey} = $characters;
            $characters = undef;
            $curKey = undef;
        } elsif ( $element =~ /true/ ) {
            $item->{$curKey} = 1;
            $curKey = undef;
        }
    } elsif ( $depth == 6 ){
    } elsif ( $depth == 7 ){
        if ( $element =~ /(integer)/ ) {
            # print "Adding $curKey => $characters\n";

            my $track = $library->{'ItemsById'}{$characters};
            if( ref $track and $$track ){
                $item->addItem( $$track );
            } else {
                warn "Couldn't find track '$characters'\n";
            }

            $characters = undef;
        }
    }
} #end_element

### Parser element contents
sub characters {
    my ($expat, $string) = @_;
    my $depth = scalar(@stack);

    if ( $depth == 0 ) {        # plist version
    } elsif ( $depth == 1 ) {   # dict
    } elsif ( $depth == 2 ) {
    } elsif ( $depth == 3 ) {
        # Check the name of the element
        if ( $stack[$#stack] eq 'key' ) {
            # Lots of keys at this level
            if ($string eq 'Major Version') {
                $inMajorVersion = 1;
            } elsif ( $string eq 'Minor Version' ) {
                $inMinorVersion = 1;
            } elsif ( $string eq 'Application Version' ) {
                $inApplicationVersion = 1;
            } elsif ( $string eq 'Features' ) {
                $inFeatures = 1;
            } elsif ( $string eq 'Music Folder' ) {
                $inMusicFolder = 1;
            } elsif ( $string eq 'Library Persistent ID' ) {
                $inLibraryPersistentID = 1;
            } elsif ( $string eq 'Tracks' ) {
                $inTracks = 1;
            } elsif ( $string eq 'Playlists' ) {
                $inPlaylists = 1;
            }
        } elsif ( $stack[$#stack] =~ /(integer|string|string|true|false)/ ) {
            if ($inMajorVersion) {
                $library->majorVersion($string);
                $inMajorVersion = undef;
            } elsif ($inMinorVersion) {
                $library->minorVersion($string);
                $inMinorVersion = undef;
            } elsif ($inApplicationVersion) {
                $library->applicationVersion($string);
                $inApplicationVersion = undef;
            } elsif ($inFeatures) {
                $library->features($string);
                $inFeatures = undef;
            } elsif ($inMusicFolder) {
                # The music folder could be long; buffer it.
                $characters .= $string;
            } elsif ($inLibraryPersistentID) {
                $library->libraryPersistentID($string);
                $inLibraryPersistentID = undef;
            }
        }
    } elsif ( $depth == 4 ) {
    } elsif ( $depth == 5 ) {
        if ( $stack[$#stack] eq 'key' ) {
            # Grab the key's name; Normally comes in a single chunk, but accept multiple chunks
            $curKey .= $string;
        } elsif ( $stack[$#stack] =~ /(integer|string|date)/ ) {
            # Append it to the characters that we've gathered so far
            $characters .= $string;
        }
    } elsif ( $depth == 6 ) {
    } elsif ( $depth == 7 ) {
        if ( $stack[$#stack] eq 'key' ) {
            # Grab the key's name; Normally comes in a single chunk, but accept multiple chunks
            $curKey .= $string;
        } elsif ( $stack[$#stack] =~ /(integer|string|date)/ ) {
            # Append it to the characters that we've gathered so far
            $characters .= $string;
        }
    }
} #characters

# Clean up
sub DESTROY {
    # Nothing to do.
} #DESTROY

1;

=head1 SEE ALSO

L<Mac::iTunes::Library::Item>, L<Mac::iTunes::Library>,
L<Mac::iTunes::Library::Playlist>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 CONTRIBUTORS

Mark Grimes <mgrimes@cpan.org>, http://www.peculiarities.com
Garrett Scott <garrett@gothik.org>, http://www.gothik.org

=head1 SOURCE REPOSITORY

http://mac-itunes.googlecode.com

=head1 SVN INFO

$Revision: 78 $
$Date: 2009-12-30 10:33:01 -0700 (Wed, 30 Dec 2009) $
$Author: drewgstephens $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Drew Stephens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
__END__
