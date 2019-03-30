=begin pod

=head1 NAME

Net::Netmask - Parse, manipulate and lookup IPv4 network blocks

=head1 SYNOPSIS

=begin code :lang<perl-6>

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

=end code


=head1 DESCRIPTION

C<Net::Netmask> parses and understands IPv4 and IPv6 CIDR blocks. The interface
is inspired by the Perl 5 module of the same name.

Not all methods support IPv6 yet.  The IPv6 interface is subject to change and
should be considered experimental.

This module does not have full method parity with it's Perl 5 cousin. Pull
requests are welcome.


=head1 CONSTRUCTION

C<Net::Netmask> objects are created with an IP address and mask.

Currently, the following forms are recognized

=begin code :lang<perl-6>

# CIDR notation (1 positional arg)
Net::Netmask.new('192.168.75.8/29');

# Address and netmask (1 positional arg)
Net::Netmask.new('192.168.75.8 255.255.255.248');

# Address and netmask (2 positional args)
Net::Netmask.new('192.168.75.8', '255.255.255.248');

# Named arguments
Net::Netmask.new( :address('192.168.75.8') :netmask('255.255.255.248') );

=end code

Using a 'hostmask' (aka, 'wildcard mask') in place of the netmask will also work.

If you create a C<Net::Netmask> object from one of the host addresses in the subnet, it will still work

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.75.10/29');
say $net.desc;    # 192.168.75.8/29

=end code

IPv4 Addresses are validated against the following subset

=begin code :lang<perl-6>

token octet   { (\d+) <?{ $0 <= 255 }>  }
regex address { <octet> ** 4 % '.'      }
subset IPv4 of Str where /<address>/;

=end code


=head1 METHODS

=head2 address

Returns the first address of the network block, aka the network address.

Synonyms: C<base>, C<first>

=head2 netmask

Returns the subnet mask in dotted-quad notation.

Synonyms: C<mask>

=head2 hostmask

Returns the inverse of the netmask, aka wildcard mask.

=head2 broadcast

Returns the last address of the network block, aka the broadcast address.

Synonyms: C<last>

=head2 bits

Returns the number of bits in the network portion of the netmask, which is the same number that appears at the end of a network written in CIDR notation.

=begin code :lang<perl-6>

say Net::Netmask.new('192.168.0.0', '255.255.255.0').bits;   # 24
say Net::Netmask.new('192.168.0.0', '255.255.255.252').bits; # 30

=end code

=head2 size

Returns the number of IP address in the block

=begin code :lang<perl-6>

say Net::Netmask.new('192.168.0.0', '255.255.255.0').size;   # 256
say Net::Netmask.new('192.168.0.0', '255.255.255.252').size; # 4

=end code

=head2 match

=begin code :lang<perl-6>

method match(IPv4 $ip)

=end code

Given a valid IPv4 address, returns a true value if the address is contained within the subnet. That is to say, it will return the addresses index in the subnet.

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.0.0/24');
if $net.match('192.168.0.0') -> $pos {
    say "IP is at index $pos.";
}

=end code

In the above example, C<match> returns C<0 but True>, so even if you are matching on the network address (at position C<0>) it still evaluates as C<True>. If the address is not in the subnet, it will return C<False>.

You could also build a ridumentary blacklist (or whitelist) checker out of an array of C<Net::Netmask> objects.

=begin code :lang<perl-6>

my @blacklist = map { Net::Netmask.new($_) },
  < 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 >;

my $host = '192.168.0.15';
if ( any @blacklist».match($host) ) {
    say "$host is blacklisted";
}

=end code

=head2 enumerate

=begin code :lang<perl-6>

method enumerate(Int :$bit = 32, Bool :$nets)

=end code

Returns a lazy list of the IP addresses in that subnet. By default, it enumerates over all the 32-bit subnets (ie. single addresses) in the subnet, but by providing an optional named C<Int> argument C<:$bit> , you can split the subnet into smaller blocks

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.75.8/29');

say $net.enumerate(:30bit);
# OUTPUT: (192.168.75.8 192.168.75.12)

=end code

Additionally, you can also pass an optional named C<Bool> argument C<:$nets>, which will return C<Net::Netmask> objects instead of C<Str>s.

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.75.8/29');

say $net.enumerate(:30bit :nets).map( *.desc );
# OUTPUT: (192.168.75.8/30 192.168.75.12/30)

=end code

While you can subscript into the list generated by enumerate, it is not recommended for large subnets, because it will still need to evaluate all previous entries before the subscripted one.

