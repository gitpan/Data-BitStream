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

  plan tests => scalar @implementations;

  foreach my $type (@implementations) {
    my $stream = new_stream($type);
    BAIL_OUT("No stream of type $type") unless defined $stream;
    my ($esub, $dsub, $param) = sub_for_string($encoding);
    BAIL_OUT("No sub for encoding $encoding") unless defined $esub and defined $dsub;
    my @got;
    my @data = (0 .. 67, 81, 96, 107, 127, 128, 129, 255, 256, 257, 510, 511, 512, 513);
    foreach my $n (@data) {
      $stream->erase_for_write;
      $esub->($stream, $param, $n);
      $stream->rewind_for_read;
      my $v = $dsub->($stream, $param);
      push @got, $v;
    }
    is_deeply( \@data, \@got, "$encoding put/get values between 0 and 513");
  }
}
