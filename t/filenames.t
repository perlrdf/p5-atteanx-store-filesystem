use strict;
use warnings;
use Test::More;

use Attean;
use File::Temp;
use Data::Dumper;

use_ok('AtteanX::Store::Filesystem');


my $local_dir = File::Temp->newdir();
my $nonlocal_dir = File::Temp->newdir();
my $store = AtteanX::Store::Filesystem->new(
														  local_base => 'http://localhost/',
														  local_graph_dir => $local_dir->dirname,
														  nonlocal_graph_dir => $nonlocal_dir->dirname
														 );

isa_ok($store, 'AtteanX::Store::Filesystem');

my $luri = URI->new('http://localhost/foo/bar');
is($store->uri_to_filename($luri), $local_dir->dirname . 'foo/bar$.ttl', 'Basic filename map');

done_testing;
