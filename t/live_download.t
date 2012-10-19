use strict;
use warnings;
use File::HomeDir::Test;
use Test::More;
use WebService::TwitterBootstrap::Download::Custom;
use File::Temp qw( tempdir );
use Path::Class qw( dir );

if($ENV{PLICEASE_LIVE})
{ plan tests => 4 }
else
{ plan skip_all => 'live test disabled' }

my $dl = WebService::TwitterBootstrap::Download::Custom->new(
  js   => ["bootstrap-button.js","bootstrap-collapse.js"],
  css  => ["navs.less","navbar.less"],
  vars => { "\@bodyBackground" => "\@black","\@textColor" => "\@white" },
  img  => ["glyphicons-halflings.png","glyphicons-halflings-white.png"],
);

isa_ok $dl, 'WebService::TwitterBootstrap::Download::Custom';

my $zip = eval { $dl->download };
diag $@ if $@;

isa_ok $zip, 'WebService::TwitterBootstrap::Download::Custom::Zip';

my $dir = tempdir( CLEANUP => 1);

my $ret = eval { $zip->extract_all($dir) };
isa_ok $ret, 'WebService::TwitterBootstrap::Download::Custom::Zip';

ok -e dir($dir)->file('js', 'bootstrap.js'), "exists js/bootstrap.js";
