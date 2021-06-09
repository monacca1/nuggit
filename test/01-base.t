#!/usr/bin/env perl
use Test2::V0;
use Test2::Plugin::BailOnFail; # TODO: Can we set per-subtest instead?
use strict;
use warnings;
use v5.10;
use FindBin;


# Simplest test: Confirm that ngt's runtime check succeeds
my $check = `ngt check`;
ok(!$?, "ngt check");
