#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #8 $ $Change: 4887 $ $DateTime: 2003/03/23 00:10:11 $

use inc::Module::Install;
require './AutoInstall.pm';

name		('ExtUtils::AutoInstall');
abstract	('Automatic install of dependencies via CPAN');
author		('Autrijus Tang (autrijus@autrius.org)');
version_from	('AutoInstall.pm');

requires	('Cwd');
requires	('Carp');
requires	('ExtUtils::Manifest');
requires	('ExtUtils::MakeMaker');

features(
    'CPANPLUS Support' => [
	-default	    => 0,
	'CPANPLUS'	    => '0.032',
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
