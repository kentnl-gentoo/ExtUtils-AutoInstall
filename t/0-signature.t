#!/usr/bin/perl
# $File: //member/autrijus/ExtUtils-AutoInstall/t/0-signature.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 7913 $ $DateTime: 2003/09/06 14:41:10 $

use strict;
print "1..1\n";

if (!eval { require Module::Signature; 1 }) {
    print "ok 1 # skip ",
	  "Next time around, consider install Module::Signature, ",
	  "# so you can verify the integrity of this distribution.\n";
}
elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
    print "ok 1 # skip ",
	  "Cannot connect to the keyserver\n";
}
else {
    (Module::Signature::verify() == Module::Signature::SIGNATURE_OK())
	or print "not ";
    print "ok 1 # Valid signature\n";
}
