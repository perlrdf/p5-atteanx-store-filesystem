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
use Types::Path::Tiny qw/AbsDir/;
use Path::Tiny;
use Path::Iterator::Rule;
use AtteanX::Store::SimpleTripleStore;

use Data::Dumper;
use Carp;

with 'Attean::API::QuadStore';
with 'Attean::API::CostPlanner';
with 'MooX::Log::Any';

has 'graph_dir' => (is => 'ro',
						  required => 1,
						  coerce => 1,
						  isa => AbsDir);

# TODO: This is for corner case where URI aliasing would occur without it
has 'local_graph_hashname' => (is => 'ro', 
										  isa => Str,
										  default => 'local-graph-name');

my @pos_names	= Attean::API::Quad->variables;

# Implement store-specific methods:

sub uri_to_filename {
  my ($self, $uri) = @_;
  unless ($uri->path =~ m/\.\w+?$/) {
	 # TODO: Support file extensions properly
	 # TODO: Support e.g. .acl
	 # TODO: Support URIs ending with /
	 $uri = URI->new($uri->as_string . '$.ttl');
  }
  my $querypart = ($uri->query) ? '/\?' . $uri->query : '';
  my $schemepart = $uri->scheme || 'noscheme'; # TODO: improve these names
  my $authoritypart = $uri->authority || 'noauthority/';
  my $localpath = path($schemepart . '/' . $authoritypart . $uri->path . $querypart);
  return $localpath->absolute($self->graph_dir);
}

sub filename_to_uri {
  my $self = shift;
  my $filename = shift;
  unless (blessed($filename) && $filename->isa('Path::Tiny')) {
	 $filename = path($filename);
  }
  my $rel = $filename->relative($self->graph_dir);
  my @parts = split('/', $rel->stringify); # TODO, really no method to do this?
  my $graph = URI->new;
  my $schemepart = shift @parts;
  $graph->scheme($schemepart) unless ($schemepart eq 'noscheme');
  my $authoritypart = shift @parts;
  $graph->authority($authoritypart) unless ($authoritypart eq 'noauthority');
  my $last = pop @parts;
  if ($last =~ m/(.*)\$\.ttl/) {
	 push(@parts, $1); # This will add the public part of the filename to the URL
  } else {
	 push(@parts, $last); # Otherwise, just add the same thing
  }
  # TODO: Support query part
  $graph->path(join('/', @parts));
  return Attean::IRI->new($graph->as_string);
}

# Implement QuadStore

sub get_quads {
  my $self = shift;
  my @nodes       = @_;
  my %bound;
  foreach my $pos (0 .. 3) {
	 my $n = $nodes[ $pos ];
	 if (blessed($n) and $n->does('Attean::API::Variable')) {
		$n = undef;
		$nodes[$pos] = undef;
	 }
	 if (blessed($n)) {
		$bound{ $pos_names[$pos] } = $n;
	 }
  }

  my $g = $nodes[3];
  my $parser = Attean->get_parser('Turtle')->new(); # TODO: support other serializations in fs
  my $iter = Attean::IteratorSequence->new(item_type => 'Attean::API::Quad');
  if (blessed($g) && $g->does('Attean::API::IRI')) {
	 # Graph is bound => single file
	 my $fh = $self->uri_to_filename($g)->openr_utf8;
	 $iter->push($parser->parse_iter_from_io($fh, $g)->as_quads($g));
  } else {
	 # Graph is unbound => all files
	 my $rule = Path::Iterator::Rule->new;
	 $rule->file->name("*.ttl"); # TODO: support other serializations
	 my $next = $rule->iter($self->graph_dir);
	 while ( defined( my $file = $next->() ) ) {
		my $path = path($file);
		my $this_graph = $self->filename_to_uri($path);
		$iter->push($parser->parse_iter_from_io($path->openr, $this_graph)->as_quads($this_graph));
	 }
  }
  # Filter the iterator for the other terms of the pattern
  return $iter->grep(sub {
							  my $q   = shift;
							  foreach my $key (keys %bound) {
								 my $term = $q->$key();
								 unless ($term->equals( $bound{$key} )) {
									return 0;
								 }
							  }
							  return 1;
							});
}

sub get_graphs {
  my $self = shift;
  my @graphs;
  my $rule = Path::Iterator::Rule->new;
  $rule->file->nonempty;
  
  my $iter = $rule->iter($self->graph_dir);
  while (my $path = $iter->()) { # TODO: Make this a CodeIterator
	 push(@graphs, Attean::IRI->new($self->filename_to_uri($path)->as_string))
  }
  return Attean::ListIterator->new( values => \@graphs, item_type => 'Attean::API::Term' );
}

# Implement MutableQuadStore

sub add_quad {
  my $self = shift;
  my $quad = shift;
  my $g = $quad->graph;
  my $iter = Attean::IteratorSequence->new(item_type => 'Attean::API::Triple');
  my $fh = $self->uri_to_filename($g)->openrw_utf8( { locked => 1 } );
  my $parser = Attean->get_parser('Turtle')->new();
  my $ser = Attean->get_serializer('Turtle')->new;
  $iter->push($parser->parse_iter_from_io($fh));
  $iter->push(Attean::ListIterator->new(values => [$quad->as_triple],
													 item_type => 'Attean::API::Triple'));
  $ser->serialize_iter_to_io($fh, $iter);
}


# Implement CostPlanner

sub cost_for_plan {
	my $self	= shift;
	my $plan	= shift;
	# TODO: could be improved with more filesystem checks
	if ($plan->isa('Attean::Plan::Quad')) {
	  my $cost = 1;
	  if ($plan->graph->does('Attean::API::Variable')) {
		 my $lstat = stat($self->local_graph_dir) || die "Couldn't find local graph dir in filesystem";
		 my $links = $lstat->nlink;
		 if ($self->has_nonlocal_graph_dir) {
			my $nstat = stat($self->nonlocal_graph_dir) || die "Couldn't find nonlocal graph dir in filesystem";
			$links += $nstat->nlink;
		 }
		 $cost *= $links * 10;
	  }
	  return $cost;
	}
	return;
}

sub plans_for_algebra {
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

