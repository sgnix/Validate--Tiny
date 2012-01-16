use strict;
use warnings;
use Test::More tests => 19;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };

# is_equal
$r->{checks} = [ a => is_equal('b') ];
ok validate({a => '', b => 1}, $r)->{success};
ok !validate({a => '0', b => ''}, $r)->{success};
ok validate({a => '1', b => '1'}, $r)->{success};
$r->{checks} = [ a => [is_required(), is_equal('b')] ];
ok !validate({a => '', b => ''}, $r)->{success};

# is_long_between
$r->{checks} = [ a => is_long_between(2,3) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => 'ab'}, $r)->{success};

# is_long_at_least
$r->{checks} = [ a => is_long_at_least(2) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => 'ab'}, $r)->{success};

# is_long_at_most (irrelevant)
#$r->{checks} = [ a => is_long_at_most(2) ];
#ok validate({a => ''}, $r)->{success};
#ok !validate({a => '000'}, $r)->{success};
#ok validate({a => 'ab'}, $r)->{success};

# is_a
{
    use FindBin;
    use lib "$FindBin::Bin/lib";
    use Class;

    $r->{checks} = [ a => is_a('Class') ];
    ok validate( { a => '' }, $r )->{success};
    ok !validate( { a => '0' }, $r )->{success};
    ok validate( { a => Class->new }, $r )->{success};
}

# is_like
$r->{checks} = [ a => is_like(qr/^[a-z]$/) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => 'a'}, $r)->{success};

# is_in
$r->{checks} = [ a => is_in([1,2,3]) ];
ok validate({a => ''}, $r)->{success};
ok !validate({a => '0'}, $r)->{success};
ok validate({a => '3'}, $r)->{success};


