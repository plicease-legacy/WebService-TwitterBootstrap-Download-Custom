package WebService::TwitterBootstrap::Download::Custom;

use strict;
use warnings;
use v5.10;
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::JSON;
use WebService::TwitterBootstrap::Download::Custom::Zip;
use Path::Class qw( file );
use File::HomeDir;
use Scalar::Util qw( looks_like_number );
use File::Temp qw( tempdir );
use DBI;
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

=item 1. fetch default values 

Using the C<fetch_defalts> method:

 use WebService::TwitterBootstrap::Download::Custom;
 my $dl = WebService::TwitterBootstrap::Download::Custom->new;
 $dl->fetch_defaults;

=item 2. filter

Remove any jQuery plugins or CSS components that you don't want.
As an example here we are removing the tooltip component and the
tab plugin.

 @{ $dl->css } = grep !/^tooltip\.less$/,     @{ $dl->css };
 @{ $dl->js  } = grep !/^bootstrap-tab\.js$/, @{ $dl->js };

=item 3. modify variables

Replace the values of any variables with new ones appropriate for your project

 $dl->vars->{'@altFontFamily'} = '@serifFontFamily';

=item 4. download

Fetch the custom bootstrap using the C<download> method.

 my $zip = $dl->download;

=item 5. extract

Using the resulting instance of L<WebService::TwitterBootstrap::Download::Custom::Zip>,
extract files using its C<extract_all> method.

 $zip->extract_all('/your/project/location');

=back

To visualize all of the defaults, it is probably worth looking at
L<http://twitter.github.com/bootstrap/customize.html>, where the 
defaults are retrieved.

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

=head2 cache

Cache customizations of bootstrap.  That is, if you provide the same input
customization it will used a local cached copy instead of consulting the
website.  Cached copies are kept only for a set time and will be refreshed.

Set this to 0 (zero) to turn of caching.   Set to 1 (one) to use the default
location (somewhere in your home directory using L<File::HomeDir>).  Anything
else will be treated as a directory bath to find the cache.

This value gets converted and is used internally as a L<Path::Class::Dir>.

=cut

sub _default_cache_dir
{
  state $dir = Path::Class::Dir->new(
    File::HomeDir->my_dist_data('WebService-TwitterBootstrap-Download-Custom', { create => 1 }),
  );
  $dir;
}

has cache => (
  is       => 'ro',
  isa      => 'Path::Class::Dir',
);

# intercept cache=1 and cache=0 and translate
around BUILDARGS => sub
{
  my $orig = shift;
  my $class = shift;
  my $args = ref $_[0] ? $_[0] : { @_ };
  $args->{cache} //= 1;
  if(looks_like_number($args->{cache}) && $args->{cache} == 1)
  { $args->{cache} = _default_cache_dir }
  elsif($args->{cache})
  { $args->{cache} = Path::Class::Dir->new($args->{cache}) }
  else
  { delete $args->{cache} }
  $class->$orig($args);
};

has ua => (
  is      => 'ro',
  isa     => 'Mojo::UserAgent',
  lazy    => 1,
  default => sub { Mojo::UserAgent->new },
);

has _cache_dir => (
  is       => 'ro',
  isa      => 'Path::Class::Dir',
  lazy     => 1,
  default  => sub {
    my $self = shift;
    return $self->cache // Path::Class::Dir->new(tempdir( CLEANUP => 1 ));
  },
);

has _cache_dbh => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my($self) = @_;
    my $dbfile = $self->_cache_dir->file('cache.sqlite');
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", { RaiseError => 1, AutoCommit => 1 });
    $dbh->do(q{
      CREATE TABLE IF NOT EXISTS zip (
        id INTEGER PRIMARY KEY,
        unix_timestamp INTEGER,
        js VARCHAR,
        css VARCHAR,
        vars VARCHAR,
        img VARCHAR,
        filename VARCHAR
      )
    });
    my $sth = $dbh->prepare(q{ SELECT id, filename FROM zip WHERE unix_timestamp < ? });
    $sth->execute(time - 60*60*24*7);
    while(my $h = $sth->fetchrow_hashref)
    {
      unlink $self->_cache_dir->file($h->{filename});
      $dbh->do(q{ DELETE FROM zip WHERE id = ? }, undef, $h->{id});
    }
    $dbh;
  },
);

sub _cache_sqlargs
{
  my($self) = @_;
  (join(':', sort @{ $self->js   }),
   join(':', sort @{ $self->css  }),
   join(':', sort map { sprintf "%s=%s", $_ => $self->vars->{$_} } keys %{ $self->vars }),
   join(':', sort @{ $self->img  }));
}

sub _cache_fetch
{
  my($self) = @_;
  my $sth = $self->_cache_dbh->prepare(q{
    SELECT
      filename
    FROM
      zip
    WHERE 
      js   = ? AND
      css  = ? AND
      vars = ? AND
      img  = ?
  });
  $sth->execute($self->_cache_sqlargs);
  my $h = $sth->fetchrow_hashref;
  return unless defined $h;
  my $file = $self->_cache_dir->file($h->{filename});
  return $file if -e $file;
}

sub _cache_store
{
  my($self, $file) = @_;
  my $sth = $self->_cache_dbh->prepare(q{
    REPLACE INTO zip (filename, unix_timestamp, js, css, vars, img) VALUES (?,?,?,?,?,?)
  });
  $sth->execute($file->basename, time, $self->_cache_sqlargs);
  $self;
}

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
  
  my $zip = WebService::TwitterBootstrap::Download::Custom::Zip->new;
  
  if(my $cached_file = $self->_cache_fetch)
  {
    $zip->spew($cached_file);
  }
  else
  {
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
    
    if($self->cache)
    {
      $zip->file(
        File::Temp->new(
          TEMPLATE => "bootstrapXXXXXX", 
          SUFFIX   => '.zip',
          DIR      => $self->cache->stringify,
        ),
      );
    }
    
    $zip->spew($res->body);
    
    $self->_cache_store(Path::Class::File->new($zip->file->filename));
  }
  
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
  
  my $dom;
  my $cache_file = $self->_cache_dir->file('customize.html');
  if(-e $cache_file && (-M $cache_file < 6))
  {
    $dom = Mojo::DOM->new(scalar $cache_file->slurp);
  }
  else
  {
    #my $tx = $self->ua->get("http://webcache.googleusercontent.com/search?q=cache:http://twitter.github.com/bootstrap/customize.html");
    my $tx = $self->ua->get("http://twitter.github.com/bootstrap/customize.html");
  
    my $res = $tx->success;
    unless($res)
    {
      my($error,$code) = $tx->error;
      die "$code $error";
    }
    $dom = Mojo::DOM->new($res->body);
    $cache_file->spew($res->body);
  }
  
  $dom->find('label.checkbox')->each(sub {
    my($dom) = @_;
    my $label = $dom->text;
    my $value = $dom->find('input')->first->attrs('value');
    $self->labels->{$value} = $label;
    push @{ $self->css }, $value if $value =~ /\.less$/;
    push @{ $self->js  }, $value if $value =~ /\.js$/;
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
