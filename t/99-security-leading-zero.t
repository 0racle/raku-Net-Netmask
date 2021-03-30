use Test;
use lib 'lib';

#
# Copyright © 2021 Joelle Maslak
# See License 
#

use Net::Netmask;

# Two security fixes were added to Perl 5's Net::Netmask:
#
#   1 - "Short" CIDRs (10/8, 10.0/16, etc) were no longer accepted since
#   different software libraries interpret them differently.  One
#   library might interpret 127.1 as 127.0.0.1 (that's the standard Unix
#   interpretation) while others might interpret it as 127.1.0.0. Thus
#   this can be unsafe if two libraries/utilities/etc have different
#   interpretations.  Fortunately this was never supported by this
#   module. This test keeps it that way.

dies-ok { Net::Netmask.new("10/8"); }        # Short format should die

#   2 - "Octal" CIDRs (010.0.0.0 => 8.0.0.0). When an octal octet is
#   encountered by some Unix (and otherwise) socket libraries, it is
#   interpreted as an OCTAL number.  This module used to interpret an
#   octet with a leading zero as an DECIMAL number, while other tools
#   would interpret it as an OCTAL one.  It's safer to just not accept
#   leading zeros.

dies-ok { Net::Netmask.new("10.01.2.3"); }   # Octal format not supported (rightly)

done-testing;


