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

# TODO cache
# ABSTRACT: Download a customized version of Twitter Bootstrap
# VERSION

=head1 SYNOPSIS

 use WebService::TwitterBootstrap::Download::Custom;
 my $dl = WebService::TwitterBootstrap::Download::Custom->new;
 # ... adjust js, css, vars and img attributes appropriately ...
 $dl->fetch_defaults;
 my $zip = $dl->download;
 $zip->extract_all('/your/project/location');

=head1 DESCRIPTION

This module allows you to create a custom Twitter Bootstrap and download
directly from the website without having to muck about with make files or
node.js.

The most common pattern is probably

=over 4

=item 1. fetch default values using the C<fetch_defaults> method

=item 2. filter out the jQuery plugins and css components you do not want

=item 3. replace any default variables with those appropriate for your project

=item 4. download your custom bootstrap using the C<download> method

=item 5. using the resultant L<WebService::TwitterBootstrap::Download::Custom::Zip> instance extract files using its C<extract_all> method.

=back

=head1 ATTRIBUTES

=head2 js

List reference containing the jQuery plugins to include in your
custom bootstrap.

=cut

has js => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] }, 
);

=head2 css

List reference containing the CSS components to include in your
custom bootstrap.

=cut

has css => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] },
);

=head2 vars

Hash table containing the variable/value pairs.

=cut

has vars => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub { { } }
);

=head2 img

List reference containing the images to include in your custom bootstrap.

=cut

has img => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] }
);

=head2 labels

Hash table containing human understandable labels for the CSS and jQuery
plugins.

=cut

has labels => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  lazy    => 1,
  default => sub { {} },
);

has ua => (
  is      => 'ro',
  isa     => 'Mojo::UserAgent',
  lazy    => 1,
  default => sub { Mojo::UserAgent->new },
);

=head1 METHODS

=head2 $dl-E<gt>download

Download your custom bootstrap.  This will return an instance of
L<WebService::TwitterBootstrap::Download::Custom::Zip>, which can
be interrogated to retrieve the various files that make up your
custom bootstrap.  This method requires Internet access.

=cut

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

=head2 $dl-E<gt>fetch_defaults

Fetch the default values for the C<js>, C<css>, C<img> and C<var> attributes, and
fill out the C<labels> attribute.  This method requires Internet access.

=cut

sub fetch_defaults
{
  my($self) = @_;
  
  # reset
  @{ $self->js }   = ();
  @{ $self->css }  = ();
  @{ $self->img }  = ();
  %{ $self->vars } = ();
  
  #my $tx = $self->ua->get("http://webcache.googleusercontent.com/search?q=cache:http://twitter.github.com/bootstrap/customize.html");
  my $tx = $self->ua->get("http://twitter.github.com/bootstrap/customize.html");
  
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
