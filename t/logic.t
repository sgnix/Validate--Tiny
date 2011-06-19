#!/usr/bin/perl -T

use Test::More tests => 6;
use Test::Deep;
use Test::Exception;

use Validate::Tiny qw/validate :util/;

my ($input, $result, $rules);

subtest 'Sanity check' => sub {
    dies_ok( sub { validate( {}, {} ) }, "Fields must be defined" );
    dies_ok(
        sub { validate( {}, { fields => [] } ) },
        "Fields can't be an empty array "
    );
    dies_ok(
        sub { validate( {}, { fields => {} } ) },
        "Fields must be an array"
    );
    dies_ok(
        sub { validate( {}, { fields => [qw/a/], filters => [ 1, 2, 3 ] } ) },
        "Fields must have even number of elements"
    );
    dies_ok(
        sub { validate( {}, { fields => [qw/a/], checks => [ 1, 2, 3 ] } ) },
        "Checks must have even number of elements" );
    dies_ok(
        sub { validate( {}, { fields => [qw/a/], filters => { a => 1 } } ) },
        "Filters must be an arrayref" );
    dies_ok(
        sub { validate( {}, { fields => [qw/a/], checks => { a => 1 } } ) },
        "Checks must be an arrayref" );
    dies_ok(
        sub { validate( {}, { fields => [qw/a/], checks => [ a => 1 ] } ) },
        "Each check must be code or arrayref" );
    dies_ok(
        sub {
            validate( { a => 2 },
                { fields => [qw/a/], filters => [ a => 1 ] } );
        },
        "Each filter must be code or arrayref"
    );
    dies_ok(
        sub {
            validate( {}, { fields => ['a'], something => [ 1, 2, 3 ] } );
        },
        "Checks for misspelled keys"
    );
};

subtest 'Filters' => sub {
    my $ok = { success => 1, error => {}, data => { a => 'Jane Doe' } };
    $input = { a => '   Jane   Doe   ' };
    $rules = {
        fields  => [qw/a/],
        filters => [ a => [ filter('trim'), filter('strip') ] ]
    };
    cmp_deeply( validate( $input, $rules ), $ok, 'Filters 1' );

    ###

    $rules->{filters} = [ a => filter(qw/trim strip/) ];
    cmp_deeply( validate( $input, $rules ), $ok, 'Filters 2' );

    ###

    $rules->{filters} = [ a => [ filter(qw/trim strip/) ] ];
    cmp_deeply( validate( $input, $rules ), $ok, 'Filters 3' );

    ###

    $rules->{filters} = [
        a => sub {
            $_[0] =~ s/^\s+//;
            $_[0] =~ s/\s+$//;
            $_[0] =~ s/\s{2,}/ /g;
            return $_[0];
        }
    ];
    cmp_deeply( validate( $input, $rules ), $ok, 'Filters 4' );
};

