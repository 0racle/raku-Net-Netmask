NAME
====

Net::Netmask - Parse, manipulate and lookup IPv4 network blocks

SYNOPSIS
========

```raku
use Net::Netmask;

my $net = Net::Netmask.new('192.168.75.8/29');

say $net.desc;        # 192.168.75.8/29 (same as ~$net or $net.Str)
say $net.base;        # 192.168.75.8
say $net.mask;        # 255.255.255.248

say $net.broadcast;   # 192.168.75.15
say $net.hostmask;    # 0.0.0.7

say $net.bits;        # 29
say $net.size;        # 8

if $net.match('192.168.75.10') -> $pos {
    say "$peer is in $net and is at index $pos.";
}

# Enumerate subnet
for $net.enumerate -> $ip {
    say $ip;
}

# Split subnet into smaller blocks
for $net.enumerate(:30bit :nets) -> $addr {
    say $addr;
}
```

DESCRIPTION
===========

`Net::Netmask` parses and understands IPv4 and IPv6 CIDR blocks. The interface is inspired by the Perl module of the same name.

Not all methods support IPv6 yet. The IPv6 interface is subject to change and should be considered experimental.

This module does not have full method parity with it's Perl cousin. Pull requests are welcome.

CONSTRUCTION
============

`Net::Netmask` objects are created with an IP address and mask.

Currently, the following forms are recognized

```raku
# CIDR notation (1 positional arg)
Net::Netmask.new('192.168.75.8/29');

# Address and netmask (1 positional arg)
Net::Netmask.new('192.168.75.8 255.255.255.248');

# Address and netmask (2 positional args)
Net::Netmask.new('192.168.75.8', '255.255.255.248');

# Named arguments
Net::Netmask.new( :address('192.168.75.8') :netmask('255.255.255.248') );
```

Using a 'hostmask' (aka, 'wildcard mask') in place of the netmask will also work.

If you create a `Net::Netmask` object from one of the host addresses in the subnet, it will still work

```raku
my $net = Net::Netmask.new('192.168.75.10/29');
say $net.desc;    # 192.168.75.8/29
```

IPv4 Addresses are validated against the following subset

```raku
token octet   { (\d+) <?{ $0 <= 255 }>  }
regex address { <octet> ** 4 % '.'      }
subset IPv4 of Str where /<address>/;
```

METHODS
=======

address
-------

Returns the first address of the network block, aka the network address.

Synonyms: `base`, `first`

netmask
-------

Returns the subnet mask in dotted-quad notation.

Synonyms: `mask`

hostmask
--------

Returns the inverse of the netmask, aka wildcard mask.

broadcast
---------

Returns the last address of the network block, aka the broadcast address.

Synonyms: `last`

bits
----

Returns the number of bits in the network portion of the netmask, which is the same number that appears at the end of a network written in CIDR notation.

```raku
say Net::Netmask.new('192.168.0.0', '255.255.255.0').bits;   # 24
say Net::Netmask.new('192.168.0.0', '255.255.255.252').bits; # 30
```

size
----

Returns the number of IP address in the block

```raku
say Net::Netmask.new('192.168.0.0', '255.255.255.0').size;   # 256
say Net::Netmask.new('192.168.0.0', '255.255.255.252').size; # 4
```

match
-----

```raku
method match(IPv4 $ip)
```

Given a valid IPv4 address, returns a true value if the address is contained within the subnet. That is to say, it will return the addresses index in the subnet.

```raku
my $net = Net::Netmask.new('192.168.0.0/24');
if $net.match('192.168.0.0') -> $pos {
    say "IP is at index $pos.";
}
```

In the above example, `match` returns `0 but True`, so even if you are matching on the network address (at position `0`) it still evaluates as `True`. If the address is not in the subnet, it will return `False`.

You could also build a ridumentary blacklist (or whitelist) checker out of an array of `Net::Netmask` objects.

```raku
my @blacklist = map { Net::Netmask.new($_) },
  < 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 >;

my $host = '192.168.0.15';
if ( any @blacklist».match($host) ) {
    say "$host is blacklisted";
}
```

enumerate
---------

```raku
method enumerate(Int :$bit = 32, Bool :$nets)
```

Returns a lazy list of the IP addresses in that subnet. By default, it enumerates over all the 32-bit subnets (ie. single addresses) in the subnet, but by providing an optional named `Int` argument `:$bit` , you can split the subnet into smaller blocks

```raku
my $net = Net::Netmask.new('192.168.75.8/29');

say $net.enumerate(:30bit);
# OUTPUT: (192.168.75.8 192.168.75.12)
```

Additionally, you can also pass an optional named `Bool` argument `:$nets`, which will return `Net::Netmask` objects instead of `Str`s.

```raku
my $net = Net::Netmask.new('192.168.75.8/29');

say $net.enumerate(:30bit :nets).map( *.desc );
# OUTPUT: (192.168.75.8/30 192.168.75.12/30)
```

While you can subscript into the list generated by enumerate, it is not recommended for large subnets, because it will still need to evaluate all previous entries before the subscripted one.

```raku
say "The address at index 4 is $net.enumerate[4]"
# Addresses 0..3 were still evaluated
```

Instead you are recommended to use the `nth` method.

nth
---

```raku
method nth($n, Int :$bit = 32, Int :$nets)
```

