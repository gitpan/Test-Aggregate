package Test::Aggregate;

use warnings;
use strict;

use Test::Builder::Module;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Test::Builder::Module);
use Test::More;
use Carp 'croak';

use File::Find;

@EXPORT = @Test::More::EXPORT;

=head1 NAME

Test::Aggregate - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.05

=cut

$VERSION = '0.05';

=head1 SYNOPSIS

    use Test::Aggregate;

    my $tests = Test::Aggregate->new( {
        dirs => $aggregate_test_dir,
    } );
    $tests->run;

=head1 DESCRIPTION

B<WARNING>:  this is ALPHA code.  The interface is not guaranteed to be
stable.

A common problem with many test suites is that they can take a long time to
run.  The longer they run, the less likely you are to run the tests.  This
module borrows a trick from C<Apache::Registry> to load up your tests at once,
create a separate package for each test and wraps each package in a method
named C<run_the_tests>.  This allows us to load perl only once and related
modules only once.  If you have modules which are expensive to load, this can
dramatically speed up a test suite.

=head1 USAGE

Create a separate directory for your tests.  This should not be a subdirectory
of your regular test directory.  Write a small driver program and put it in
your regular test directory (C<t/> is the standard):

 use Test::Aggregate;
 my $other_test_dir = 'aggregate_tests';
 my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
 });
 $tests->run;

Take your simplest tests and move them, one by one, into the new test
directory and keep running the C<Test::Aggregate> program.  You'll find some
tests will not run in a shared environment like this.  You can either fix the
tests or simply leave them in your regular test directory.  See how this
distribution's tests are organized for an example.

=head1 METHODS

=head2 C<new>
 
 my $tests = Test::Aggregate->new(
     {
         dirs          => 'aggtests',
         dump          => 'dump.t',     # optional
         shuffle       => 1,            # optional
         matching      => qr/customer/, # optional
         set_filenames => 1,            # optional
     }
 );
 
Creates a new C<Test::Aggregate> instance.  Accepts a hashref with the
following keys:

=over 4

=item * C<dirs> (mandatory)

The directories to look in for the aggregated tests.  This may be a scalar
value of a single directory or an array refernce of multiple directories.

=item * C<dump> (optional)

You may list the name of a file to dump the aggregated tests to.  This is
useful if you have test failures and need to debug why the tests failed.

=item * C<shuffle> (optional)

Ordinarily, the tests are sorted by name and run in that order. This allows
you to run them in any order.

=item * C<matching> (optional)

If supplied with a regular expression (requires the C<qr> operator), will only
run tests whose filename matches the regular expression.

=item * C<set_filenames> (optional)

If supplied with a true value, this will cause the following to be added for
each test:

  local $0 = $test_filename;

Tests which depend on the value of $0 can often be made to work with this.

=back

=head2 C<run>

 $tests->run;

Attempts to aggregate and run all tests listed in the directories specified in
the constructor.

=cut

sub new {
    my ( $class, $arg_for ) = @_;

    unless ( exists $arg_for->{dirs} ) {
        Test::More::BAIL_OUT("You must supply 'dirs'");
    }
        
    my $dirs = $arg_for->{dirs};
    $dirs = [$dirs] if 'ARRAY' ne ref $dirs;

    my $matching = qr//;
    if ( $arg_for->{matching} ) {
        $matching = delete $arg_for->{matching};
        unless ( 'Regexp' eq ref $matching ) {
            $class->_croak("Argument for 'matching' must be a pre-compiled regex");
        }
    }

    my $self = bless {
        dump          => $arg_for->{dump},
        shuffle       => $arg_for->{shuffle},
        dirs          => $dirs,
        matching      => $matching,
        set_filenames => $arg_for->{set_filenames},
    } => $class;
}

sub _dump           { shift->{dump} }
sub _should_shuffle { shift->{shuffle} }
sub _matching       { shift->{matching} }
sub _set_filenames  { shift->{set_filenames} }
sub _dirs           { @{ shift->{dirs} } }

sub _get_tests {
    my $self = shift;
    my @tests;
    my $matching = $self->_matching;
    find( {
            no_chdir => 1,
            wanted   => sub {
                push @tests => $File::Find::name if /\.t\z/ && /$matching/;
            }
    }, $self->_dirs );
    
    if ( $self->_should_shuffle ) {
        $self->_shuffle(@tests);
    }
    else {
        @tests = sort @tests;
    }
    return @tests;
}

sub _shuffle {
    my $self = shift;

    # Fisher-Yates shuffle
    my $i = @_;
    while ($i) {
        my $j = rand $i--;
        @_[ $i, $j ] = @_[ $j, $i ];
    }
    return;
}