subtest 'Checks' => sub {
    $rules = {
        fields => [qw/a b/],
        checks => [ [qw/a b/] => is_required() ]
    };
    cmp_deeply( validate( { a => '', b => 'something' }, $rules ),
        { success => 0, data => ignore(), error => { a => 'Required' } },
        'Check required 1'
    );

    ###

    cmp_deeply( validate( { a => 'something' }, $rules ),
        { success => 0, data => ignore(), error => { b => 'Required' } },
        'Check required 2'
    );

    ###

    cmp_deeply(
        validate( { a => 'a', b => 'b' }, $rules ),
        {
            success => 1,
            data    => { a => 'a', b => 'b' },
            error   => {}
        },
        'Check required 3'
    );

    ###

    $rules->{checks} = [a => is_equal('b')] ;
    cmp_deeply(
        validate( { a => 'a', b => 'b' }, $rules ),
        {
            success => 0,
            data => ignore(),
            error => { a => 'Invalid value' }
        },
        'Check equal 1'
    );

    ###

    $rules->{checks} = [a => is_equal('b', 'Error')] ;
    cmp_deeply(
        validate( { a => 'a', b => 'b' }, $rules ),
        {
            success => 0,
            data => ignore(),
            error => { a => 'Error' }
        },
        'Check equal 2'
    );

    ###

    cmp_deeply(
        validate( { a => 'a' }, $rules ),
        {
            success => 0,
            data => ignore(),
            error => { a => 'Error' }
        },
        'Check equal 3'
    );

    ###
    
    cmp_deeply(
        validate( { b => 'a', a => 'a' }, $rules ),
        {
            success => 1,
            data => { a => 'a', b => 'a' },
            error => {}
        },
        'Check equal 4'
    );

    ###

    cmp_deeply(
        validate( { b => 'a' }, $rules ),
        {
            success => 1,
            data => { b => 'a' },
            error => {}
        },
        'Check equal 5'
    );

    ###

    $result = validate(
        { a => 20 },
        {
            fields => [qw/a/],
            checks => [ a => sub { $_[0] < 12 ? undef : 'Error' } ]
        }
    );
    cmp_deeply(
        $result,
        {
            success => 0,
            data    => ignore(),
            error   => { a => 'Error' }
        },
        'Custom check 1'
    );

};

subtest 'Non-required params' => sub {
    $result = validate(
        { a => 1, b => 0 },
        {
            fields => [qw/a b c/],
            checks => [
                a         => is_required(),
                [qw/b c/] => sub {
                    if ( defined $_[0] ) {
                        $_[0] > 1 ? undef : 'Error';
                    }
                    else {
                        return undef;
                    }
                  }
            ]
        }
    );
    cmp_deeply(
        $result,
        {
            success => 0,
            data    => ignore(),
            error   => { b => 'Error' }
        },
        "Fail checks if provided"
    );

    $result = validate(
        { a => 1 },
        {
            fields => [qw/a b c/],
            checks => [
                a         => is_required(),
                [qw/b c/] => sub {
                    if ( defined $_[0] ) {
                        $_[0] > 1 ? undef : 'Error';
                    }
                    else {
                        return undef;
                    }
                  }
            ]
        }
    );
    cmp_deeply(
        $result,
        {
            success => 1,
            data    => { a => 1 },
            error   => {}
        },
        "Pass checks if undefined"
    );
};

subtest 'Params' => sub {
    $result = validate(
        { a => 1 },
        {
            fields => [qw/a b c/],
            checks => [ a => sub { $_[0] < 12 ? undef : 'Error' } ]
        }
    );
    cmp_deeply(
        $result,
        {
            success => 1,
            data    => { a => 1 },
            error   => {}
        },
        'Missing params not checked'
    );

    $result = validate(
        { a => '', b => '   ' },
        {
            fields  => [qw/a b c/],
            filters => [ [qw/a b c/] => filter(qw/trim strip/) ],
            checks => [ [qw/a b c/] => is_required() ]
        }
    );
    cmp_deeply(
        $result,
        {
            success => 0,
            data    => ignore(),
            error   => { a => 'Required', b => 'Required', c => 'Required' }
        },
        'Required params failed'
    );
};

subtest 'Check arrays' => sub {
    $input = { a => [ 1, 2, 3, 4 ] };
    $rules = {
        fields  => [qw/a/],
        filters => [
            a => sub {
                [ grep { $_ > 2 } @{ $_[0] } ];
              }
        ],
        checks => [
            a => sub {
                for ( @{ $_[0] } ) { return 'Error' if $_ > 5 }
                undef;
              }
        ]
    };

    $result = validate( $input, $rules );
    cmp_deeply(
        $result,
        {
            success => 1,
            data    => { a => [ 3, 4 ] },
            error   => {}
        },
        'Proper array filter and check OK'
    );

    $input = { a => [ 1, 2, 3, 4, 20, 30 ] };
    $result = validate( $input, $rules );
    cmp_deeply(
        $result,
        {
            success => 0,
            data    => ignore(),
            error   => { a => 'Error' }
        },
        'Bad array fails OK'
    );
};

