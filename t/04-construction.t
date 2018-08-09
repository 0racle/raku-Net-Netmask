use v6.c;
use Test;

#
# Copyright © 2018 Lukas Valle
# See License 
#

use Net::Netmask;

my @invalid_input =
    { :input<0.0.0.0/33> },
    { :input<0.0.0.0 255.255.128.255> },
    { :input<0.0.0.256'> };

for @invalid_input -> $test {
    throws-like { Net::Netmask.new( $test<input> ) },    Exception, message => 'failed to parse ' ~  $test<input> ;
}


done-testing;

