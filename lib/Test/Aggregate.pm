package Test::Aggregate;

use warnings;
use strict;

use Test::Builder::Module;
use vars qw(@ISA @EXPORT $DUMP);
@ISA = qw(Test::Builder::Module);
use Test::More;
use Carp 'croak';

use File::Find;

@EXPORT = @Test::More::EXPORT;

=head1 NAME

Test::Aggregate - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Test::Aggregate;

    Test::Aggregate->runtests($dir);

=head1 DESCRIPTION

B<WARNING>:  this is ALPHA code.  The interface is not guaranteed to be
stable.

A common problem with many test suites is that they can take a long time to
run.  The longer they run, the less likely you are to run the tests.  This
module borrows a trick from C<Apache::Registry> to load up your tests at once,
create a separate package for each test and wraps the code in a method named
C<run_the_tests>.  This allows us to load perl only once and related modules
only once.  If you have modules which are expensive to load, this can
dramatically speed up a test suite.

=head1 USAGE

Create a separate directory for your tests.  This should not be a subdirectory
of your regular test directory.  Write a small driver program and put it in
your regular test directory (C<t/> is the standard):

 use Test::Aggregate;
 my $other_test_dir = 'aggregate_tests';
 Test::Aggregate->runtests($other_test_dir);

Take your simplest tests and move them, one by one, into the new test
directory and keep running the C<Test::Aggregate> program.  You'll find some
tests will not run in a shared environment like this.  You can either fix the
tests or simply leave them in your regular test directory.  See how this
distribution's tests are organized for an example.

=head1 METHODS

=head2 C<runtests>
 
 my $test_dir = 'aggtests/';
 Test::Aggregate->runtests($test_dir);
 
Attempts to aggregate all test programs in a given directory and run them at
the same time.

If C<$Test::Aggregate::DUMP> is set, will attempt to use the value as a
filename and print the code to it.

=cut

sub runtests {
    my ( $class, $dir ) = @_;
    my @tests;
    find( {
            no_chdir => 1,
            wanted   => sub {
                push @tests => $File::Find::name if /\.t\z/;
            }
    }, $dir);

    my $code = $class->_test_builder_override;

    my @packages;
    my $separator = '#' x 20;
    foreach my $test (@tests) {
        my $test_code = $class->_slurp($test);
        if ( $test_code =~ /^(__(?:DATA|END)__)/m ) {
            croak("Test $test not allowed to have $1 token");
        }
        my $package   = $class->_get_package($test);
        push @packages => [ $test, $package ];
        $code .= <<"        END_CODE";
$separator beginning of $test $separator
package $package;

sub run_the_tests {
$test_code
}
$separator end of $test $separator
        END_CODE
    }

    $code .= <<'    END_CODE';
    END {
        no warnings 'redefine';
        *Test::Builder::no_header = sub { 0 }; 
    }
    END_CODE

    if ( defined $DUMP ) {
        open my $fh, '>', $DUMP
          or die "Could not open ($DUMP) for writing: $!";
        print $fh $code;
        close $fh;
    }
    eval $code;
    if ( my $error = $@ ) {
        croak("Could not run tests: $@");
    }

    foreach my $data (@packages) {
        my ( $test, $package ) = @$data;
        ok 1, "******** running tests for $test ********";
        $package->run_the_tests;
    }
}

sub _slurp {
    my ( $class, $file ) = @_;
    open my $fh, '<', $file or die "Cannot read ($file): $!";
    return do { local $/; <$fh> };
}

sub _get_package {
    my ( $class, $file ) = @_;
    $file =~ s/\W//g;
    return $file;
}

sub _test_builder_override {
 return <<'END_CODE';
{
    no warnings 'redefine';
    package Test::Builder;

    sub plan {
        my ( $self, $cmd, $arg ) = @_;

        return unless $cmd;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

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
    sub no_header { 1 }
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

=back

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

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::Aggregate
