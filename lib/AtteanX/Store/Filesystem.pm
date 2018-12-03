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
use Path::Tiny;
use File::Find;

use Data::Dumper;
use Carp;

with 'Attean::API::QuadStore';
with 'Attean::API::CostPlanner';
with 'MooX::Log::Any';

has 'local_base' => (is => 'ro',
							isa => Uri,
							coerce => 1
							);

has 'local_graph_dir' => (is => 'ro',
								  required => 1,
								  isa => Str); # TODO: make these Path::Tiny

has 'nonlocal_graph_dir' => (is => 'ro',
									  isa => Str);

has 'local_graph_hashname' => (is => 'ro',
										  isa => Str,
										  default => 'local-graph-name');



sub uri_to_filename {
  my ($self, $uri) = @_;
  unless ($uri->path =~ m/\.\w+?$/) {
	 # TODO: Support file extensions properly
	 $uri = URI->new($uri->as_string . '$.ttl');
  }
  my $rel = $uri->rel($self->local_base);
  my $graph_dir = ($uri->eq($rel)) ? $self->nonlocal_graph_dir : $self->local_graph_dir;
  return $graph_dir . $rel->as_string;
}

sub filename_to_uri {
  my ($self, $filename) = @_;
  my ($graph) = $filename =~ s/^$self->local_graph_dir/$self->local_base->as_string/;
  if ($filename =~ m/^$self->nonlocal_graph_dir(.*)/) {
	 $graph = $1;
  }
  return URI->new($graph)
}

sub get_quads {
  my $self = shift;
  my ($s, $p, $o, $g) = @_;
  my $parser = Attean->get_parser('Turtle')->new();
  my $iter
  if (blessed($g) && $g->does('Attean::API::IRI')) {
	 open(my $fh, '<' . $self->uri_to_filename($g)) || die "Couldn't open file"; 
	 $iter = $parser->parse_iter_from_io($fh, $self->local_base)->as_quad;
  } else {
	 # TODO: OMG, we have to traverse all files...
  }
  # TODO: Filter other terms
}

sub get_graphs {
  my $self = shift;
  my @graphs;
  find(sub {
			if ($File::Find::name =~ m/^(.*?)\$?\.ttl$/) {
			  my $file = $1;
			  my $dir = $self->local_graph_dir;
			  my $base = $self->local_base->as_string;
			  $file =~ s/^$dir/$base/;
			  $file .= '#' . $self->local_graph_hashname;
			  push(@graphs, Attean::IRI->new($file))
			}
		 },
		 $self->local_graph_dir);
	 # TODO: non-local graphs
  return Attean::ListIterator->new( values => \@graphs, item_type => 'Attean::API::Term' );
}

sub cost_for_plan {
	my $self	= shift;
	my $plan	= shift;
	if ($plan->isa('Attean::Plan::Quad')) {
	  my $cost = 1; 	  # TODO grab size of file system
	  if ($plan->graph->does('Attean::API::Variable')) {
		 $cost *= 100; 		 # TODO if plan has graph as variable, penalize heavily
	  }
	  return $cost;
	}
	return;
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

