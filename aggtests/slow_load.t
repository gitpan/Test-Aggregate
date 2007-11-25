#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More 'no_plan'; # tests => 1;
use Slow::Loading::Module;
ok 1, 'slow loading module loaded';
