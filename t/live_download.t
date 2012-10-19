use strict;
use warnings;
use Test::More tests => 2;
use WebService::TwitterBootstrap::Download::Custom;

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

