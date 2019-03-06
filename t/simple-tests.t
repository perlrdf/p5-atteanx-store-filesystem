use strict;
use warnings;
use Test::More;

use Attean;
use Data::Dumper;
use FindBin qw($Bin);

use_ok('AtteanX::Store::Filesystem');


my $local_dir = $Bin . '/simple-test-data/';
my $store = AtteanX::Store::Filesystem->new(
														  graph_dir => $local_dir,
														 );

isa_ok($store, 'AtteanX::Store::Filesystem');

ok(my $iter = $store->get_graphs);

isa_ok($iter, 'Attean::ListIterator');

ok(my $uri = $iter->next);

is($uri->value, 'http://localhost/foo/bar');

warn Dumper($store->get_graphs);

done_testing;