This method works similarly to `enumerate`, except it is optimised for subscripting, which is most noticeable with large ranges

```raku
my $net = Net::Netmask.new('10.0.0.0/8');

# Instant result
say "The 10000th address is " ~ $net.nth(10000);

# Takes several seconds
say "The 10000th address is " ~ $net.enumerate[10000];
```

This method will also happily takes a `Range` as it's argument, but if you want to get any trickier, you will need to provide a container to ensure it is passed as a single argument.

```raku
# Works as expected
say $net.nth(10000..10010);

# Too many arguments
say $net.nth(10000..10010, 20000);

# Works if in container
say $net.nth([10000..10010, 20000]);

# This also works
my @n = 10000..10010, 20000;
say $net.nth(@n);
```

The named arguments `:$bit` and `:$nets` work just like `enumerate`. Note that when using `:$bit`, the `$n`th index is based on how many subnets your are producing.

```raku
my $net2 = Net::Netmask.new('192.168.75.8/29');

say $net2.nth(3);
# OUTPUT: (192.168.75.11)

say $net2.nth(3, :30bit);
# FAILURE: Index out of range. Is: 3, should be in 0..1;

say $net2.nth(^2, :30bit :nets)».nth(^2);
# OUTPUT: ((192.168.75.8 192.168.75.9) (192.168.75.12 192.168.75.13))
```

next
----

```raku
method next()
```

Returns a `Net::Netmask` object of the next block with the same mask.

```raku
my $net = Net::Netmask.new('192.168.0.0/24');
my $next = $net.next;

say "$next comes after $net"; # 192.168.1.0/24 comes after 192.168.0.0/24
```

Alternatively, you can increment your `Net::Netmask` object to the next block by using the auto-increment operator

```raku
say "This block is $net"; # This block is 192.168.0.0/24
$net++;
say "Next block is $net"; # Next block is 192.168.1.0/24
```

prev
----

```raku
method prev()
```

Just like `next` but in reverse. Returns a `Net::Netmask` object of the previous block with the same mask.

```raku
my $net = Net::Netmask.new('192.168.1.0/24');
my $prev = $net.prev;

say "$prev comes before $net"; # 192.168.0.0/24 comes before 192.168.1.0/24
```

Alternatively, you can decrement your `Net::Netmask` object to the previous block by using the auto-decrement operator

```raku
say "This block is $net"; # This block is 192.168.1.0/24
$net--;
say "Next block is $net"; # Previous block is 192.168.0.0/24
```

sortkey()
---------

```raku
my @nets = Net::Netmask.new('192.168.1.0/24'),
    Net::Netmask.new('192.168.0.0/16'),
    Net::Netmask.new('192.168.0.0/24');

say @nets.sort(*.sortkey)[0];  # 192.168.0.0/16
say @nets.sort(*.sk)[0];       # 192.168.0.0/16
```

Provides a numeric value (Rat) that can be used as a sort key. Note that this value should not be directly used, as it is subject to future changes. This routine will return smaller values for smaller CIDR network addresses. I.E. the value for `10.0.0.0` will always be smaller than the value for `192.168.0.0`. Where the network address is the same, a CIDR with a shorter prefix will appear before one with a longer CIDR prefix. Thus, the `sortkey()` for `192.168.0.0/16` will be smaller than the `sortkey()` for `192.168.0.0/24`.

Synonym: `sk`

CLASS METHODS
=============

sort()
------

```raku
my @nets = Net::Netmask.new('192.168.1.0/24'),
    Net::Netmask.new('192.168.0.0/16'),
    Net::Netmask.new('192.168.0.0/24');

say Net::Netmask.sort(@nets)[0]  # 192.168.0.0/16
```

This sort method will use the internal `sortkey()` method to provide a sorted sequence of `Net::Netmask` objects. Note that you must call this only on the class (I.E. `Net::Netmask.sort(...)`) and never on an individual instance (I.E. `$net.sort(...)`. If called on an instance rather than the class, an exception will be thrown.

TYPE CONVERSIONS
================

Int()
-----

```raku
my $net = Net::Netmask.new('192.168.1.0/24');
say $net.Int;   # 3232235776
```

Returns an Int representing the integer value of the IP address (similar to `inet_atoi`).

Synonym: `Real`

Str()
-----

```raku
my $net = Net::Netmask.new('192.168.1.0/24');
say $net.Str;  # 192.168.1.0/24
```

Returns the stringification of the object.

FUNCTIONS
=========

dec2ip()
--------

    dec2ip(2130706433); #127.0.0.1

Converts decimal number to IPv4 address string.

ip2dec()
--------

    ip2dec('127.0.0.1'); #2130706433

Converts string IPv4 address to decimal number.

CONTRIBUTORS
============

Some updates have been made by Joelle Maslak <jmaslak@antelope.net>

Initial IPv6 code contributed by Lukas Vale.

BUGS, LIMITATIONS, and TODO
===========================

Yes, this module is fully functional for IPv4 but not-so-complete for IPv6. It's enough for me, but there's always room to grow. Pull requests welcome.

As mentioned in the description, this module does not have method parity with the Perl module of the same name. I didn't really look at how the other module is implemented, so there's a chance some of my methods might be horribly inefficient. Pull requests are welcome!

LICENCE
=======

    The Artistic License 2.0

See LICENSE file in the repository for the full license text.

