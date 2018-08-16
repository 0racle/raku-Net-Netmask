use Test;
use lib 'lib';

#
# Copyright © 2018 Lukas Valle
# See License 
#

use Net::Netmask;


my $testnet = Net::Netmask.new('fd9e:21a7:a92c:2323:0:0:0:1/37');
is dec2ip6(337115748440208604321572676367667953665).lc, 'fd9e:21a7:a92c:2323:0:0:0:1', 'dec2ip6';
is $testnet.desc.lc, 'fd9e:21a7:a800::/37', 'desc';
is $testnet.size, 2475880078570760549798248448, 'size';
is $testnet.bits, 37, 'bits';
is $testnet.broadcast.lc, 'fd9e:21a7:afff:ffff:ffff:ffff:ffff:ffff', 'broadcast';
is $testnet.next.desc.lc, 'fd9e:21a7:b000::/37', 'next';
is $testnet.base.lc, 'fd9e:21a7:a800::', 'base';
#todo "compress needed", 2;
#is $testnet.hostmask.lc, '::7ff:ffff:ffff:ffff:ffff:ffff', 'base';
#is $testnet.mask.lc, 'ffff:ffff:f800::', 'mask';
is $testnet.prev.desc.lc, 'fd9e:21a7:a000::/37', 'prev';
#todo "nth and emurat", 2;
#is $testnet.nth.desc.lc, '......', 'nth';
#is $testnet.enumerate.desc.lc, '......', 'nth';



done-testing;

