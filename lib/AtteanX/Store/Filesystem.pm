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
use Types::Path::Tiny qw/Path AbsDir/;;
use File::Find;
use File::stat;

use Data::Dumper;
use Carp;

with 'Attean::API::QuadStore';
with 'Attean::API::CostPlanner';
with 'MooX::Log::Any';

has 'graph_dir' => (is => 'ro',
						  required => 1,
						  isa => AbsDir);

# TODO: This is for corner case where URI aliasing would occur without it
has 'local_graph_hashname' => (is => 'ro', 
										  isa => Str,
										  default => 'local-graph-name');



sub uri_to_filename {
  my ($self, $uri) = @_;
  unless ($uri->path =~ m/\.\w+?$/) {
	 # TODO: Support file extensions properly
	 # TODO: Support e.g. .acl
	 # TODO: Support URIs ending with /
	 $uri = URI->new($uri->as_string . '$.ttl');
  }
  
  return $self->graph_dir . $rel->as_string;
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
  my $iter;
  if (blessed($g) && $g->does('Attean::API::IRI')) {
	 open(my $fh, '<' . $self->uri_to_filename($g)) || die "Couldn't open file"; 
	 $iter = $parser->parse_iter_from_io($fh, $self->local_base)->as_quad($g);
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
			  my $dir = $self->graph_dir;
			  my $base = $self->local_base->as_string;
			  $file =~ s/^$dir/$base/;
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

