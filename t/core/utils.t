#============================================================= -*-perl-*-
#
# t/core/utils.t
#
# Test the Badger::Utils module.
#
# Written by Andy Wardley <abw@wardley.org>.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;

use lib qw( t/core/lib ./lib ../lib ../../lib );
use Badger::Debug modules => 'Badger::Utils';
use Badger::Utils 'UTILS blessed xprintf reftype textlike plural permute_fragments';
use Badger::Test 
    tests => 102,
    debug => 'Badger::Utils',
    args  => \@ARGV;

is( UTILS, 'Badger::Utils', 'got UTILS defined' );
ok( blessed bless([], 'Wibble'), 'got blessed' );


#-----------------------------------------------------------------------
# test is_object()
#-----------------------------------------------------------------------

package My::Base;
use base 'Badger::Base';

package My::Sub;
use base 'My::Base';

package main;
use Badger::Utils 'is_object';

my $obj = My::Sub->new;
ok(   is_object( 'My::Sub'   => $obj ), 'object is a My::Sub' );
ok(   is_object( 'My::Base'  => $obj ), 'object is a My::Base' );
ok( ! is_object( 'My::Other' => $obj ), 'object is not My::Other' );


#-----------------------------------------------------------------------
# test params() and self_params()
#-----------------------------------------------------------------------

use Badger::Utils 'params';

my $hash = {
    a => 10,
    b => 20,
};
is( params($hash), $hash, 'params returns hash ref' );
is( params(%$hash)->{ a }, 10, 'params merged named param list' );


package Selfish;

use Badger::Class
    base    => 'Badger::Base',
    as_text => 'text',                  # for testing textlike()
    utils   => 'self_params';

sub test1 {
    my ($self, $params) = self_params(@_);
    return ($self, $params);
}

sub text {                              # for testing textlike()
    return 'Hello World';
}

package main;
my $selfish = Selfish->new();
my ($s, $p) = $selfish->test1($hash);
is( $s, $selfish, 'self_params returns self' );
is( $p, $hash, 'self_params returns params' );
($s, $p) = $selfish->test1(%$hash);
is( $s, $selfish, 'self_params returns self again' );
is( $p->{a}, 10, 'self_params returns params again' );

# test warnings generated by add number of arguments - this is invaluable
# for debugging


sub foo { bar(@_) }
sub bar { baz(@_) }
sub baz { params(@_) }

{ 
    my @warnings;
    local $Badger::Utils::WARN = sub {
        push(@warnings, join('', @_));
    };
    foo(1, 2, 3);
    is( 
        $warnings[0], 
        "Badger::Utils::params() called with an odd number of arguments: 1, 2, 3\n",
        'got odd number of arguments warning'
    );
    like( 
        $warnings[1], 
        qr/#1: Called from main::baz/,
        'got baz() in stack trace'
    );
    like( 
        $warnings[2], 
        qr/#2: Called from main::bar/,
        'got bar() in stack trace'
    );
    like( 
        $warnings[3], 
        qr/#3: Called from main::foo/,
        'got foo() in stack trace'
    );
}


#-----------------------------------------------------------------------
# test textlike
#-----------------------------------------------------------------------

ok( textlike 'hello', 'string is textlike' );
ok( textlike $selfish, 'selfish object is textlike' );
ok( ! textlike $obj, 'object is not textlike' );
ok( ! textlike [10], 'list is not textlike' );
ok( ! textlike sub { 'foo' }, 'sub is not textlike' );


#-----------------------------------------------------------------------
# test xprintf()
#-----------------------------------------------------------------------

is( xprintf('The %s sat on the %s', 'cat', 'mat'),
    'The cat sat on the mat', 'xprintf s s' );

is( xprintf('The %1$s sat on the %2$s', 'cat', 'mat'),
    'The cat sat on the mat', 'xprintf 1 2' );

is( xprintf('The %2$s sat on the %1$s', 'cat', 'mat'),
    'The mat sat on the cat', 'xprintf 2 1' );

is( xprintf('The <2> sat on the <1>', 'cat', 'mat'),
    'The mat sat on the cat', 'xprintf <2> <1>' );

is( xprintf('The <1:s> sat on the <2:s>', 'cat', 'mat'),
    'The cat sat on the mat', 'xprintf <1:s> <2:s>' );

is( xprintf('The <1:5s> sat on the <2:5s>', 'cat', 'mat'),
    'The   cat sat on the   mat', 'xprintf <1:5s> <2:5s>' );

is( xprintf('The <1:-5s> sat on the <2:-5s>', 'cat', 'mat'),
    'The cat   sat on the mat  ', 'xprintf <1:-5s> <2:-5s>' );

is( xprintf('<1> is <2:4.3f>', pi => 3.1415926),
    'pi is 3.142', 'pi is 3.142' );

