#!/usr/bin/perl

use Test::More;
use Validate::Tiny ':all';

if ( eval("use Test::Exception; 1;") ) {
    plan tests => 17;
}
else {
    plan skip_all => "No Test::Exception installed";
}

dies_ok( sub { validate( {}, {} ) }, "Fields must be defined" );
dies_ok(
    sub { validate( {}, { fields => [] } ) },
    "Fields can't be an empty array "
);
dies_ok( sub { validate( {}, { fields => {} } ) }, "Fields must be an array" );
dies_ok(
    sub {
        validate( {}, { fields => [qw/a/], filters => [ 1, 2, 3 ] } );
    },
    "Fields must have even number of elements"
);
dies_ok( sub { validate( {}, { fields => [qw/a/], checks => [ 1, 2, 3 ] } ) },
    "Checks must have even number of elements" );
dies_ok( sub { validate( {}, { fields => [qw/a/], filters => { a => 1 } } ) },
    "Filters must be an arrayref" );
dies_ok( sub { validate( {}, { fields => [qw/a/], checks => { a => 1 } } ) },
    "Checks must be an arrayref" );
dies_ok( sub { validate( {}, { fields => [qw/a/], checks => [ a => 1 ] } ) },
    "Each check must be code or arrayref" );
dies_ok(
    sub {
        validate( { a => 2 }, { fields => [qw/a/], filters => [ a => 1 ] } );
    },
    "Each filter must be code or arrayref"
);
dies_ok(
    sub {
        validate( {}, { fields => ['a'], something => [ 1, 2, 3 ] } );
    },
    "Checks for misspelled keys"
);
dies_ok(sub{
    my $result = Validate::Tiny->new(1,2);
}, "Wrong params to constructor");
dies_ok(sub{
    my $result = Validate::Tiny->new({});
}, "Wrong params to constructor 2");


my $input = { a => 1 };
$rules = { fields => [qw/a/] };
my $result = Validate::Tiny->new( $input, $rules );
dies_ok(sub{ $result->something }, "Wrong accessor");
dies_ok(sub{ $result->data('b') }, "Non existing field");

###

# is_like expects a regexp
dies_ok(
    sub {
        $rules = { fields => ['a'], checks => [ a => is_like('b') ] };
        validate( { a => 1 }, $rules );
    }
);

# is_in expects arrayref
dies_ok(
    sub {
        $rules = { fields => ['a'], checks => [ a => is_in('b') ] };
        validate( { a => 1 }, $rules );
    }
);

# is_required_if expects CODE or SCALAR
dies_ok(
    sub {
        $rules = {
            fields => [qw/a b/],
            checks => [ a => is_required_if( [] ) ]
        };
        validate( {a => ''}, $rules );
    },
    "is_required_if"
);

