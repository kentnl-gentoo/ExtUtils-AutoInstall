# $File: //member/autrijus/ExtUtils-AutoInstall/AutoInstall.pm $ 
# $Revision: #25 $ $Change: 2741 $ $DateTime: 2001/12/29 04:53:34 $

package ExtUtils::AutoInstall;
require 5.005;

$ExtUtils::AutoInstall::VERSION = '0.25';

use strict;

use Cwd;
use ExtUtils::MakeMaker;

=head1 NAME

ExtUtils::AutoInstall - Automatic install of dependencies via CPAN

=head1 SYNOPSIS

In F<Makefile.PL>:

    # ExtUtils::AutoInstall Bootstrap Code, version 1.
    BEGIN { my $p='ExtUtils::AutoInstall'; eval"use $p 0.21;1" or(print
	    "*** Fetching $p.\n"), require CPAN, CPAN::install $p; eval
	    "use $p 0.21;1" or die "*** Please install $p manually.\n"}

    use ExtUtils::AutoInstall (
	-version	=> '0.21',	# ExtUtils::AutoInstall version
	-config		=> {
	    make_args	=> '--hello'	# option(s) for CPAN::Config 
	},
	-core		=> [		# core modules
	    Package0	=> '',		# any version would do
	],
	'Feature1'	=> [
	    # do we want to install this feature by default?
	    -default	=> ( system('feature1 --version') == 0 ),
	    Package1	=> '0.01',
	],
	'Feature2'	=> [
	    # associate tests to be disabled along with this
	    -tests	=> [ <t/feature2*.t> ],
	    Package2	=> '0.02',
	],
	'Feature3'	=> {		# hash reference works, too
	    Package3	=> '0.03',
	}
    );

    WriteMakefile(
	AUTHOR          => 'Joe Hacker (joe@hacker.org)',
	ABSTRACT        => 'Perl Interface to Joe Hacker',
	NAME            => 'Joe::Hacker',
	VERSION_FROM    => 'Hacker.pm',
	DISTNAME        => 'Joe-Hacker',
    );

Invoking the resulting F<Makefile.PL>:

    % perl Makefile.PL			# default behaviour
    % perl Makefile.PL --checkdeps	# check only, no Makefile produced
    % perl Makefile.PL --skipdeps	# ignores all dependencies

Using F<make> (or F<nmake>):

    % make [all|test|install]		# default behaviour
    % make checkdeps			# same as the --checkdeps above
    % make installdeps			# install dependencies only

=head1 DESCRIPTION

B<ExtUtils::AutoInstall> lets module writers to specify a more
sophisticated form of dependency information than the C<PREREQ_PM>
option offered by B<ExtUtils::MakeMaker>.

Prerequisites are grouped into B<features>, and the user could
choose yes/no on each one's dependencies; the module writer may
also supply a boolean value via C<-default> to specify the default
choice.

The B<Core Features> marked by the name C<-core> is an exception:
all missing packages that belongs to it will be installed without
prompting the user, unless the user explicitly disables all features
via C<--skipdeps> command line option.

The dependencies are expressed as pairs of C<Module> => C<version>
inside an a array reference. If the order does not matter, and there
are no C<-default> or C<-tests> directives for that feature, you
may also use a hash reference.

Once B<ExtUtils::AutoInstall> has determined which module(s) are
needed, it checks whether it's running under the B<CPAN> shell and
should let B<CPAN> handle the dependency.

If it's not running under B<CPAN>, the installer will probe for
an active connection by trying to resolve the domain C<cpan.org>,
and check for the user's permission to use B<CPAN>. If all went
well, a separate B<CPAN> instance is created to install the required
modules.

If you have the B<CPANPLUS> package installed in your system,
it is preferred by default over B<CPAN>.

All modules scheduled to install will be deleted from C<%INC> first,
so B<ExtUtils::MakeMaker> will check the newly installed modules.

Finally, the C<WriteMakefile()> is overridden to perform some
additional checks, as well as skips tests associated with
disabled features by the C<-tests> option.

