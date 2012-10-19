use strict;
use warnings;
use File::HomeDir::Test;
use Test::More;
use WebService::TwitterBootstrap::Download::Custom;

if($ENV{PLICEASE_LIVE})
{ plan tests => 2 }
else
{ plan skip_all => 'live test disabled' }

my $dl = WebService::TwitterBootstrap::Download::Custom->new;
isa_ok $dl, 'WebService::TwitterBootstrap::Download::Custom';

my $ret = eval { $dl->fetch_defaults };
diag $@ if $@;
isa_ok $ret, 'WebService::TwitterBootstrap::Download::Custom';

use YAML ();
diag YAML::Dump({
  map { $_ => $dl->$_ } qw( js css vars img )
});
