package AtteanX::Store::Filesystem;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use Moo;
use Type::Tiny::Role;
use Types::URI -all;
use Types::Standard qw(ConsumerOf InstanceOf Str);
use Attean;
use Attean::RDF;
use Scalar::Util qw(blessed);

use Data::Dumper;
use Carp;

with 'Attean::API::QuadStore';
with 'MooX::Log::Any';

has 'local_base' => (is => 'ro',
							isa => ConsumerOf['Attean::API::IRI'],
							coerce => sub { blessed($_[0]) ? Attean::IRI->new($_[0]->as_string) : Attean::IRI->new($_[0]) });

has 'local_graph_dir' => (is => 'ro',
								  required => 1,
								  isa => Str);

has 'nonlocal_graph_dir' => (is => 'ro',
									  isa => Str);

has 'local_graph_hashnames' => (is => 'ro',
										  isa => Str,
										  default => 'local-graph-name');



sub uri_to_filename {
  my ($self, $uri) = @_;
  unless ($uri->path =~ m/\.\w+?$/) {
	 # TODO: Support file extensions properly
	 $uri = URI->new($uri->as_string . '$.ttl');
  }
  my $rel = $uri->rel($self->local_base->value);
  my $graph_dir = ($uri->eq($rel)) ? $self->nonlocal_graph_dir : $self->local_graph_dir;
  return $graph_dir . $rel->as_string;
}

sub get_quads {
  return 1;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Store::Filesystem - Generic Filesystem-based Quad Store for Attean

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-atteanx-store-filesystem/issues>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

