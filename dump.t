use Test::Aggregate::Builder;
BEGIN { $Test::Aggregate::Builder::CHECK_PLAN = 0 };
;
my $TEST_AGGREGATE_STARTUP;
{
my ($startup);
$startup=3;
$TEST_AGGREGATE_STARTUP=sub {
  use warnings;
  use strict 'refs';
  $startup++;
};

}

my $TEST_AGGREGATE_SHUTDOWN;
{
my ($shutdown);
$shutdown=0;
$TEST_AGGREGATE_SHUTDOWN=sub {
  use warnings;
  use strict 'refs';
  $shutdown++;
};

}

my $TEST_AGGREGATE_SETUP;
{
my ($setup);
$setup=3;
$TEST_AGGREGATE_SETUP=sub {
  use warnings;
  use strict 'refs';
  $setup++;
};

}

my $TEST_AGGREGATE_TEARDOWN;
{
my ($teardown);
$teardown=0;
$TEST_AGGREGATE_TEARDOWN=sub {
  use warnings;
  use strict 'refs';
  $teardown++;
};

}

my $LAST_TEST_NUM = 0;
if ( __FILE__ eq 'dump.t' ) {
    package Test::Aggregate; # ;)
    my $builder = Test::Builder->new;
    $TEST_AGGREGATE_STARTUP->() if __FILE__ eq 'dump.t';
    $TEST_AGGREGATE_SETUP->('aggtests/00-load.t');
    Test::More::diag("******** running tests for aggtests/00-load.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtests00loadt->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/00-load.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/00-load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/boilerplate.t');
    Test::More::diag("******** running tests for aggtests/boilerplate.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsboilerplatet->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/boilerplate.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/boilerplate.t');

    $TEST_AGGREGATE_SETUP->('aggtests/check_plan.t');
    Test::More::diag("******** running tests for aggtests/check_plan.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestscheck_plant->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/check_plan.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/check_plan.t');

    $TEST_AGGREGATE_SETUP->('aggtests/findbin.t');
    Test::More::diag("******** running tests for aggtests/findbin.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsfindbint->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/findbin.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/findbin.t');

    $TEST_AGGREGATE_SETUP->('aggtests/skip_all.t');
    Test::More::diag("******** running tests for aggtests/skip_all.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsskip_allt->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/skip_all.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/skip_all.t');

    $TEST_AGGREGATE_SETUP->('aggtests/slow_load.t');
    Test::More::diag("******** running tests for aggtests/slow_load.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsslow_loadt->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/slow_load.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/slow_load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/subs.t');
    Test::More::diag("******** running tests for aggtests/subs.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestssubst->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/subs.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/subs.t');

    $TEST_AGGREGATE_SHUTDOWN->() if __FILE__ eq 'dump.t';
}
{
#################### beginning of aggtests/00-load.t ####################
    package aggtests00loadt;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtests00loadt} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtests00loadt} = 'aggtests/00-load.t';
local $0 = 'aggtests/00-load.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/00-load.t"


use Test::More tests => 2;

use lib 't/lib';

BEGIN {
    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/00-load.t ####################
}
{
#################### beginning of aggtests/boilerplate.t ####################
    package aggtestsboilerplatet;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestsboilerplatet} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestsboilerplatet} = 'aggtests/boilerplate.t';
local $0 = 'aggtests/boilerplate.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/boilerplate.t"


use strict;
use warnings;
use Test::More tests => 3;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    local *FH;
    open FH, "< $filename"
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <FH>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

module_boilerplate_ok('lib/Test/Aggregate.pm');


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/boilerplate.t ####################
}
{
#################### beginning of aggtests/check_plan.t ####################
    package aggtestscheck_plant;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestscheck_plant} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestscheck_plant} = 'aggtests/check_plan.t';
local $0 = 'aggtests/check_plan.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/check_plan.t"


use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 4;

BEGIN { ok 1, "$0 ***** 1" }
END   { ok 1, "$0 ***** 4" }
ok 1, "$0 ***** 2";

SKIP: {
    skip "checking plan ($0 ***** 3)", 1;
    ok 1;
}


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/check_plan.t ####################
}
{
#################### beginning of aggtests/findbin.t ####################
    package aggtestsfindbint;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestsfindbint} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestsfindbint} = 'aggtests/findbin.t';
local $0 = 'aggtests/findbin.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/findbin.t"


use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
use File::Spec::Functions qw/rel2abs catfile/;

is(rel2abs(catfile($FindBin::Bin, 'findbin.t')), rel2abs($0), 'findbin is reinitialized for every test');


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/findbin.t ####################
}
{
#################### beginning of aggtests/skip_all.t ####################
    package aggtestsskip_allt;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestsskip_allt} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestsskip_allt} = 'aggtests/skip_all.t';
local $0 = 'aggtests/skip_all.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/skip_all.t"


use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More skip_all => 'Testing skip all';

ok 0, 'Should not reach here';


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/skip_all.t ####################
}
{
#################### beginning of aggtests/slow_load.t ####################
    package aggtestsslow_loadt;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestsslow_loadt} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestsslow_loadt} = 'aggtests/slow_load.t';
local $0 = 'aggtests/slow_load.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/slow_load.t"


use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;
ok 1, 'slow loading module loaded';


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/slow_load.t ####################
}
{
#################### beginning of aggtests/subs.t ####################
    package aggtestssubst;
    sub run_the_tests {
        AGGTESTBLOCK: {
        if ( my $reason = $Test::Aggregate::Builder::SKIP_REASON_FOR{aggtestssubst} )
        {
            Test::Builder->new->skip($reason);
            last AGGTESTBLOCK;
        }
$Test::Aggregate::Builder::FILE_FOR{aggtestssubst} = 'aggtests/subs.t';
local $0 = 'aggtests/subs.t';
my $reinit_findbin = FindBin->can(q/again/);
$reinit_findbin->() if $reinit_findbin;

# line 1 "aggtests/subs.t"


use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;

{
    no warnings;
    my $whee = 'whee!';
    sub whee { return $whee }
}

is whee(), 'whee!', 'subs work!';


        } # END AGGTESTBLOCK:
    }
#################### end of aggtests/subs.t ####################
}
