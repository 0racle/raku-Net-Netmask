use v6.c;
use Test;

#
# Copyright © 2018 Joelle Maslak
# See License 
#

use Net::Netmask;

my @tests = (
    {
        input => '0.0.0.0',
        desc  => '0.0.0.0/32',
        base  => '0.0.0.0',
        mask  => '255.255.255.255',
        bits  => 32,
        size  => 1,
    },
    {
        input => '0.0.0.0/0',
        desc  => '0.0.0.0/0',
        base  => '0.0.0.0',
        mask  => '0.0.0.0',
        bits  => 0,
        size  => 2³²,
    },
    {
        input => '192.168.75.8',
        desc  => '192.168.75.8/32',
        base  => '192.168.75.8',
        mask  => '255.255.255.255',
        bits  => 32,
        size  => 1,
    },
    {
        input => '192.168.75.8/29',
        desc  => '192.168.75.8/29',
        base  => '192.168.75.8',
        mask  => '255.255.255.248',
        bits  => 29,
        size  => 8,
    },
    {
        input => '255.255.255.255/32',
        desc  => '255.255.255.255/32',
        base  => '255.255.255.255',
        mask  => '255.255.255.255',
        bits  => 32,
        size  => 1,
    },
    {
        input => '255.255.255.255',
        desc  => '255.255.255.255/32',
        base  => '255.255.255.255',
        mask  => '255.255.255.255',
        bits  => 32,
        size  => 1,
    }
);

for @tests -> $test {
    my $net = Net::Netmask.new( $test<input> );

    is ~$net, $test<desc>, "Stringification (1) of $test<input>";
    is $net.Str, $test<desc>, "Stringification (2) of $test<input>";
    is $net.desc, $test<desc>, "desc of $test<input>";
    
    is $net.base, $test<base>, "base of $test<input>";
    is $net.mask, $test<mask>, "mask of $test<input>";

    is $net.bits, $test<bits>, "bits of $test<input>";
    is $net.size, $test<size>, "size of $test<input>";

    my $net2 = Net::Netmask.new( $test<base>, $test<mask> );
    is ~$net2, ~$net, "Construction via 2 parameter new";

    $net2 = Net::Netmask.new( "$test<base> $test<mask>" );
    is ~$net2, ~$net, "Construction via 1 parameter new with netmask";

    $net2 = Net::Netmask.new( :address($test<base>) :netmask($test<mask>) );
    is ~$net2, ~$net, "Construction via 2 named parameter new";
}

done-testing;

