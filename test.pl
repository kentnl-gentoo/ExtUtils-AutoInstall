#!/usr/bin/perl -w
# $File: //member/autrijus/ExtUtils-AutoInstall/test.pl $ $Author: autrijus $
# $Revision: #1 $ $Change: 2104 $ $DateTime: 2001/10/17 02:49:40 $

use strict;
use Test;

BEGIN { plan tests => 1 }

ok(eval qq{use ExtUtils::AutoInstall; 1});
