# $File: //member/autrijus/ExtUtils-AutoInstall/AutoInstall.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 2104 $ $DateTime: 2001/10/17 02:49:40 $

package ExtUtils::AutoInstall;
require 5.005;

$ExtUtils::AutoInstall::VERSION = '0.2';

use strict;

use Cwd;
use ExtUtils::MakeMaker;

=head1 NAME

ExtUtils::AutoInstall - Automatic install of dependencies via CPAN

=head1 SYNOPSIS

in F<Makefile.PL>:

    # till we think of a better solution...
    BEGIN { eval q{ require ExtUtils::AutoInstall; 1 } or eval q{
	    warn "*** This module needs ExtUtils::AutoInstall...\n";
	    use CPAN; CPAN::install('ExtUtils::AutoInstall') }; }

    use ExtUtils::MakeMaker;
    use ExtUtils::AutoInstall (
	-core => [
	    # core modules
	    Package1	=> '0.01',
	],
	'Feature1', [
	    # do we want to install this feature by default?
	    -default	=>  (system('feature1 --version') == 0 ),
	    Package2	=> '0.02',
	],
	'Feature2', [
	    # associate tests to be disabled along with this
	    -tests	=> [ <t/feature2*.t> ],
	    Package3	=> '0.03',
	],
    );

    WriteMakefile(
	AUTHOR          => 'Joe Hacker (joe@hacker.org)',
	ABSTRACT        => 'Perl Interface to Joe Hacker',
	NAME            => 'Joe::Hacker',
	VERSION_FROM    => 'Hacker.pm',
	DISTNAME        => 'Joe-Hacker',
    );

=head1 DESCRIPTION

B<ExtUtils::AutoInstall> lets module writers specify a more
sophisticated form of dependency information than the C<PREREQ_PM>
option offered by B<ExtUtils::MakeMaker>.

Prerequisites are grouped into B<features>, and the user could
specify yes/no on each one. The module writer may also supply
a boolean value via C<-default> to specify the default choice.

The B<Core Features> marked by the name C<-core> is an exeption:
all missing packages that belongs to it will be installed without
prompting the user.

Once B<ExtUtils::AutoInstall> knows which modules are needed,
it checks whether it's running under the B<CPAN> shell and should
let B<CPAN> handle the dependency.

If it's not running under B<CPAN>, the installer will probe for
an active connection by trying to resolve the domain C<cpan.org>,
and check for the user's permission to use B<CPAN>. If all tests
pass, a separate B<CPAN> instance is created to install the required
modules.

All modules scheduled to install will be deleted from C<%INC> first,
so B<ExtUtils::MakeMaker> will check the newly installed modules.

Finally, the C<WriteMakefile()> is overrided to perform some
additional checks, as well as skips tests associated with
disabled features by the C<-tests> option.

=head1 CAVEATS

