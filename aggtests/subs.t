#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 2;
use Slow::Loading::Module;

{
    no warnings;
    my $whee = 'whee!';
    sub whee { return $whee }
}

is whee(), 'whee!', 'subs work!';

SKIP: {
    skip 'Test::Aggregate not loaded', 1
      unless exists $INC{'Test/Aggregate.pm'};
    ok $ENV{TEST_AGGREGATE},
      '... and the TEST_AGGREGATE environment variable should be set';
}
