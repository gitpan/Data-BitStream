#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use BitStreamTest;

my @implementations = impl_list;
my @encodings       = encoding_list;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {
  subtest "$encoding" => sub { test_encoding($encoding); };
}
done_testing();


sub test_encoding {
  my $encoding = shift;

  plan tests => 2 * scalar @implementations;

  foreach my $type (@implementations) {
    my $nfibs = 22;
    if (is_universal($encoding)) {
      $nfibs = 47;
      {
        my $mstream = new_stream($type);
        $nfibs = 80 if $mstream->maxbits >= 64;
      }
    }

    my @fibs = (0,1,1);
    my ($v2, $v1) = ( $fibs[-2], $fibs[-1] );
    for (scalar @fibs .. $nfibs) {
      ($v2, $v1) = ($v1, $v2+$v1);
      push(@fibs, $v1);
    }

    {
      my @data = @fibs;
      my $stream = stream_encode_array($type, $encoding, @data);
      BAIL_OUT("No stream of type $type") unless defined $stream;
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$encoding store F(0) - F($nfibs) using $type");
    }

    {
      my @data = reverse @fibs;
      my $stream = stream_encode_array($type, $encoding, @data);
      BAIL_OUT("No stream of type $type") unless defined $stream;
      my @v = stream_decode_array($encoding, $stream);
      is_deeply( \@v, \@data, "$encoding store F($nfibs) - F(0) using $type");
    }
  }
}
