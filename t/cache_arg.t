use strict;
use warnings;
use v5.10;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More tests => 9;
use WebService::TwitterBootstrap::Download::Custom;

my $default_cache_dir = eval { WebService::TwitterBootstrap::Download::Custom->_default_cache_dir };
diag $@ if $@;
ok -d $default_cache_dir, "default_cache_dir: " . ($default_cache_dir // '[undef]');
isa_ok $default_cache_dir, 'Path::Class::Dir';

isa_ok eval { WebService::TwitterBootstrap::Download::Custom->new->cache }, 'Path::Class::Dir';
diag $@ if $@;
is eval { WebService::TwitterBootstrap::Download::Custom->new->cache }, $default_cache_dir, "use default by default";
diag $@ if $@;

is eval { WebService::TwitterBootstrap::Download::Custom->new(cache => 0)->cache } , undef, "0 transfers to undef";
diag $@ if $@;
is eval { WebService::TwitterBootstrap::Download::Custom->new(cache => 1)->cache }, $default_cache_dir, "use default when cache = 1";
diag $@ if $@;

my $other_dir = Path::Class::Dir->new(File::HomeDir->my_home, qw( data) );
$other_dir->mkpath(0,0755);
ok -d $other_dir, "other_dir: $other_dir";

is eval { WebService::TwitterBootstrap::Download::Custom->new(cache => $other_dir)->cache }, $other_dir, "other_dir Path::Class::Dir";
is eval { WebService::TwitterBootstrap::Download::Custom->new(cache => $other_dir->stringify)->cache }, $other_dir, "other_dir as string";