=begin code :lang<perl-6>

say "The address at index 4 is $net.enumerate[4]"
# Addresses 0..3 were still evaluated

=end code

Instead you are recommended to use the C<nth> method.

=head2 nth

=begin code :lang<perl-6>

method nth($n, Int :$bit = 32, Int :$nets)

=end code

This method works similarly to C<enumerate>, except it is optimised for subscripting, which is most noticeable with large ranges

=begin code :lang<perl-6>

my $net = Net::Netmask.new('10.0.0.0/8');

# Instant result
say "The 10000th address is " ~ $net.nth(10000);

# Takes several seconds
say "The 10000th address is " ~ $net.enumerate[10000];

=end code

This method will also happily takes a C<Range> as it's argument, but if you want to get any trickier, you will need to provide a container to ensure it is passed as a single argument.

=begin code :lang<perl-6>

# Works as expected
say $net.nth(10000..10010);

# Too many arguments
say $net.nth(10000..10010, 20000);

# Works if in container
say $net.nth([10000..10010, 20000]);

# This also works
my @n = 10000..10010, 20000;
say $net.nth(@n);

=end code

The named arguments C<:$bit> and C<:$nets> work just like C<enumerate>. Note that when using C<:$bit>, the C<$n>th index is based on how many subnets your are producing.

=begin code :lang<perl-6>

my $net2 = Net::Netmask.new('192.168.75.8/29');

say $net2.nth(3);
# OUTPUT: (192.168.75.11)

say $net2.nth(3, :30bit);
# FAILURE: Index out of range. Is: 3, should be in 0..1;

say $net2.nth(^2, :30bit :nets)».nth(^2);
# OUTPUT: ((192.168.75.8 192.168.75.9) (192.168.75.12 192.168.75.13))

=end code

=head2 next

=begin code :lang<perl-6>

method next()

=end code

Returns a C<Net::Netmask> object of the next block with the same mask.

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.0.0/24');
my $next = $net.next;

say "$next comes after $net"; # 192.168.1.0/24 comes after 192.168.0.0/24

=end code

Alternatively, you can increment your C<Net::Netmask> object to the next block by using the auto-increment operator

=begin code :lang<perl-6>

say "This block is $net"; # This block is 192.168.0.0/24
$net++;
say "Next block is $net"; # Next block is 192.168.1.0/24

=end code

=head2 prev

=begin code :lang<perl-6>

method prev()

=end code

Just like C<next> but in reverse. Returns a C<Net::Netmask> object of the previous block with the same mask.

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.1.0/24');
my $prev = $net.prev;

say "$prev comes before $net"; # 192.168.0.0/24 comes before 192.168.1.0/24

=end code

Alternatively, you can decrement your C<Net::Netmask> object to the previous block by using the auto-decrement operator

=begin code :lang<perl-6>

say "This block is $net"; # This block is 192.168.1.0/24
$net--;
say "Next block is $net"; # Previous block is 192.168.0.0/24

=end code

=head2 sortkey()

=begin code :lang<perl-6>

my @nets = Net::Netmask.new('192.168.1.0/24'),
    Net::Netmask.new('192.168.0.0/16'),
    Net::Netmask.new('192.168.0.0/24');

say @nets.sort(*.sortkey)[0];  # 192.168.0.0/16
say @nets.sort(*.sk)[0];       # 192.168.0.0/16

=end code

Provides a numeric value (Rat) that can be used as a sort key.  Note that this
value should not be directly used, as it is subject to future changes.  This
routine will return smaller values for smaller CIDR network addresses.  I.E.
the value for C<10.0.0.0> will always be smaller than the value
for C<192.168.0.0>.  Where the network address is the same, a CIDR with a
shorter prefix will appear before one with a longer CIDR prefix.  Thus,
the C<sortkey()> for C<192.168.0.0/16> will be smaller than the C<sortkey()>
for C<192.168.0.0/24>.

Synonym: C<sk>

=head1 CLASS METHODS

=head2 sort()

=begin code :lang<perl-6>

my @nets = Net::Netmask.new('192.168.1.0/24'),
    Net::Netmask.new('192.168.0.0/16'),
    Net::Netmask.new('192.168.0.0/24');

say Net::Netmask.sort(@nets)[0]  # 192.168.0.0/16

=end code