sub run {
    my $self  = shift;
    my @tests = $self->_get_tests;

    my $code = $self->_test_builder_override;

    my @packages;
    my $separator = '#' x 20;
    
    my $test_packages = '';

    my $dump = $self->_dump;

    $code .= "\nif ( __FILE__ eq '$dump' ) {\n";
    foreach my $test (@tests) {
        my $test_code = $self->_slurp($test);
        if ( $test_code =~ /^(__(?:DATA|END)__)/m ) {
            Test::More::BAIL_OUT("Test $test not allowed to have $1 token");
        }
        if ( $test_code =~ /skip_all/m ) {
            warn
              "Found possible 'skip_all'.  This can cause test suites to abort";
        }
        my $package   = $self->_get_package($test);
        push @packages => [ $test, $package ];
        $code .= <<"        END_CODE";
    Test::More::ok(1, "******** running tests for $test ********");
    $package->run_the_tests;
        END_CODE

        my $set_filenames = $self->_set_filenames
            ? "local \$0 = '$test';"
            : '';
        $test_packages .= <<"        END_CODE";
{
$separator beginning of $test $separator
package $package;
sub run_the_tests {
$set_filenames
$test_code
}
$separator end of $test $separator
}
        END_CODE
    }

    $code .= "}\n$test_packages";

    if ( $dump ne '' ) {
        local *FH;
        open FH, "> $dump" or die "Could not open ($dump) for writing: $!";
        print FH $code;
        close FH;
    }
    eval $code;
    if ( my $error = $@ ) {
        croak("Could not run tests: $@");
    }

    foreach my $data (@packages) {
        my ( $test, $package ) = @$data;
        Test::More::ok(1, "******** running tests for $test ********");
        $package->run_the_tests;
    }
}

sub _slurp {
    my ( $class, $file ) = @_;
    local *FH;
    open FH, "< $file" or die "Cannot read ($file): $!";
    return do { local $/; <FH> };
}

sub _get_package {
    my ( $class, $file ) = @_;
    $file =~ s/\W//g;
    return $file;
}

sub _test_builder_override {
    return <<'END_CODE';
{
    use Test::Builder;
    use Test::Builder::Module;

    no warnings 'redefine';

    sub Test::Builder::DESTROY {
        my $builder = shift;
        my $tests   = $builder->current_test;
        $builder->_print("1..$tests\n");
    }

    sub Test::Builder::_plan_check {
        my $self = shift;

        # Will this break under threads?
        $self->{Expected_Tests} = $self->{Curr_Test} + 1;
    }

    sub Test::Builder::no_header { 1 }

    sub Test::Builder::plan {
        my ( $self, $cmd, $arg ) = @_;

        return unless $cmd;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        # XXX need to disable the plan check
        #if( $self->{Have_Plan} ) {
        #    $self->croak("You tried to plan twice");
        #}

        if ( $cmd eq 'no_plan' ) {
            $self->no_plan;
        }
        elsif ( $cmd eq 'skip_all' ) {
            return $self->skip_all($arg);
        }
        elsif ( $cmd eq 'tests' ) {
            if ($arg) {
                local $Test::Builder::Level = $Test::Builder::Level + 1;
                return $self->expected_tests($arg);
            }
            elsif ( !defined $arg ) {
                $self->croak("Got an undefined number of tests");
            }
            elsif ( !$arg ) {
                $self->croak("You said to run 0 tests");
            }
        }
        else {
            my @args = grep { defined } ( $cmd, $arg );
            $self->croak("plan() doesn't understand @args");
        }

        return 1;
    }
}
END_CODE
}

=head1 CAVEATS

Not all tests can be included with this technique.  If you have C<Test::Class>
tests, there is no need to run them with this.  Otherwise:

=over 4

=item * C<__END__> and C<__DATA__> tokens.

These won't work and the tests will call BAIL_OUT() if these tokens are seen.

=item * C<BEGIN> and C<END> blocks.

Since all of the tests are aggregated together, C<BEGIN> and C<END> blocks
will be for the scope of the entire set of aggregated tests.

=item * Syntax errors

Any syntax errors encountered will cause this program to BAIL_OUT().  This is
why it's recommended that you move your tests into your new directory one at a
time:  it makes it easier to figure out which one has caused the problem.

=item * C<no_plan>

Unfortunately, due to how this works, the plan is always C<no_plan>.  If
C<Test::Builder> implements "deferred plans", we can get a bit more safety.
See
L<http://groups.google.com/group/perl.qa/browse_thread/thread/d58c49db734844f4/cd18996391acc601?#cd18996391acc601>
for more information.

