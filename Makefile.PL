#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/Makefile.PL $ $Author: autrijus $
# $Revision: #12 $ $Change: 9532 $ $DateTime: 2004/01/01 06:47:30 $

use inc::Module::Install;
use lib 'lib';

name		('ExtUtils-AutoInstall');
abstract	('Automatic install of dependencies via CPAN');
author		('Autrijus Tang <autrijus@autrius.org>');
version_from	('lib/ExtUtils/AutoInstall.pm');
license		('perl');

requires	('Cwd');
requires	('Carp');
requires	('ExtUtils::Manifest');
requires	('ExtUtils::MakeMaker');

features	(
    'CPANPLUS Support' => [
	-default	    => 0,
	'CPANPLUS'	    => '0.043',
    ],
  (eval { require version; version->VERSION >= 0.28 }) ? () : (
    'Nondecimal version number support' => [
	-default	    => 0,
	'Sort::Versions'    => '1.2'
    ],
  ),
);

auto_install();
&WriteAll( sign => 1 );
