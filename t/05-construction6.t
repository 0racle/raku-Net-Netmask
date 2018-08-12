use Test;
use lib 'lib';

#
# Copyright © 2018 Lukas Valle
# See License 
#

use Net::Netmask;

my @valid_input_ip =
        {:ip<0000:0000:0000:0000:0000:0000:0000:0001>, :desc<0:0:0:0:0:0:0:1/128>},
        {:ip<::1>,                                     :desc<0:0:0:0:0:0:0:1/128>},
        {:ip<fd9e:21a7:a92c:2323::1/128>,              :desc<fd9e:21a7:a92c:2323:0:0:0:1/128>},
        {:ip<fd9e:21a7:a92c:2323:0:0:0:1/128>,            :desc<fd9e:21a7:a92c:2323:0:0:0:1/128>},
        {:ip<fd9e:21a7:a92c:2323:0:0:0:1>,                :desc<fd9e:21a7:a92c:2323:0:0:0:1/128>};

for @valid_input_ip -> $test {
    my $net = Net::Netmask.new( $test<ip> );
    isa-ok $net, 'Net::Netmask', 'isa Net::Netmask ' ~ $test<desc>;
    is $net.Str.lc, $test<desc>;
}

my $testnet = Net::Netmask.new('fd9e:21a7:a92c:2323:0:0:0:1/37');
is $testnet.desc.lc, 'fd9e:21a7:a800:0:0:0:0:0/37';
#is $testnet.size, 137438953472;
#is $testnet.broadcast.lc, 'fd9e:21a7:afff:ffff:ffff:ffff:ffff:ffff';



        #desc    => '192.168.75.8/32',
        #base    => '192.168.75.8',#my @invalid_input_ip =
        #mask    => '255.255.255.255',#        :ip<0.0.0.>,
        #hmask   => '0.0.0.0',#        :ip<0.0.0.256>;
        #bcast   => '192.168.75.8',#
        #next    => '192.168.75.9/32',#for @invalid_input_ip -> $test {
        #prev    => '192.168.75.7/32',#    dies-ok { Net::Netmask.new( $test<ip> ) }, 'dies ' ~ $test<ip>;
        #bits    => 32,#}
        #size    => 1,#
        #int     => 0xc0a84b08,#
        #match   => [ ],#my @valid_input_ip_cidr =
        #nomatch => [ '0.0.0.0', '0.0.0.1', '10.0.0.0', '255.255.255.255' ],#        :ip<0.0.0.0/0>,
#        :ip<0.0.0.255/29>;
#
#for @valid_input_ip_cidr -> $test {
#    my $net = Net::Netmask.new( $test<ip> );
#    isa-ok $net, 'Net::Netmask', 'isa Net::Netmaks ' ~ $test<ip>;
#}
#
#
#my @invalid_input_ip_cidr =
#        :ip<0.0.0.0/33>,
#        :ip<0.0.0.256/1>;
#
#for @invalid_input_ip_cidr -> $test {
#    dies-ok { Net::Netmask.new( $test<ip> ) }, 'dies ' ~ $test<ip>;
#}
#
#
#
#my @valid_input_two_param =
#        { :address<0.0.0.0>,     :netmask<255.255.255.255> },
#        { :address<255.0.0.255>, :netmask<255.0.0.0>       };
#
#for @valid_input_two_param -> $test {
#    my $net = Net::Netmask.new( $test<address>, $test<netmask> );
#    isa-ok $net, 'Net::Netmask', 'two params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#    $net = Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> );
#    isa-ok $net, 'Net::Netmask', 'one param ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#    $net = Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> );
#    isa-ok $net, 'Net::Netmask', 'named params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#}
#
#
#my @invalid_input_two_param  =
#        { :address<0.0.>, :netmask<255.255.255.255>   },
#        { :address<255.0.0.255>, :netmask<0.255.0.0>  },
#        { :address<255.0.0.255>, :netmask<128.255.0.0>};
#
#for @invalid_input_two_param -> $test {
#    dies-ok  { Net::Netmask.new( $test<address>, $test<netmask> )}, 'dies two params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#    dies-ok  { Net::Netmask.new( $test<address> ~ ' ' ~ $test<netmask> )}, 'dies one param ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#    dies-ok  { Net::Netmask.new( :address($test<address>), :netmask($test<netmask>) )}, 'dies named params ' ~ $test<address> ~ ' ' ~ $test<netmask>;
#}
#
#
done-testing;

