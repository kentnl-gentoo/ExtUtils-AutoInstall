#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 2153 $ $DateTime: 2001/10/19 08:44:50 $

require 5.005;

use ExtUtils::MakeMaker;

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

