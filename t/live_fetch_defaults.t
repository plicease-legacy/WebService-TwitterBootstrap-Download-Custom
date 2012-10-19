use strict;
use warnings;
use Test::More tests => 2;
use WebService::TwitterBootstrap::Download::Custom;

my $dl = WebService::TwitterBootstrap::Download::Custom->new;
isa_ok $dl, 'WebService::TwitterBootstrap::Download::Custom';

my $ret = eval { $dl->fetch_defaults };
diag $@ if $@;
isa_ok $ret, 'WebService::TwitterBootstrap::Download::Custom';

#use YAML ();
#diag YAML::Dump({
#  map { $_ => $dl->$_ } qw( js css vars img )
#});
