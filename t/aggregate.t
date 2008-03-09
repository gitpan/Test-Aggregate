#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my $tests = Test::Aggregate->new(
    {
        verbose       => 1,
        dump          => 'dump.t',
        shuffle       => 1,
        dirs          => 'aggtests',
        set_filenames => 1,
    }
);
$tests->run;
