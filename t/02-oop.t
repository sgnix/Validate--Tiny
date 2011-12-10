#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use Validate::Tiny;

my $rules = {
    fields => [qw/a b/],
    checks => [ a => sub { $_[0] < 5 ? undef : 'Error' } ]
};
my $result = Validate::Tiny->new( { a=> 1 }, $rules );
my $r2 = Validate::Tiny::validate( { a => 1 }, $rules );

ok( $result->success, 'success' );
is( $result->data('a'), 1, 'functional access data' );
is( $result->data->{a}, 1, 'hash access data' );
is( $result->data('b'), undef, 'return undef if field has no value 1' );
is( $result->data->{b}, undef, 'return undef if field has no value 2' );
eval { $result->data('c') };
ok($@, 'croaks if the field has not been defined');
is( $result->data->{c}, undef, 'returns undef on undefined field via hash' );

is_deeply( $result->data,    $r2->{data}, 'data match' );
$result->data->{a} = 'foo';
is_deeply( $result->data,    $r2->{data}, 'can not change data' );

is_deeply( $result->error,   $r2->{error}, 'error match' );
$result->error->{a} = 'foo';
is_deeply( $result->error,   $r2->{error}, 'can not change error' );

is_deeply( $result->success, $r2->{success}, 'success match' );
is_deeply( $result->to_hash, $r2, 'to_hash match' );

$result = Validate::Tiny->new( { a => 11 }, $rules );
$r2 = Validate::Tiny::validate( { a => 11 }, $rules );
is( $result->error('a'), 'Error', 'functional error' );
is( $result->error->{a}, 'Error', 'hash error' );
is_deeply( $result->data,    $r2->{data} );
is_deeply( $result->error,   $r2->{error} );
is_deeply( $result->success, $r2->{success} );
is_deeply( $result->to_hash, $r2 );

$rules->{checks} = [
    a => sub { $_[0] < 5 ? undef : 'ErrorA' },
    b => sub { $_[0] < 2 ? undef : 'ErrorB' }
];
$result = Validate::Tiny->new( { a => 11, b => 11 }, $rules );
my $str = $result->error_string;
like $str, qr/\[a\] ErrorA/;
like $str, qr/\[b\] ErrorB/;

$str = $result->error_string(
    single => 1
);

ok( $str eq '[a] ErrorA' || $str eq '[b] ErrorB' );

$str = $result->error_string(
    separator => 'bangladesh'
);
like $str, qr/\[a\] ErrorA/;
like $str, qr/\[b\] ErrorB/;
like $str, qr/bangladesh/;

$str = $result->error_string(
    template => '*%s*%s'
);
like $str, qr/\*a\*ErrorA/;
like $str, qr/\*b\*ErrorB/;

$str = $result->error_string(
    names => { a => 'Bar', b => 'Foo' }
);
like $str, qr/\[Bar\] ErrorA/;
like $str, qr/\[Foo\] ErrorB/;

$result = Validate::Tiny->new( { a => 11, b => 1 }, $rules );
$str = $result->error_string;
like $str, qr/\[a\] ErrorA/;
unlike $str, qr/\[b\] ErrorB/;

