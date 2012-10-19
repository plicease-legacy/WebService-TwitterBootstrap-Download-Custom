package WebService::TwitterBootstrap::Download::Custom;

use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::JSON;
use WebService::TwitterBootstrap::Download::Custom::Zip;
use Moose;

# ABSTRACT: Download a customized version of Twitter Bootstrap
# VERSION

has js => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] }, 
);

has css => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] },
);

has vars => (
  is      => 'rw',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub { { } }
);

has img => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] }
);

has ua => (
  is      => 'ro',
  isa     => 'Mojo::UserAgent',
  lazy    => 1,
  default => sub { Mojo::UserAgent->new },
);

sub download
{
  my($self) = @_;
  
  my $json = Mojo::JSON->new;
  
  my $tx = $self->ua->post_form('http://bootstrap.herokuapp.com/', {
    js   => $json->encode($self->js),
    css  => $json->encode($self->css),
    vars => $json->encode($self->vars),
    img  => $json->encode($self->img),
  });
  
  my $res = $tx->success;
  
  unless($res)
  {
    my($error, $code) = $tx->error;
    die "$code $error";
  }

  my $zip = WebService::TwitterBootstrap::Download::Custom::Zip->new;
  $zip->spew($res->body);
  $zip;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
