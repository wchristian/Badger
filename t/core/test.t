#============================================================= -*-perl-*-
#
# t/core/test.t
#
# Test the Badger::Test module.
#
# Copyright (C) 2006-2008 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;

use lib qw( core/lib t/core/lib ./lib ../lib ../../lib );
use Badger::Test 
    debug => 'Badger::Class',
    args  => \@ARGV;

plan(6);
pass('Badgers are cool');
ok( 1, 'Ferrets are ok, but not as cool as badgers' );
is( 'badger', 'badger', 'Badger is' );
isnt( 'badger', 'ferret', "Ferret isn't");
like( 'Badger', qr/badger/i, 'Badger Badger Badger' );
unlike( 'Mushroom', qr/badger/i, 'Mushroom!' );

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