This sort method will use the internal C<sortkey()> method to provide a
sorted sequence of C<Net::Netmask> objects.  Note that you must call
this only on the class (I.E. C<Net::Netmask.sort(...)>) and never on
an individual instance (I.E. C<$net.sort(...)>.  If called on an instance
rather than the class, an exception will be thrown.

=head1 TYPE CONVERSIONS

=head2 Int()

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.1.0/24');
say $net.Int;   # 3232235776

=end code

Returns an Int representing the integer value of the IP address (similar
to C<inet_atoi>).

Synonym: C<Real>

=head2 Str()

=begin code :lang<perl-6>

my $net = Net::Netmask.new('192.168.1.0/24');
say $net.Str;  # 192.168.1.0/24

=end code

Returns the stringification of the object.

=head1 FUNCTIONS

=head2 dec2ip()

    dec2ip(2130706433); #127.0.0.1

Converts decimal number to IPv4 address string.

=head2 ip2dec()

    ip2dec('127.0.0.1'); #2130706433


Converts string IPv4 address to decimal number.

=head1 CONTRIBUTORS

The author is Joshua Yeshouroun

Some updates have been made by Joelle Maslak <jmaslak@antelope.net>

Initial IPv6 code contributed by Lukas Vale.

=head1 BUGS, LIMITATIONS, and TODO

Yes, this module is fully functional for IPv4 but not-so-complete for IPv6.
It's enough for me, but there's always room to grow. Pull requests welcome.

As mentioned in the description, this module does not have method parity with the Perl 5 module of the same name. I didn't really look at how the other module is implemented, so there's a chance some of my methods might be horribly inefficient. Pull requests are welcome!


=head1 LICENCE

    The Artistic License 2.0

See LICENSE file in the repository for the full license text.

=end pod

class Net::Netmask {

    has Int @.address;
    has Int @.netmask;
    has Int $!start;
    has Int $!end;

    #based on http://rosettacode.org/wiki/Parse_an_IP_Address#Perl_6
    grammar IP_Addr {
        token TOP { ^ [ <IPv4> | <IPv6> ] $ } #allow IPv6 Parsing needs more work to be done
        #token TOP { ^ <IPv4> $ }

        token IPv4 { <ipv4> [ <CIDRv4> | <ipv4mask> ]? }

        token ipv4 {
            [ <d8> +% '.' ] <?{ $<d8> == 4 }>
            { make @$<d8> }
        }

        token ipv4mask {
            \s* [ <d8> +% '.' ] <?{ $<d8> == 4 and ((@$<d8>)».fmt("%08b").join ~~ /^1*0*$/)}>
            { make @$<d8> }
        }

        token CIDRv4 {
            '/' <n5> { my $n = 2**32-1+<(32-$<n5>); make (0x18,0x10...0x0).map({ $n +> $_}) »%» 0x100 }
        }

        token IPv6 {
                 <ipv6> [ <CIDRv6> ]?
        }

        token ipv6 {
            | <h16> +% ':' <?{ $<h16> == 8 }>
            { make @$<h16>.map({.Str.parse-base(16)}) }

            | [ (<h16>) +% ':']? '::' [ (<h16>) +% ':' ]? <?{ @$0 + @$1 <= 8 }>
            { make (|@$0, |( '0' xx 8 - (@$0 + @$1)), |@$1).map({.Str.parse-base(16)}) }

            | :i['::ffff:' | '0:0:0:0:0:ffff:'] <IPv4>
            { make (|(0 xx 5), 0xff , 0xff, by8to16 @$<IPv4>) }
        }

        token CIDRv6 {
            '/' <n7> { my $n = 2**128-1+<(128-$<n7>); make (0x70,0x60...0x0).map({ $n +> $_}) »%» 0x10000 }
        }

        token d8  { (\d+) <?{ $0 < 256   }> }
        token n5  { (\d+) <?{ $0 <= 32    }> }
        token n7  { (\d+) <?{ $0 <= 128   }> }
        token h16 { (<:hexdigit> ** {1..4})  }
    }


    our subset IPv4     of Str   where { IP_Addr.subparse: $_, :rule<ipv4>     };
    our subset IPv4mask of Str   where { IP_Addr.subparse: $_, :rule<ipv4mask> };
    our subset IPv4arr  of Array where { .elems == 4 };
    our subset IPv6     of Str   where { IP_Addr.subparse: $_, :rule<ipv6>     };
    our subset IPv6arr  of Array where { .elems == 8 };
    our subset IParr    of Array where { $_ ~~ IPv4arr || $_ ~~ IPv6arr };


    multi method new(IPv4 $ip){
        my $match = IP_Addr.parse($ip)<IPv4> or die 'failed to parse ' ~ $ip.gist;
        my @netmask = 255 xx 4;
        if $match<ipv4mask> { @netmask = $match<ipv4mask>.made>>.Int }
        if $match<CIDRv4>   { @netmask = $match<CIDRv4>.made>>.Int   }
        my @address = $match<ipv4>.made>>.Int;
        self.bless :@address :@netmask;
    }

    multi method new(IPv6 $ip){
        my $match = IP_Addr.parse($ip)<IPv6> or die 'failed to parse ' ~ $ip.gist;
        my @netmask = 0xFFFF xx 8;
        if $match<CIDRv6>   { @netmask = $match<CIDRv6>.made>>.Int   }
        my @address = $match<ipv6>.made>>.Int;
        self.bless :@address :@netmask;
    }

    multi method new(IPv4 $address, IPv4mask $netmask) {
        self.bless :address(ip2arr($address)) :netmask(ipmask2arr($netmask));
    }

    multi method new(IPv4 :$address, IPv4mask :$netmask) {
        self.bless :address(ip2arr($address)) :netmask(ipmask2arr($netmask));
    }

    submethod BUILD(:@address where {$_ ~~ IParr}, :@netmask where {$_ ~~ IParr}) {
        given @address {
            when IPv4arr  {
                @!netmask = @netmask;
                $!start = ( [Z+&] (@address, @!netmask)).join('.').&ip2dec;
                @!address = ip2arr($!start.&dec2ip);
                $!end = ( [Z+^] (@!address, self.hostmask.split('.'))).join('.').&ip2dec;
            }

            when IPv6arr {
                @!netmask = @netmask;
                $!start = (( [Z+&] (@address, @!netmask)) Z+< (0x70,0x60...0)).sum;
                @!address = (0x70,0x60...0x0).map({ $!start +> $_}) »%» 0x10000;
                $!end = (( [Z+^] (@!address, (@!netmask »+^» 0xFFFF) )) Z+< (0x70,0x60...0)).sum;
            }
        }

    }

    sub ip2dec(\i) is export {
        i.split('.').flatmap({
            ($^a +< 0x18), ($^b +< 0x10), ($^c +< 0x08), $^d
        }).sum;
    }

    sub dec2ip(\d where { 0 <= $_ <= 0xffffffff or die 'not in IPv4 range 0-4294967295'} --> IPv4) is export {
        ( (d +> 0x18, d +> 0x10, d +> 0x08, d) »%» 0x100 ).join('.');
    }

    sub dec2ip6(\d where { 0 <= $_ <= (2**128-1) or die 'not in IPv6 range (128bit)'} --> IPv6) is export {
        (((0x70,0x60...0x0).map({ d +> $_}) »%» 0x10000)».base(16).join(':'));
    }

    sub by8to16     (@m) { gather for @m -> $a,$b { take ($a * 256 + $b).fmt("%04x") } }
    sub ip2arr      ($a) { IP_Addr.subparse($a, :rule<ipv4>    ).made>>.Int            }
    sub ipmask2arr  ($m) { IP_Addr.subparse($m, :rule<ipv4mask>).made>>.Int            }

    sub compress6(@ip) {
        my $matches = 0;
        my $bestspos = Nil;
        my $startpos = Nil;
        for @ip.keys -> $i {
            if @ip[$i] == 0 ff^ @ip[$i] != 0 {
                $startpos //= $i;
                #last element is zero and bestmatch
                if $i == @ip.elems-1 and @ip.elems-$startpos > $matches {
                    $matches  = @ip.elems-$startpos;
                    $bestspos = $startpos;
                }
            } else {
                if defined $startpos and $i-$startpos > $matches {
                    $matches = $i-$startpos;
                    $bestspos = $startpos;
                }
                $startpos = Nil;
            }
        }

        given $bestspos {
            when 0                       { '::' ~ @ip.[$matches .. (@ip.elems-1)]».base(16).join(':') }
            when + $matches == @ip.elems { @ip.[0..$bestspos-1]».base(16).join(':') ~ '::'}
            when $_                      { @ip.[0..$bestspos-1]».base(16).join(':') ~ '::' ~ @ip.[($bestspos+$matches)..(@ip.elems-1)]».base(16).join(':') }
            default                      { @ip».base(16).join(':') }
        }
    }


    method Str     {
        given @!address {
            when IPv4arr { "$.base/$.bits"; }
            when IPv6arr { "$.base/$.bits";}
        }
    }

    method gist    { qq[Net::Netmask.new("$.Str")]; }
    method Numeric { $!start; }
    method Int     { $!start; }
    method Real    { $!start; }
    method desc    { self.Str;  }

    method mask    {
        given @!address {
            when IPv4arr { @.netmask.join('.') }
            when IPv6arr { @!netmask.&compress6 }
        }
    }

    method hostmask {
        given @!address {
            when IPv4arr { (@!netmask »+^» 0xFF).join('.')  } #bitflip
            when IPv6arr { (@!netmask »+^» 0xFFFF).&compress6}
            #when IPv6arr { (@!netmask »+^» 0xFFFF)».base(16).join(':')}

        }
    }

    method broadcast {
        given @!address {
            when IPv4arr { $!end.&dec2ip }
            when IPv6arr { $!end.&dec2ip6}
        }
     }

    method last {
        $.broadcast;
    }

    method base {
        given @!address {
            when IPv4arr { @!address.join('.') }
            when IPv6arr { @!address.&compress6 }
        }
    }

    method first {
        $.base;
    }

    method bits {
        @!netmask.map(*.base: 2).comb('1').elems;
    }

    method size {
        $!end - $!start + 1;
    }

    method enumerate(Int :$bit, Bool :$nets) {
        given @!address {
            when IPv4arr {
                my $b = $bit // 32;
                $b > 32 and fail('Cannot split network into smaller than /32 blocks');
                my $inc = 2 ** ( 32 - $b );
                ($!start, * + $inc ... * > $!end - $inc).map(&dec2ip).map(-> $ip {
                     $nets ?? self.new( "$ip/$b" ) !! $ip
                });
            }
            when IPv6arr {
                my $b = $bit // 128;
                $b > 128 and fail('Cannot split network into smaller than /128 blocks');
                my $inc = 2 ** ( 128 - $b );
                ($!start, * + $inc ... * > $!end - $inc).map(&dec2ip6).map(-> $ip {
                    $nets ?? self.new( "$ip/$b" ) !! self.new($ip).base
                });
            }
        }
    }

    method nth($n, Int :$bit, Bool :$nets) {
        given @!address {
            when IPv4arr {
                my $b = $bit // 32;
                $b > 32 and fail('Cannot split network into smaller than /32 blocks');
                my $inc = 2 ** ( 32 - $b ) × 1;
                my @n = $n.flatmap(* × $inc);
                if ( my $i = @n.max ) >= $.size {
                    return fail(
                        "Index out of range. Is: { $i ÷ $inc }, "
                        ~ "should be in 0..{ ($.size ÷ $inc) - 1 }"
                    );
                }
                ($!start .. $!end)[@n].map(&dec2ip).map(-> $ip {
                     $nets ?? self.new( "$ip/$b" ) !! $ip
                });
            }
            when IPv6arr {
                my $b = $bit // 128;
                $b > 128 and fail('Cannot split network into smaller than /128 blocks');
                my $inc = 2 ** ( 128 - $b ) × 1;
                my @n = $n.flatmap(* × $inc);
                if ( my $i = @n.max ) >= $.size {
                    return fail(
                            "Index out of range. Is: { $i ÷ $inc }, "
                            ~ "should be in 0..{ ($.size ÷ $inc) - 1 }"
                            );
                }
                ($!start .. $!end)[@n].map(&dec2ip6).map(-> $ip {
                    $nets ?? self.new( "$ip/$b" ) !! self.new($ip).base
                });
            }
        }



    }

    method match(IPv4 $ip) {
        my $dec = self.new($ip).Int;
        $!end >= $dec >= $!start ?? ($dec - $!start) but True !! False;
    }

    method next {
        given @!address {
            when IPv4arr { self.new(($!start + $.size).&dec2ip, self.mask) }
            when IPv6arr { self.new(($!start + $.size).&dec2ip6 ~ '/' ~ self.bits) }
        }
    }

    method prev {
        given @!address {
            when IPv4arr { self.new(($!start - $.size).&dec2ip, self.mask) }
            when IPv6arr { self.new(($!start - $.size).&dec2ip6  ~ '/' ~ self.bits) }
        }
    }

    method succ {
        $.next;
    }

    method pred {
        $.prev
    }

    method sort(*@a) {
        if defined self { die "Cannot call sort() as an instance method"; }
        @a.sort( *.sortkey );
    }

    method sortkey {
        given @!address {
            when IPv4arr { $!start +  $.bits/32 }
            when IPv6arr { $!start +  $.bits/128}
        }
    }

    method sk { $.sortkey; }
}

