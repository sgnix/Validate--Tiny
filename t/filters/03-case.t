
use strict;
use warnings;

use Validate::Tiny ':all';
use Test::More tests => 3;

my $rules = {
    fields  => [qw/a b c/],
    filters => [ a => filter('lc'), b => filter('uc'), c => filter('ucfirst') ]
};

my $input = {
    a => 'BAR',
    b => 'foo',
    c => 'baz'
};

my $res = validate($input, $rules);
is $res->{data}->{a}, 'bar', "lc";
is $res->{data}->{b}, 'FOO', "uc";
is $res->{data}->{c}, 'Baz', "ucfirst";
