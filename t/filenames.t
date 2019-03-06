use strict;
use warnings;
use Test::More;

use Attean;
use Path::Tiny;
use Data::Dumper;

use_ok('AtteanX::Store::Filesystem');

my $local_dir = Path::Tiny->tempdir;

my $store = AtteanX::Store::Filesystem->new(
														  graph_dir => $local_dir
														 );

isa_ok($store, 'AtteanX::Store::Filesystem');

subtest 'Simple case with empty suffix' => sub {
  my $luri = URI->new('http://localhost/foo/bar');
  my $file = $local_dir->stringify . '/http/localhost/foo/bar$.ttl';
  is($store->uri_to_filename($luri), $file, 'Basic filename map');
};

subtest 'Simple case with other suffix' => sub {
  my $luri = URI->new('http://localhost/foo/bar.rdf');
  my $file = $local_dir->stringify . '/http/localhost/foo/bar.rdf';
  is($store->uri_to_filename($luri), $file, 'Basic filename map');
};

subtest 'Port number case with empty suffix' => sub {
  my $luri = URI->new('http://localhost:8443/foo/bar');
  my $file = $local_dir->stringify . '/http/localhost:8443/foo/bar$.ttl';
  is($store->uri_to_filename($luri), $file, 'Basic filename map');
};

subtest 'User in authority case with empty suffix' => sub {
  my $luri = URI->new('http://dahut@localhost/foo/bar');
  my $file = $local_dir->stringify . '/http/dahut@localhost/foo/bar$.ttl';
  is($store->uri_to_filename($luri), $file, 'Basic filename map');
};

# TODO:
#subtest 'Just a URN test' => sub {
#	 my $luri = URI->new('urn:foobar:test');
#	 is($store->uri_to_filename($luri), $local_dir->stringify . '/urn/foobar/test$.ttl', 'Basic filename map');
#};
done_testing;
