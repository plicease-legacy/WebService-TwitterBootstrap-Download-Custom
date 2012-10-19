use strict;
use warnings;
use v5.10;
use File::HomeDir::Test;
use Test::More tests => 2;
use WebService::TwitterBootstrap::Download::Custom;

my $call_count = 0;
my $dl = WebService::TwitterBootstrap::Download::Custom->new(ua => FakeUA->new);
$dl->fetch_defaults;
is $call_count, 1, 'call count = 1';

$dl = WebService::TwitterBootstrap::Download::Custom->new(ua => FakeUA->new);
$dl->fetch_defaults;
is $call_count, 1, 'call count (still) = 1';

package FakeUA;

use Mojo::Message::Response;
use base qw( Mojo::UserAgent );

sub get
{
  my($self, $url) = @_;
  $call_count++;
  return $self;
}

sub success
{
  state $res;
  unless(defined $res)
  {
    $res = Mojo::Message::Response->new;
    local $/;
    $res->parse(<DATA>);
  }
  return $res;
}

1;

__DATA__
HTTP/1.1 200 OK
Connection: keep-alive
Cache-Control: max-age=86400
Last-Modified: Wed, 05 Sep 2012 03:46:48 GMT
Accept-Ranges: bytes
Date: Fri, 19 Oct 2012 21:37:31 GMT
Content-Length: 26685
Content-Type: text/html
Server: nginx
Expires: Sat, 20 Oct 2012 21:37:31 GMT

<!DOCTYPE html>
<html lang="en">
  <head>
    <title>whatever</title>
  </head>
  <body>
    <section id="variables"></section>
  </body>
</html>