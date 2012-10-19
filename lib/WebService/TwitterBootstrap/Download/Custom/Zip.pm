package WebService::TwitterBootstrap::Download::Custom::Zip;

use strict;
use warnings;
use File::Temp ();
use File::Spec;
use Archive::Zip ();
use Moose;

# ABSTRACT: Zip file containing Twitter Bootstrap
# VERSION

has file => (
  is      => 'ro',
  isa     => 'File::Temp',
  lazy    => 1,
  default => sub { 
    # TODO: does this need to be binmoded for Win32?
    File::Temp->new(
      TEMPLATE => "bootstrapXXXXXX", 
      SUFFIX   => '.zip',
      DIR      => File::Spec->tmpdir,
    );
  }, 
);

has archive => (
  is      => 'ro',
  isa     => 'Archive::Zip',
  lazy    => 1,
  default => sub {
    Archive::Zip->new(shift->file->filename);
  },
);

has member_names => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub {
    [grep !m{/$}, shift->archive->memberNames],
  },
);

sub spew
{
  my($self, $content) = @_;
  $self->file->print($content);
  $self->file->close;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