is( xprintf('<1> is <2:4.3f>', e => 2.71828),
    'e is 2.718', 'pi is 2.718' );

is( xprintf("<1><2| by ?>", 'one'),
    'one', 'one' );

is( xprintf("<1><2| by ?>", 'one', 'two'),
    'one by two', 'one by two' );

is( xprintf("<1><2| by ? by ?>", 'one', 'two'),
    'one by two by two', 'one by two by two' );


#-----------------------------------------------------------------------
# test we can import utility functions from Scalar::Util, List::Util,
# List::MoreUtils and Hash::Util.
#-----------------------------------------------------------------------

use Badger::Utils 'reftype looks_like_number numlike first max lock_hash';

my $object = bless [ ], 'Badger::Test::Object';
is( reftype $object, 'ARRAY', 'reftype imported' );

ok( looks_like_number 23, 'looks_like_number imported' );
ok( numlike 42, 'numlike imported' );

my @items = (10, 22, 33, 42);
my $first = first { $_ > 25 } @items;
is( $first, 33, 'list first imported' );

my $max = max 2.718, 3.14, 1.618;
is( $max, 3.14, 'list max imported' );

my %hash = (x => 10);
lock_hash(%hash);
ok( ! eval { $hash{x} = 20 }, 'could not modify read-only hash' );
like( $@, qr/Modification of a read-only value attempted/, 'got read-only error' );


#-----------------------------------------------------------------------
# Import from Badger::Timestamp
#-----------------------------------------------------------------------

use Badger::Utils 'Timestamp Now';

my $ts = Now;
is( ref $ts, 'Badger::Timestamp', 'Now is a Badger::Timestamp' );

$ts = Timestamp('2009/05/25 11:31:00');
is( ref $ts, 'Badger::Timestamp', 'Timestamp returned a Badger::Timestamp' );
is( $ts->year, 2009, 'got timestamp year' );
is( $ts->month, 5, 'got timestamp month' );
is( $ts->day, 25, 'got timestamp day' );


#-----------------------------------------------------------------------
# Import from Badger::Logic
#-----------------------------------------------------------------------

use Badger::Utils 'Logic';

my $logic = Logic('cheese and biscuits');
ok( blessed $logic && $logic->isa('Badger::Logic'), 'Logic returned a Badger::Logic object' );


#-----------------------------------------------------------------------
# Import from Badger::Filesystem
#-----------------------------------------------------------------------

use Badger::Utils 'Bin';

my $bin = Bin;
ok( blessed $bin && $bin->isa('Badger::Filesystem::Directory'), "Bin is $bin" );



#-----------------------------------------------------------------------
# test plural()
#-----------------------------------------------------------------------

is( plural('gateway'), 'gateways', 'pluralised gateway/gateways' );
is( plural('fairy'), 'fairies', 'pluralised fairy/fairies' );


#-----------------------------------------------------------------------
# test random_name()
#-----------------------------------------------------------------------

use Badger::Utils 'random_name';

is( length random_name(), $Badger::Utils::RANDOM_NAME_LENGTH, 
    "default random_name() length is $Badger::Utils::RANDOM_NAME_LENGTH" );
is( length random_name(16), 16, 'random_name(16) length is 16');
is( length random_name(32), 32, 'random_name(16) length is 32');
is( length random_name(48), 48, 'random_name(16) length is 48');
is( length random_name(64), 64, 'random_name(16) length is 64');


#-----------------------------------------------------------------------
# test camel_case() and CamelCase
#-----------------------------------------------------------------------

use Badger::Utils 'camel_case CamelCase';

is( camel_case('hello_world'), 'HelloWorld', 
   "camel_case('hello_world') => 'HelloWorld'" 
);
is( camel_case('FOO_bar'), 'FOOBar', 
   "camel_case('FOO_bar') => 'FOOBar'"
);

is( CamelCase('hello_world'), 'HelloWorld', 
   "CamelCase('hello_world') => 'HelloWorld'" 
);



#-----------------------------------------------------------------------
# test permute_fragments()
#-----------------------------------------------------------------------

test_permute('foo', 'foo');
test_permute('Template(X)', 'Template', 'TemplateX');
test_permute('Template(X|)', 'TemplateX', 'Template');
test_permute(
    'Template(X)::(XS::TT3|TT3)::Foo', 
    'Template::XS::TT3::Foo', 
    'Template::TT3::Foo',
    'TemplateX::XS::TT3::Foo', 
    'TemplateX::TT3::Foo',
);

sub test_permute {
    my $input   = shift;
    my @outputs = permute_fragments($input);
#    print("  INPUT: $input\n");
#    print("OUTPUTS: ", join(', ', @outputs), "\n");
    
    foreach my $output (@outputs) {
        if (@_) {
            my $expect = shift;
            is( $output, $expect, "$input => $expect" );
        }
        else {
            fail("$input permuted unexpected value: $output");
        }
    }
    foreach my $expect (@_) {
        fail("$input did not permute expected value: $expect");
    }
}


