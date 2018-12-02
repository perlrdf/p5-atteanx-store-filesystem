=pod

=encoding utf-8

=head1 PURPOSE

Run standard Test::Attean::QuadStore tests

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Roo;

with 'Test::Attean::QuadStore', 'Test::Attean::Store::Filesystem::Role::CreateStore';
run_me;

done_testing;

