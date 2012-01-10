use strict;
use warnings;

use Test::More tests => 6;
use Validate::Tiny;

# Scalar
ok Validate::Tiny::_match( 'foo', 'foo' );
ok !Validate::Tiny::_match( 'foo', 'goo' );

# Array
ok Validate::Tiny::_match( 'foo', [qw/bar foo baz/] );
ok !Validate::Tiny::_match( 'foo', [qw/bar goo baz/] );

# Regexp
ok Validate::Tiny::_match( 'FOO', qr/foo/i );
ok !Validate::Tiny::_match( 'foo', qr/bar/ );

