#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #4 $ $Change: 2748 $ $DateTime: 2001/12/30 03:27:51 $

require 5.005;
require 'AutoInstall.pm';

ExtUtils::AutoInstall->import(
    -core			=> [
	'Cwd'			=> '',
	'Carp'			=> '',
	'CPAN'			=> '',
	'ExtUtils::Manifest'	=> '',
	'ExtUtils::MakeMaker'	=> '',
    ],
    'CPANPLUS Support'		=> [
	'CPANPLUS'		=> '',
    ],
    'Advanced version sorting'	=> [
	'Sort::Versions'	=> '',
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
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

