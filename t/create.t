use strict;
use warnings;
use Test::More tests => 1;
use WebService::TwitterBootstrap::Download::Custom;

my $dl = eval { WebService::TwitterBootstrap::Download::Custom->new };
diag $@ if $@;

isa_ok $dl, 'WebService::TwitterBootstrap::Download::Custom';
