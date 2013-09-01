use strict;
use warnings;
BEGIN { eval q{ use EV; } }
use Test::More tests => 2;

use_ok 'WebService::TwitterBootstrap::Download::Custom';
use_ok 'WebService::TwitterBootstrap::Download::Custom::Zip';
