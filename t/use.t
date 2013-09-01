use strict;
use warnings;
BEGIN { eval { use EV; } }
use Test::More tests => 2;

use_ok 'WebService::TwitterBootstrap::Download::Custom';
use_ok 'WebService::TwitterBootstrap::Download::Custom::Zip';
