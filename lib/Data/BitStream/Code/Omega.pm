package Data::BitStream::Code::Omega;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Omega::AUTHORITY = 'cpan:DANAJ';
}
BEGIN {
  $Data::BitStream::Code::Omega::VERSION = '0.01';
}

use Mouse::Role;
requires 'read', 'write', 'skip';

# Elias Omega code.
#
# Store the number of binary bits in recursive Gamma codes, followed by the
# number in binary.
#
# Very rarely used code.  Sometimes called "recursive Elias" or "logstar".
#
# See:  Peter Elias, "Universal codeword sets and representations of the integers", IEEE Trans. Information Theory 21(2):194-203, Mar 1975.
#
# See: Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996

sub _base_of { my $d = shift; my $base = 0; $base++ while ($d >>= 1); $base; }

sub put_omega {
  my $self = shift;

  foreach my $v (@_) {
    my $val = $v;
    die "Value must be >= 0" unless $val >= 0;
    # Need to figure out a way to get the decoder to output 0 when we get ~0
    $val++;

    # Simpler code, prepending each group to a list.
    #  my @d = ( [1,0] );    # bits, value
    #  while ($val > 1) {
    #    my $base = _base_of($val);
    #    unshift @d, [$base+1, $val];
    #    $val = $base;
    #  }
    #  foreach my $aref (@d) {  $self->write( @{$aref} );  }

    # This code bundles up groups of 32-bit writes.  Almost 2x faster.
    my @d;
    my $cbits = 1;
    my $cword = 0;
    while ($val > 1) {
      my $base = _base_of($val) + 1;

      if (($cbits + $base) >= 32) {
        unshift @d, [$cbits, $cword];
        $cword = $val;
        $cbits = $base;
      } else {
        $cword |= ($val << $cbits);
        $cbits += $base;
      }

      $val = $base-1;
    }
    if (scalar @d == 0) {
      $self->write($cbits, $cword);
    } else {
      unshift @d, [$cbits, $cword];
      foreach my $aref (@d) {
        $self->write( @{$aref} );
      }
    }
  }
  1;
}

sub get_omega {
  my $self = shift;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  while ($count-- > 0) {
    my $val;
    my $first_bit;
    # Speedup reading the first couple sets of codes.  30-80% faster overall.
    if (1) {  # TODO fix for array
      my $prefix = $self->read(7, 'readahead');
      last unless defined $prefix;
      $val = 1;
      $prefix <<= 1;
      if (($prefix & 0x80) == 0) {
        $self->skip(1);
        push @vals, 0;
        next;
      } elsif (($prefix & 0x20) == 0) {
        $self->skip(3);
        push @vals, 1 + (($prefix & 0x40) != 0);
        next;
      } elsif ($prefix & 0x40) {                # read 4 more bits
        $val = ($prefix >> 2) & 0x0F;
        $self->skip(7);
        if (($prefix & 0x02) == 0) {
          push @vals, $val-1;
          next;
        }
      } else {                             # read 3 more bits
        $val = ($prefix >> 3) & 0x07;
        $self->skip(6);
        if (($prefix & 0x04) == 0) {
          push @vals, $val-1;
          next;
        }
      }
      do {
         $val = (1 << $val) | $self->read($val);
      } while ($first_bit = $self->read(1));
    } else {
      $val = 1;
      while ($first_bit = $self->read(1)) {
        $val = (1 << $val) | $self->read($val);
      }
    }
    last unless defined $first_bit;
    push @vals, ($val == 0) ? ~0 : $val-1;
  }
  wantarray ? @vals : $vals[-1];
}
no Mouse;
1;

# ABSTRACT: A Role implementing Elias Omega codes

=pod

=head1 NAME

Data::BitStream::Code::Omega - A Role implementing Elias Omega codes

=head1 VERSION

version 0.01

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the Elias Omega codes.  The role applies to a stream object.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_omega($value) >

=item B< put_omega(@values) >

Insert one or more values as Omega codes.  Returns 1.

=item B< get_omega() >

=item B< get_omega($count) >

Decode one or more Omega codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< skip >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Peter Elias, "Universal codeword sets and representations of the integers", IEEE Trans. Information Theory 21(2), pp. 194-203, Mar 1975.

=item Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996

=back

=head1 BUGS

The all-bits-on sequence C<~0> does not encode correctly.

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