#-----------------------------------------------------------------------------
# test hash_each() and list_each
#-----------------------------------------------------------------------------

my @each;

use Badger::Utils 'hash_each list_each';

hash_each(
    { a => 10, b => 20 },
    sub {
        my ($hash, $key, $value) = @_;
        push(@each, "$key:$value");
    }
);
is( join(', ', sort @each), "a:10, b:20", 'hash_each()' );

@each = ();

list_each(
    [ 30, 40, 50 ],
    sub {
        my ($list, $index, $value) = @_;
        push(@each, "$index:$value");
    }
);
is( join(', ', sort @each), "0:30, 1:40, 2:50", 'list_each()' );

#-----------------------------------------------------------------------------
# test split_to_list()
#-----------------------------------------------------------------------------

use Badger::Utils 'split_to_list';

is( 
    join(', ', @{ split_to_list('a b c') }), 
    'a, b, c', 
    'split_to_list("a b c")'
);

is( 
    join(' + ', @{ split_to_list('a, b,c') }), 
    'a + b + c', 
    'split_to_list("a, b,c")'
);

is( 
    join(', ', @{ split_to_list([qw(a b c)]) }), 
    'a, b, c', 
    'split_to_list([qw(a b c)])'
);

#-----------------------------------------------------------------------------
# test extend()
#-----------------------------------------------------------------------------

use Badger::Utils 'extend';

my $one = { a => 10 };
my $two = { b => 20 };
extend($one, $two);

is( $one->{ b }, 20, 'extend($one, $two)');

my $combo = extend(
    { },
    $one,
    $two,
    { c => 30 }
);
is( $combo->{ a }, 10, 'extend(...) a=10');
is( $combo->{ b }, 20, 'extend(...) b=20');
is( $combo->{ c }, 30, 'extend(...) c=30');

#-----------------------------------------------------------------------------
# uri methods
#-----------------------------------------------------------------------------

use Badger::Utils 'join_uri resolve_uri';

is( join_uri('foo',   'bar'), 'foo/bar', 'join_uri("foo", "bar")');
is( join_uri('foo/',  'bar'), 'foo/bar', 'join_uri("foo/", "bar")');
is( join_uri('foo',  '/bar'), 'foo/bar', 'join_uri("foo", "/bar")');
is( join_uri('foo/', '/bar'), 'foo/bar', 'join_uri("foo/", "/bar")');

is( resolve_uri('foo',  'bar'), 'foo/bar', 'resolve_uri("foo", "bar")');
is( resolve_uri('foo', '/bar'), '/bar',    'resolve_uri("foo", "/bar")');


#-----------------------------------------------------------------------------
# truelike/falselike
#-----------------------------------------------------------------------------

use Badger::Utils 'truelike falselike';

ok(   truelike(1),        '1 is truelike'            );
ok(   truelike('1'),      "'1' is truelike"          );
ok(   truelike('on'),     'on is truelike'           );
ok(   truelike('yes'),    'yes is truelike'          );
ok(   truelike('true'),   'true is truelike'         );
ok( ! truelike(undef),    'undef is not truelike'    );
ok( ! truelike(0),        '0 is not truelike'        );
ok( ! truelike('0'),      "'0' is not truelike"      );
ok( ! truelike('off'),    "off is not truelike"      );
ok( ! truelike('no'),     "'no' is not truelike"     );
ok( ! truelike('false'),  "'false' is not truelike"  );

ok(   falselike(undef),   'undef is falselike'       );
ok(   falselike(0),       '0 is falselike'           );
ok(   falselike('0'),     "'0' is falselike"         );
ok(   falselike('off'),   "off is falselike"         );
ok(   falselike('no'),    "'no' is falselike"        );
ok(   falselike('false'), "'false' is falselike"     );
ok( ! falselike(1),       '1 is not falselike'       );
ok( ! falselike('1'),     "'1' is not falselike"     );
ok( ! falselike('on'),    'on is not falselike'      );
ok( ! falselike('yes'),   'yes is not falselike'     );
ok( ! falselike('true'),  'true is not falselike'    );


__END__

# Hmmm... I didn't realise that List::MoreUtils wasn't a core Perl module.

use Badger::Utils 'any all';
    
my $any = any { $_ % 11 == 0 } @items;      # divisible by 11
ok( $any, 'any list imported' );

my $all = all { $_ % 11 == 0 } @items;      # divisible by 11
ok( ! $all, 'all list imported' );

my $true = true { $_ % 11 == 0 } @items;    # divisible by 11
is( $true, 2, 'true list imported' );


__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

