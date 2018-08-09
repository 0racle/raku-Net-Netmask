use v6.c;
use Test;

#
# Copyright © 2018 Lukas Valle
# See License 
#

use Net::Netmask;

my @valid_input_ip =
        :ip<0.0.0.0>,
        :ip<0.0.0.255>;

for @valid_input_ip -> $test {
    my $net = Net::Netmask.new( $test<ip> );
    isa-ok $net, 'Net::Netmask', 'isa Net::Netmaks ' ~ $test<ip>;
}


my @invalid_input_ip =
        :ip<0.0.0.>,
        :ip<0.0.0.256>;

for @invalid_input_ip -> $test {
    dies-ok { Net::Netmask.new( $test<ip> ) }, 'dies ' ~ $test<ip>;
}


my @valid_input_ip_cidr =
        :ip<0.0.0.0/0>,
        :ip<0.0.0.255/29>;

for @valid_input_ip_cidr -> $test {
    my $net = Net::Netmask.new( $test<ip> );
    isa-ok $net, 'Net::Netmask', 'isa Net::Netmaks ' ~ $test<ip>;
}


my @invalid_input_ip_cidr =
        :ip<0.0.0.0/33>,
        :ip<0.0.0.256/1>;

for @invalid_input_ip_cidr -> $test {
    dies-ok { Net::Netmask.new( $test<ip> ) }, 'dies ' ~ $test<ip>;
}



my @valid_input_two_param =
        { :address<0.0.0.0>,     :netmask<255.255.255.255> },
        { :address<255.0.0.255>, :netmask<255.0.0.0>       };

for @valid_input_two_param -> $test {
    my $net = Net::Netmask.new( $test<address>, $test<netmask> );
    isa-ok $net, 'Net::Netmask', 'two params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
    $net = Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> );
    isa-ok $net, 'Net::Netmask', 'one param ' ~ $test<address> ~ ' ' ~ $test<netmask>;
    $net = Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> );
    isa-ok $net, 'Net::Netmask', 'named params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
}


my @invalid_input_two_param  =
        { :address<0.0.>,
          :netmask<255.255.255.255>
        },
        { :address<255.0.0.255>,
          :netmask<0.255.0.0>
        };

for @invalid_input_two_param -> $test {
    #thows-like seems to confueses test output
    #throws-like {  my $net = Net::Netmask.new( $test<ip> ) }, Exception, message => 'failed to parse ' ~  $test<ip>, 'fail ' ~ $test<ip>  ;
    todo 'migrate to grammer';
    dies-ok  { Net::Netmask.new( $test<address>, $test<netmask> )}, 'dies two params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
    todo 'grammer to check netmask';
    dies-ok  { Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> )}, 'dies one param ' ~ $test<address> ~ ' ' ~ $test<netmask>;
    todo 'migrate to grammer';
    dies-ok  { Net::Netmask.new( :address($test<address>), :netmask($test<netmask>) )}, 'dies named params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
}


done-testing;

