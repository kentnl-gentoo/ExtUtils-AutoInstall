#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #10 $ $Change: 7914 $ $DateTime: 2003/09/06 14:42:30 $

use inc::Module::Install;
use lib 'lib';

name		('ExtUtils-AutoInstall');
abstract	('Automatic install of dependencies via CPAN');
author		('Autrijus Tang (autrijus@autrius.org)');
version_from	('lib/ExtUtils/AutoInstall.pm');

requires	('Cwd');
requires	('Carp');
requires	('ExtUtils::Manifest');
requires	('ExtUtils::MakeMaker');

features(
    'CPANPLUS Support' => [
	-default	    => 0,
	'CPANPLUS'	    => '0.043',
    ],
    'CPAN.pm support' => [
	-default	    => 0,
	'CPAN'		    => '1.0',
    ],
    'Nondecimal version number support' => [
	-default	    => 0,
    can_cc()
	? ('version'	    => '0.28')
	: ('Sort::Versions' => '1.2')
    ],
);

check_nmake();
auto_install();
&Meta->write;
&Makefile->write;