The actual installation happens right after at the end of the C<make
config> target; i.e. both C<make test> and C<make install> will
trigger the installation of required modules first.

Additionally, you could use the C<make installdeps> target to install
the modules, and the C<make checkdeps> target to check dependencies
without actually installing them. The C<perl Makefile.PL --checkdeps>
command has an equivalent effect.

=head1 CAVEATS

B<ExtUtils::AutoInstall> will add C<UNINST=1> to your B<make install>
flag if your effective uid is 0 (root), unless you explicitly disable
it by setting B<CPAN>'s C<make_install_arg> configuration option to
include C<UNINST=0>.

This I<may> cause dependency problems if you are using a customized
directory structure for your site. Please consult L<CPAN/FAQ> for an
explanation in detail.

B<Inline::MakeMaker> is not happy with this module, since it prohibits
competing C<MY::postamble> functions. Patches welcome.

=head1 NOTES

Since this module is needed before writing F<Makefile>, it makes
little use as a CPAN module; hence each distribution must include
it in full. The only alternative I'm aware of, namely prompting
in F<Makefile.PL> to force user install it (cf. the B<Template>
Toolkit's dependency on B<AppConfig>) is not very desirable either.

The current compromise is to add this check before every script:

    # ExtUtils::AutoInstall Bootstrap Code, version 1.
    BEGIN { my $p='ExtUtils::AutoInstall'; eval"use $p 0.21;1" or(print
	    "*** Fetching $p.\n"), require CPAN, CPAN::install $p; eval
	    "use $p 0.21;1" or die "*** Please install $p manually.\n"}

But that ain't pretty, and won't work without internet connection.

Since we do not want all future options of B<ExtUtils::AutoInstall>
to be painfully detected manually like above, this module provides
a I<bootstrapping> mechanism via the C<-version> flag. If a newer
version is needed by the F<Makefile.PL>, it will go ahead to fetch
a new version, reload it into memory, and pass the arguments forward.

If you have any ideas, please let me know. Thanks.

=cut

# special map on pre-defined feature sets
my %FeatureMap = (
    ''	    => 'Core Features', # XXX: deprecated
    '-core' => 'Core Features',
);

# missing modules, existing modules, disabled tests
my (@Missing, @Existing, %DisabledTests, $UnderCPAN, $HasCPANPLUS);
my ($Config, $CheckOnly, $SkipInstall); 

foreach my $arg (@ARGV) {
    if ($arg =~ /^--config=(.*)$/) {
	$Config = [ split(',', $1) ];
	next;
    }
    elsif ($arg =~ /^--installdeps=(.*)$/) {
	__PACKAGE__->install($Config, split(',', $1));
	exit 0;
    }
    elsif ($arg =~ /^--checkdeps$/) {
	$CheckOnly = 1;
	next;
    }
    elsif ($arg =~ /^--skipdeps$/) {
	$SkipInstall = 1;
	next;
    }
}

sub _prompt { goto &ExtUtils::MakeMaker::prompt; }

sub import {
    my $class = shift;
    my @args  = @_ or return;

    print "*** $class version ".$class->VERSION."\n";
    print "*** Checking for dependencies...\n";

    my $cwd = Cwd::cwd();

    $Config  = [];

    my $maxlen = length((sort { length($b) <=> length($a) }
	grep { /^[^\-]/ } map { keys %{ref($_) eq 'HASH' ? $_ : +{@{$_}}} }
	map { +{@args}->{$_} }
	grep { /^[^\-]/ or /^-core$/i } keys %{+{@args}})[0]);

    while (my ($feature, $modules) = splice(@args, 0, 2)) {
	my (@required, @tests);
	my $default = 1;

	if ($feature =~ m/^-(\w+)$/) {
	    my $option = lc($1);

	    # check for a newer version of myself
	    _update_to($modules, @_) and return	if $option eq 'version';
	    # sets CPAN configuration options
	    $Config = $modules			if $option eq 'config';

	    next unless $option eq 'core';
	}

	print "[".($FeatureMap{lc($feature)} || $feature)."]\n";

	$modules = [ %{$modules} ] if UNIVERSAL::isa($modules, 'HASH');

	unshift @$modules, -default => &{shift(@$modules)}
	    if (ref($modules->[0]) eq 'CODE'); # XXX: bugward combatability

	while (my ($mod, $arg) = splice(@$modules, 0, 2)) {
	    if ($mod =~ m/^-(\w+)$/) {
		my $option = lc($1);

		$default = $arg  if ($option eq 'default');
		@tests = @{$arg} if ($option eq 'tests');

		next;
	    }

	    printf("- %-${maxlen}s ...", $mod);

	    if (my $cur = _version_check(_load($mod), $arg ||= 0)) {
		print "loaded. ($cur".($arg ? " >= $arg" : '').")\n";
		push @Existing, $mod => $arg;
	    }
	    else {
		print "failed! (need".($arg ? "s $arg" : 'ed').")\n";
		push @required, $mod => $arg;
	    }
	}

	next unless @required;

	if (!$SkipInstall and (($feature eq '-core') or $CheckOnly or _prompt(
	    qq{==> Do you wish to install the }. (@required / 2).
	    qq{ optional module(s)?}, $default ? 'y' : 'n',
	) =~ /^[Yy]/)) {
	    push (@Missing, @required);
	}
	else {
	    @DisabledTests{map { glob($_) } @tests} = 1;
	}
    }

    if (@Missing) {
	my $lock;

	unless (_has_cpanplus()) {
	    require CPAN; CPAN::Config->load;
	    $lock = MM->catfile($CPAN::Config->{cpan_home}, ".lock");
	}


	if (-f $lock and open(LOCK, $lock)
	    and ($^O eq 'MSWin32' ? _under_cpan() : <LOCK> == getppid())
	    and ($CPAN::Config->{prerequisites_policy} || '') ne 'ignore'
	) {
	    print << '.';

*** Since we're running under CPAN, I'll just let it take care
    of the dependency's installation later.
.
	    $UnderCPAN = 1;
	}
	elsif (!$CheckOnly) {
	    print << '.';
*** Dependencies will be installed the next time you type 'make'.
.
	}

	close LOCK;
    }

    chdir $cwd;

    print "*** $class configuration finished.\n";
}

sub install {
    my $class  = shift;
    my @config = @{+shift};

    print "*** Installing dependencies...\n";

    return unless _connected_to('cpan.org');
    
    if (_has_cpanplus()) {
	require CPANPLUS::Backend;
    }
    else {
	return unless _can_write(
	    MM->catfile($CPAN::Config->{cpan_home}, 'sources')
	);

	# if we're root, set UNINST=1 to avoid trouble unless user asks for it.
	$CPAN::Config->{make_install_arg} .= ' UNINST=1' if index(
	    $CPAN::Config->{make_install_arg} ||= '', 'UNINST'
	) == -1 and eval qq{ $> eq '0' };

	# don't show start-up info
	$CPAN::Config->{inhibit_startup_message} = 1;

	# set additional options
	while (my ($opt, $arg) = splice(@config, 0, 2)) {
	    $CPAN::Config->{$opt} = $arg;
	}
    }

    my $installed = 0;
    my $cpanplus_backend = CPANPLUS::Backend->new if $HasCPANPLUS;

    while (my ($pkg, $ver) = splice(@_, 0, 2)) {
	print "*** Installing $pkg...\n";

	my $pathname = $pkg; $pathname =~ s/::/\\W/;
	delete $INC{$_} foreach grep { m/$pathname.pm/i } keys(%INC);

	if ($cpanplus_backend) {
	    $cpanplus_backend->install(modules => [ $pkg ]);
	    $installed++; next;
	}

	require CPAN; CPAN::Config->load;
	my $obj = CPAN::Shell->expand(Module => $pkg);

	if ($obj and _version_check($obj->cpan_version, $ver)) {
	    $obj->install;
	    $installed++;
	}
	else {
	    print << ".";

*** Could not find a version $ver or above for $pkg; skipping.
.
	}
    }

    print "*** $class installation finished.\n";

    return $installed;
}

sub _has_cpanplus {
    return ($HasCPANPLUS = eval "use CPANPLUS; 1;");
}

# make guesses on whether we're under the CPAN installation directory
sub _under_cpan {
    require Cwd;
    require File::Spec;

    my $cwd  = File::Spec->canonpath(Cwd::cwd());
    my $cpan = File::Spec->canonpath($CPAN::Config->{cpan_home});
    
    return (index($cwd, $cpan) > -1);
}

sub _update_to {
    my $class = __PACKAGE__;
    my $ver   = shift;

    return if _version_check(_load($class), $ver); # no need to upgrade

    print << ".";

*** A newer version of $class ($ver) is required.
    Trying to fetch it from CPAN...
.

    # install ourselves
    eval qq{ use $class; 1 } and return $class->import(@_)
	if $class->install([], $class, $ver);

    print << '.'; exit 1;

*** Cannot bootstrap myself. :-( Installation terminated.
.
}

sub _connected_to {
    my $site = shift;

    return (
	qq{use Socket; Socket::inet_aton('$site') } or _prompt(qq(
*** Your host cannot resolve the domain name '$site', which
    probably means the Internet connections are unavailable.
==> Should we try to install the required module(s) anyway?), 'n'
	) =~ /^[Yy]/
    );
}

sub _can_write {
    my $path = shift;
    mkdir ($path, 0777) unless -e $path;

    return (
	-w $path or _prompt(qq(
*** You are not allowed to write to the directory '$path';
    the installation may fail due to insufficient permissions.
==> Should we try to install the required module(s) anyway?), 'n'
	) =~ /^[Yy]/
    );
}

sub _load {
    my $mod = pop; # class/instance doesn't matter
    return eval qq{ use $mod; $mod->VERSION } || 0;
}

sub _version_check {
    my ($cur, $min) = @_; $cur =~ s/\s+$//;

    if ($Sort::Versions::VERSION or _load('Sort::Versions')) {
	# use Sort::Versions as the sorting algorithm 
	return ((Sort::Versions::versioncmp($cur, $min) != -1) ? $cur : 0);
    }
    else {
	# plain comparison
	local $^W = 0; # shuts off 'not numeric' bugs
	return ($cur >= $min ? $cur : 0);
    }
}

# nothing; this usage is deprecated.
sub main::PREREQ_PM { return {}; }

sub main::WriteMakefile {
    require Carp;
    Carp::croak "WriteMakefile: Need even number of args" if @_ % 2;

    if ($CheckOnly) {
	print << ".";
*** Makefile not written in check-only mode.
.
	return;
    }


    my %args = @_;

    $args{PREREQ_PM} = { %{$args{PREREQ_PM} ||= {} }, @Existing, @Missing }
	if $UnderCPAN;

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

    my $missing = join(',', @Missing);
    my $config  = join(',',
	UNIVERSAL::isa($Config, 'HASH') ? %{$Config} : @{$Config}
    ) if $Config;

    my $action = (
	$missing ? "\$(PERL) $0 --config=$config --installdeps=$missing"
		 : "\$(NOOP)"
    );

    no strict 'refs';
    *{'MY::postamble'} = sub {
	return << ".";
config :: installdeps

checkdeps ::
	\$(PERL) $0 --checkdeps

installdeps ::
	$action
.
    };

    ExtUtils::MakeMaker::WriteMakefile(%args);

    return 1;
}

1;

__END__

=head1 SEE ALSO

L<perlmodlib>, L<ExtUtils::MakeMaker>, L<CPAN>, L<CPANPLUS>

=head1 ACKNOWLEDGEMENTS

The test script included in the B<ExtUtils::AutoInstall> distribution
contains code adapted from Michael Schwern's B<Test::More> under the
I<Artistic License>. Please refer to F<tests.pl> for details.

Thanks also to Jesse Vincent (obra) for suggesting the semantics of
various F<make> targets, and Jos Boumans (kane) for introducing me
to his B<CPANPLUS> project.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