Since this module is needed before writing F<Makefile>, it makes
little use as a CPAN module; hence each distribution must include
it in full. The only alternative I'm aware of, namely prompting
in F<Makefile.PL> to force user install it (cf. the B<Template>
Toolkit's dependency on B<AppConfig>) is not very desirable either.

Of course, it's possible to add this line before every script:

    BEGIN { eval q{ require ExtUtils::AutoInstall; 1 } or eval q{
	    warn "*** This module needs ExtUtils::AutoInstall...\n";
	    use CPAN; CPAN::install('ExtUtils::AutoInstall') }; }

But that ain't pretty.

If you have any solutions, please let me know. Thanks.

=cut

# special map on pre-defined feature sets
my %FeatureMap = (
    '-core' => 'Core Features',
);

# missing modules, existing modules, disabled tests
my (@Missing, @Existing, %DisabledTests); 

sub import {
    my ($class, $pkg) = (shift, caller(0));
    return unless @_; # nothing to do

    print "*** $class version ".$class->VERSION."\n";
    print "*** Checking for dependencies...\n";

    my $cwd = Cwd::cwd();

    while (my ($feature, $modules) = splice(@_, 0, 2)) {
	my (@required, @tests);
	my $default = 1;

	print "[".($FeatureMap{$feature} || $feature)."]\n";

	while (my ($mod, $arg) = splice(@$modules, 0, 2)) {
	    if ($mod =~ m/^-(\w+)$/) {
		my $option = lc($1);

		$default = $arg  if ($option eq 'default');
		@tests = @{$arg} if ($option eq 'tests');

		next;
	    }

	    printf("- %-16s ...", $mod);

	    if (my $cur = _version_check($mod, $arg)) {
		print "loaded. ($cur >= $arg)\n";
		push @Existing, $mod => $arg;
	    }
	    else {
		print "failed! (needs $arg)\n";
		push @required, $mod => $arg;
	    }
	}

	next unless @required;

	if (($feature eq '-core') or ExtUtils::MakeMaker::prompt(
	    qq{==> Do you wish to install the }. (@required / 2).
	    qq{ optional module(s)?}, $default ? 'y' : 'n',
	) =~ /^[Yy]/) {
	    push (@Missing, @required);
	}
	else {
	    @DisabledTests{map { glob($_) } @tests} = 1;
	}
    }

    if (@Missing) {
	print "*** Installing dependencies...\n" if @Missing;

	require CPAN; CPAN::Config->load;

	my $lock = MM->catfile($CPAN::Config->{cpan_home}, ".lock");

	if (-f $lock and open(LOCK, $lock) and <LOCK> == getppid()
	    and ($CPAN::Config->{prerequisites_policy} || '') ne 'ignore'
	) {
	    print << '.';

*** Since we're running under CPAN, I'll just let it take care
    of the dependency's installation later.
.
	}
	elsif (_connected_to('cpan.org') and
	       _can_write(MM->catfile($CPAN::Config->{cpan_home}, 'sources'))
	) {
	    foreach my $package (@Missing) {
		my $pathname = $package; $pathname =~ s/::/\\W/;
		delete $INC{$_} foreach grep { m/$pathname.pm/i } keys(%INC);

		my $obj = CPAN::Shell->expand(Module => $package);
		$obj->install if $obj;
	    }
	}
	else {
	    print << '.';

*** Okay, skipped auto-installation. However, you should still
    install the missing modules manually before doing 'make test'
    or 'make install'.
.
	}

	print "\n";

	close LOCK;
    }

    chdir $cwd;

    print "*** $class finished.\n";
}

sub _connected_to {
    my $site = shift;

    return (
	qq{use Socket; Socket::inet_aton('$site') } or
	ExtUtils::MakeMaker::prompt(qq(
*** Your host cannot resolve the domain name '$site', which
    probably means the internet connections are unavailable.
==> Should we try to install the required modules anyway?), 'n'
	) =~ /^[Yy]/
    );
}

sub _can_write {
    my $path = shift;
    mkdir $path unless -e $path;

    return (
	-w $path or ExtUtils::MakeMaker::prompt(qq(
*** You are not allowed to write to the directory '$path';
    the installation may fail due to insufficient permissions.
==> Should we try to install the required modules anyway?), 'n'
	) =~ /^[Yy]/
    );
}

sub _load {
    my $mod = pop; # class/instance doesn't matter
    return eval qq{ use $mod; $mod->VERSION } || 0;
}

sub _version_check {
    my ($mod, $min) = @_;
    my $cur = _load($mod);

    if ($Sort::Versions::VERSION || _load('Sort::Versions')) {
	# use Sort::Versions as the sorting algorithm 
	return ((Sort::Versions::versioncmp($cur, $min) != -1) ? $cur : 0);
    }
    else {
	# plain comparison
	return ($cur >= $min ? $cur : 0);
    }
}

sub main::WriteMakefile {
    require Carp;
    Carp::croak "WriteMakefile: Need even number of args" if @_ % 2;

    my %args = @_;
    $args{PREREQ_PM} = { %{$args{PREREQ_PM} ||= {}}, @Existing, @Missing };

    if ($args{EXE_FILES}) {
	require ExtUtils::Manifest;
	my $manifest = ExtUtils::Manifest::maniread('MANIFEST');

	$args{EXE_FILES} = [ 
	    grep { exists $manifest->{$_} } @{$args{EXE_FILES}} 
	];
    }

    $args{test}{TESTS} ||= 't/*.t';
    $args{test}{TESTS} = join(' ', grep {
	!exists($DisabledTests{$_}) 
    } map { glob($_) } split(/\s+/, $args{test}{TESTS}));

    ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;

__END__

=head1 SEE ALSO

L<perlmodlib>, L<CPAN>, L<ExtUtils::MakeMaker>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
