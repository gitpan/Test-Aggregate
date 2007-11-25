#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use Test::Aggregate;

$Test::Aggregate::DUMP = 'dump.t';
Test::Aggregate->runtests('aggtests/');
