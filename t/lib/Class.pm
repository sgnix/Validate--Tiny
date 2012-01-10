package Class;

use strict;

sub new {
    my ( $c, %a ) = @_;
    bless \%a, $c;
}

1;
