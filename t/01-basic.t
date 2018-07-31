use v6.c;
use Test;

#
# Copyright © 2018 Joelle Maslak
# See License 
#

use Net::Netmask;

my @tests =
    {
        input   => '0.0.0.0',
        desc    => '0.0.0.0/32',
        base    => '0.0.0.0',
        mask    => '255.255.255.255',
        hmask   => '0.0.0.0',
        bcast   => '0.0.0.0',
        bits    => 32,
        size    => 1,
        int     => 0,
        match   => ( '0.0.0.0' => 0 ),
        nomatch => [ '0.0.0.1', '10.0.0.0', '255.255.255.255' ],
    },
    {
        input   => '0.0.0.0/0',
        desc    => '0.0.0.0/0',
        base    => '0.0.0.0',
        mask    => '0.0.0.0',
        hmask   => '255.255.255.255',
        bcast   => '255.255.255.255',
        bits    => 0,
        size    => 2³²,
        int     => 0,
        match   => [ '0.0.0.0' => 0, '0.0.0.1' => 1, '10.0.0.0' => 10*2²⁴, '255.255.255.255' => 2³²-1 ],
        nomatch => [ ],
    },
    {
        input   => '192.168.75.8',
        desc    => '192.168.75.8/32',
        base    => '192.168.75.8',
        mask    => '255.255.255.255',
        hmask   => '0.0.0.0',
        bcast   => '192.168.75.8',
        bits    => 32,
        size    => 1,
        int     => 0xc0a84b08,
        match   => [ ],
        nomatch => [ '0.0.0.0', '0.0.0.1', '10.0.0.0', '255.255.255.255' ],
    },
    {
        input   => '192.168.75.8/29',
        desc    => '192.168.75.8/29',
        base    => '192.168.75.8',
        mask    => '255.255.255.248',
        hmask   => '0.0.0.7',
        bcast   => '192.168.75.15',
        bits    => 29,
        size    => 8,
        int     => 0xc0a84b08,
        match   => [ '192.168.75.8' => 0, '192.168.75.10' => 2, '192.168.75.15' => 7 ],
        nomatch => [ '0.0.0.0', '0.0.0.1', '10.0.0.0', '192.168.75.16', '255.255.255.255' ],
    },
    {
        input   => '255.255.255.255/32',
        desc    => '255.255.255.255/32',
        base    => '255.255.255.255',
        mask    => '255.255.255.255',
        hmask   => '0.0.0.0',
        bcast   => '255.255.255.255',
        bits    => 32,
        size    => 1,
        int     => 0xffffffff,
        match   => [ '255.255.255.255' => 0 ],
        nomatch => [ '0.0.0.0', '0.0.0.1', '10.0.0.0', '192.168.75.16' ],
    };

for @tests -> $test {
    my $net = Net::Netmask.new( $test<input> );

    is ~$net, $test<desc>, "Stringification (1) of $test<input>";
    is $net.Str, $test<desc>, "Stringification (2) of $test<input>";
    is $net.desc, $test<desc>, "desc of $test<input>";
    
    is $net.first, $test<base>, "first of $test<input>";
    is $net.base, $test<base>, "base of $test<input>";
    is $net.mask, $test<mask>, "mask of $test<input>";

    is $net.hostmask, $test<hmask>, "hostmask of $test<input>";
    is $net.broadcast, $test<bcast>, "broadcast of $test<input>";
    is $net.last, $test<bcast>, "last of $test<input>";

    is $net.bits, $test<bits>, "bits of $test<input>";
    is $net.size, $test<size>, "size of $test<input>";

    is $net.Numeric, $test<int>, "Numeric of $test<input>";
    is $net.Int,     $test<int>, "Int of $test<input>";

    my $net2 = Net::Netmask.new( $test<base>, $test<mask> );
    is ~$net2, ~$net, "Construction $test<base> via 2 parameter new";

    $net2 = Net::Netmask.new( "$test<base> $test<mask>" );
    is ~$net2, ~$net, "Construction $test<base> via 1 parameter new with netmask";

    $net2 = Net::Netmask.new( :address($test<base>) :netmask($test<mask>) );
    is ~$net2, ~$net, "Construction $test<base> via 2 named parameter new";

    is $net.match($test<base>), 0, "Match test of $test<desc> for $test<base>";
    for @($test<match>) -> $match {
        is $net.match($match.key), $match.value, "Match test of $test<desc> for $match.key";
    }
}

my $obj = Net::Netmask.new('0.0.0.0/0');
is $obj.enumerate[1024], '0.0.4.0', '0.0.0.0/0 enumerate[1024] = 0.0.4.0';

@tests =
    {
        input    => '0.0.0.0/32',
        output24 => «0.0.0.0»,
        output28 => «0.0.0.0»,
        output32 => «0.0.0.0»,
    },
    {
        input    => '1.0.0.0/32',
        output24 => «1.0.0.0»,
        output28 => «1.0.0.0»,
        output32 => «1.0.0.0»,
    },
    {
        input    => '10.20.9.0/24',
        output24 => «10.20.9.0»,
        output28 => ( 0,16,32...240 ).map( { "10.20.9.$^a" } ),
        output32 => (^256).map( { "10.20.9.$^a" } ),
    }
;

for @tests -> $test {
    my $net = Net::Netmask.new( $test<input> );

    is $net.enumerate, $test<output32>, "$test<input> /32 Enumerations";
    is $net.enumerate :28bit, $test<output28>, "$test<input> /28 Enumerations";
    is $net.enumerate :24bit, $test<output24>, "$test<input> /24 Enumerations";

    $test<net_output32> = $test<output32>.map( { "$^a/32" } );
    $test<net_output28> = $test<output28>.map( { "$^a/28" } );
    $test<net_output24> = $test<output24>.map( { "$^a/24" } );

    is $net.enumerate :nets,         $test<net_output32>, "$test<input> /32 Net Enumerations";
    is $net.enumerate(:28bit :nets), $test<net_output28>, "$test<input> /28 Net Enumerations";
    is $net.enumerate(:24bit :nets), $test<net_output24>, "$test<input> /24 Net Enumerations";
}

done-testing;

