#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 1348 $ $DateTime: 2002/10/12 10:06:20 $

require 5.005;
require Config;
require 'AutoInstall.pm';

my $have_cc = _can_run($Config::Config{cc});

ExtUtils::AutoInstall->import(
    -core			=> [
	'Cwd'			=> '',
	'Carp'			=> '',
	'ExtUtils::Manifest'	=> '',
	'ExtUtils::MakeMaker'	=> '',
    ],
    'CPANPLUS support'		=> [
	'CPANPLUS'		=> '0.032',
    ],
    'CPAN.pm support'		=> [
	-default		=> 0,
	'CPAN'			=> '1.0',
    ],
    'Nondecimal version number support' => [
$have_cc ? (
	'version'		=> '0.20',
) : (
	'Sort::Versions'	=> '1.2',
),
    ],
);

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Automatic install of dependencies via CPAN',
    NAME		=> 'ExtUtils::AutoInstall',
    VERSION_FROM	=> 'AutoInstall.pm', 
    DISTNAME		=> 'ExtUtils-AutoInstall',
    BINARY_LOCATION	=> 'x86/ExtUtils-AutoInstall.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

sub _can_run {
    my $command = shift;

    require File::Spec;
    for my $dir (split /$Config::Config{path_sep}/, $ENV{PATH}) {
        my $abs = File::Spec->catfile($dir, $command);
        return $abs if $abs = MM->maybe_command($abs);
    }

    return;
}

