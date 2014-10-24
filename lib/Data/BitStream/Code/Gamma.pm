package Data::BitStream::Code::Gamma;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Gamma::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::Code::Gamma::VERSION = '0.01';
}

use Mouse::Role;
requires qw(maxbits read write put_unary get_unary);

# Elias Gamma code.
#
# Store the number of binary bits in Unary code, then the value in binary
# excepting the top bit which is known from the unary code.
#
# Like Unary, this encoding is used as a component of many other codes.
# Hence it is not unreasonable for a base Bitstream class to code this
# if it can make a substantially faster implementation.  Also this class
# is assumed to be part of the base class, so no 'with Gamma' needs or should
# be done.  It is done by the base classes if needed.

sub put_gamma {
  my $self = shift;

  foreach my $val (@_) {
    die "Value must be >= 0" unless $val >= 0;
    # Simple:
    #
    #   my $base = 0;
    #   { my $v = $val+1; $base++ while ($v >>= 1); }
    #   $self->put_unary($base);
    #   $self->write($base, $val+1)  if $base > 0;
    #
    # More optimized, and handles encoding 0 - ~0
    if    ($val == 0)  { $self->write(1, 1); }
    elsif ($val == 1)  { $self->write(3, 2); }  # optimization
    elsif ($val == 2)  { $self->write(3, 3); }  # optimization
    elsif ($val == ~0) { $self->put_unary($self->maxbits); }
    else {
      my $base = 0;
      { my $v = $val+1; $base++ while ($v >>= 1); }
      if ($base < 16) {
        $self->write( $base+1+$base, (1<<$base) | ($val+1) );
      } else {
        $self->put_unary($base);   # Unary code the base
        $self->write($base, $val+1);
      }
    }
  }
  1;
}

sub get_gamma {
  my $self = shift;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  while ($count-- > 0) {
    my $base = $self->get_unary();
    last unless defined $base;
    if    ($base == 0) {  push @vals, 0; }
    elsif ($base == 1) {  push @vals, (2 | $self->read(1))-1; }  # optimization
    elsif ($base == 2) {  push @vals, (4 | $self->read(2))-1; }  # optimization
    elsif ($base == $self->maxbits) { push @vals, ~0; }
    else  {
      push @vals, ((1 << $base) | $self->read($base))-1;
    }
  }
  wantarray ? @vals : $vals[-1];
}
no Mouse;
1;

# ABSTRACT: A Role implementing Elias Gamma codes

=pod

=head1 NAME

Data::BitStream::Code::Gamma - A Role implementing Elias Gamma codes

=head1 VERSION

version 0.01

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the Elias Gamma codes.  The role applies to a stream object.

This is a very common and very useful code, and is used to create some other
codes (e.g. Elias Delta, Gamma-Golomb, and Exponential-Golomb).

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_gamma($value) >

=item B< put_gamma(@values) >

Insert one or more values as Gamma codes.  Returns 1.

=item B< get_gamma() >

=item B< get_gamma($count) >

Decode one or more Gamma codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Required Methods

=over 4

=item B< maxbits >

=item B< read >

=item B< write >

=item B< put_unary >

=item B< get_unary >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Peter Elias, "Universal codeword sets and representations of the integers", IEEE Trans. Information Theory 21(2), pp. 194-203, Mar 1975.

=item Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