=item * No 'skip_all' tests, please

Tests which potentially 'skip_all' will cause the aggregate test suite to
abort prematurely.  Do not attempt to aggregate them.  This may be fixed in a
future release.

=item * C<Variable "$x" will not stay shared at (eval ...>

Because each test is wrapped in a method call, any of your subs which access a
variable in an outer scope will likely throw the above warning.  Pass in
arguments explicitly to suppress this.

Instead of:

 my $x = 17;
 sub foo {
     my $y = shift;
     return $y + $x;
 }

Write this:

 my $x = 17;
 sub foo {
     my ( $y, $x ) = @_;
     return $y + $x;
 }

=item * Singletons

Be very careful of code which loads singletons.  Oftimes those singletons in
test suites may be altered for testing purposes, but later attempts to use
those singletons can fail dramatically as they're not expecting the
alterations.  (Your author has painfully learned this lesson with database
connections).

=back

=head1 DEBUGGING AGGREGATE TESTS

Before aggregating tests, make sure that you add tests B<one at a time> to the
aggregated test directory.  Attempting to add many tests to the directory at
once and then experiencing a failure means it will be much harder to track
down which tests caused the failure.

Debugging aggregated tests which fail is a multi-step process.  Let's say the
following fails:

 my $tests = Test::Aggregate->new(
     {
         dump    => 'dump.t',
         shuffle => 1,
         dirs    => 'aggtests',
     }
 );
 $tests->run;

=head2 Manually run the tests

The first step is to manually run all of the tests in the C<aggtests> dir.

 prove -r aggtests/

If the failures appear the same, fix them just like you would fix any other
test failure and then rerun the C<Test::Aggregate> code.

Sometimes this means that a different number of tests run from what the
aggregted tests run.  Look for code which ends the program prematurely, such
as an exception or an C<exit> statement.

=head2 Run a dump file

If this does not fix your problem, create a dump file by passing 
C<< dump => $dumpfile >> to the constructor (as in the above example).  Then
try running this dumpfile directly to attempt to replicate the error:

 prove -r $dumpfile

=head2 Tweaking the dump file

Assuming the error has been replicated, open up the dump file.  The beginning
of the dump file will have some code which overrides some C<Test::Builder>
internals.  After that, you'll see the code which runs the tests.  It will
look similar to this:

 if ( __FILE__ eq 'dump.t' ) {
     Test::More::ok(1, "******** running tests for aggtests/boilerplate.t ********");
     aggtestsboilerplatet->run_the_tests;
     Test::More::ok(1, "******** running tests for aggtests/subs.t ********");
     aggtestssubst->run_the_tests;
     Test::More::ok(1, "******** running tests for aggtests/00-load.t ********");
     aggtests00loadt->run_the_tests;
     Test::More::ok(1, "******** running tests for aggtests/slow_load.t ********");
     aggtestsslow_loadt->run_the_tests;
 }

You can try to narrow down the problem by commenting out all of the
C<run_the_tests> lines and gradually reintroducing them until you can figure
out which one is actually causing the failure.

=head1 COMMON PITFALLS

=head2 C<BEGIN>, C<CHECK>, C<INIT> and C<END> blocks

Remember that since the tests are now being run at once, these blocks will no
longer run on a per-test basis, but will run for the entire aggregated set of
tests.  You may need to examine these individually to determine the problem.

=head2 C<Test::NoWarnings>

This is a great test module.  When aggregating tests together, however, it can
cause pain as you'll often discover warnings that you never new existed.  For
a quick fix, add this before you attempt to run your tests:

 $INC{'Test/NoWarnings.pm'} = 1;

That will disable C<Test::NoWarnings>, but you'll want to go in later to fix
them.

=head2 Paths

Many tests make assumptions about the paths to files and moving them into a
new test directory can break this.

=head2 C<$0>

Tests which use C<$0> can be problematic as the code is run in an C<eval>
through C<Test::Aggregate> and C<$0> may not match expectations.  This also
means that it can behave differently if run directly from a dump file.

As it turns out, you can assign to C<$0>!  If C<< set_filenames => 1 >> is
passed to the constructor, every test will have the following added to its
package:

 local $0 = $test_file_name;

=head2 Minimal test case

If you cannot solve the problem, feel free to try and create a minimal test
case and send it to me (assuming it's something I can run).

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-aggregate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Aggregate

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Aggregate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Aggregate>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Aggregate>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Aggregate>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to mauzo (L<http://use.perl.org/~mauzo/> for helping me find the
'skip_all' bug.

Thanks to Johan Lindström for pointing me to Apache::Registry.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
