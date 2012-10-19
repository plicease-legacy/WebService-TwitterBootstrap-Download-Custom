package WebService::TwitterBootstrap::Download::Custom;

use strict;
use warnings;
use v5.10;
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::JSON;
use WebService::TwitterBootstrap::Download::Custom::Zip;
use Path::Class qw( file );
use Moose;

# ABSTRACT: Download a customized version of Twitter Bootstrap
# VERSION

has js => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] }, 
);

has css => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] },
);

has vars => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub { { } }
);

has img => (
  is      => 'ro',
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

has labels => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub { {} },
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

sub fetch_defaults
{
  my($self) = @_;
  
  # reset
  @{ $self->js }   = ();
  @{ $self->css }  = ();
  @{ $self->img }  = ();
  %{ $self->vars } = ();
  
  my $tx = $self->ua->get("http://webcache.googleusercontent.com/search?q=cache:http://twitter.github.com/bootstrap/customize.html");
  #my $tx = $self->ua->get("http://twitter.github.com/bootstrap/customize.html");
  
  my $res = $tx->success;
  unless($res)
  {
    my($error,$code) = $tx->error;
    die "$code $error";
  }
  my $dom = $res->dom;
  
  $dom->find('label.checkbox')->each(sub {
    my($dom) = @_;
    my $label = $dom->text;
    my $value = $dom->find('input')->first->attrs('value');
    $self->labels->{$value} = $label;
    given($value) {
      when(/\.less$/) { push @{ $self->css }, $value }
      when(/\.js$/)   { push @{ $self->js  }, $value }
    }
  });
  
  my $key;
  $dom->find('section#variables')
      ->first
      ->find('*')
      ->grep(sub { $_->type eq 'input' || $_->type eq 'label' })
      ->each(sub {
      
    my($dom) = @_;
    
    if($dom->type eq 'label')
    {
      $key = $dom->text;
    }
    else
    {
      my $value = $dom->attrs('placeholder');
      $self->vars->{$key} = $value;
      if($value =~ /\.png'$/)
      {
        $value =~ s/'//g;
        push @{ $self->img }, file( $value )->basename;
      }
    }

  });
  
  $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
