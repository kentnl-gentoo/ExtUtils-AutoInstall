#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 1 $ $DateTime: 2002/06/11 08:35:12 $

require 5.005;
require 'AutoInstall.pm';

ExtUtils::AutoInstall->import(
    -core			=> [
	'Cwd'			=> '',
	'Carp'			=> '',
	'ExtUtils::Manifest'	=> '',
	'ExtUtils::MakeMaker'	=> '',
    ],
    'CPANPLUS Support'		=> [
	'CPANPLUS'		=> 0.032,
    ],
    'CPAN.pm Support'		=> [
	-default		=> 0,
	'CPAN'			=> 1.0,
    ],
    'Advanced version sorting'	=> [
	'Sort::Versions'	=> 1.2,
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

