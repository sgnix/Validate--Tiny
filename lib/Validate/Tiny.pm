package Validate::Tiny;

use strict;
use warnings;
use utf8;

use parent 'Exporter';

use Carp;
use List::MoreUtils 'natatime';

our @EXPORT_OK = qw/
    validate
    filter
    is_required
    is_equal
    is_long_between
    is_long_at_least
    is_long_at_most
    is_a
    is_like
    is_in
/;

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 NAME

Validate::Tiny - Minimalistic data validation

=head1 VERSION

Version 0.35

=cut

our $VERSION = '0.35';

=head1 SYNOPSIS

Filter and validate user input from forms, etc.

    use Validate::Tiny ':all';

    my $rules = {

        # List of fields to look for
        fields => [qw/name email pass pass2 gender/],

        # Filters to run on all fields
        filters => [

            # Remove spaces from all
            qr/.+/ => filter(qw/trim strip/),

            # Lowercase email
            email => filter('lc'),

            # Remove non-alphanumeric symbols from
            # both passwords
            qr/pass?/ => sub {
                $_[0] =~ s/\W/./g;
                $_[0];
            },
        ],

        # Checks to perform on all fields
        checks => [

            # All of these are required
            [qw/name email pass pass2/] => is_required(),

            # pass2 must be equal to pass
            pass2 => is_equal('pass'),

            # custom sub validates an email address
            email => sub {
                my ( $value, $params ) = @_;
                Email::Valid->address($value) ? undef : 'Invalid email';
            },

            # custom sub to validate gender
            gender => sub {
                my ( $value, $params ) = @_;
                return $value eq 'M'
                  || $value eq 'F' ? undef : 'Invalid gender';
            }

        ]
    };

    # Validate the input agains the rules
    my $result = validate( $input, $rules );

    if ( $result->{success} ) {
        my $values_hash = $result->{data};
        ...
    }
    else {
        my $errors_hash = $result->{error};
        ...
    }


Or if you prefer an OOP approach:

    use Validate::Tiny;

    my $result = Validate::Tiny->new( $input, $rules );
    if ( $result->success ) {
        my $values_hash = $result->data;
        my $name        = $result->data('name');
        my $email       = $result->data('email');
        ...;
    }
    else {
        my $errors_hash = $result->error;
        my $name_error  = $result->error('name');
        my $email_error = $result->error('email');
    }

=head1 DESCRIPTION

This module provides a simple, light and minimalistic way of validating user
input. Except perl core modules and some test modules it has no other
dependencies, which is why it does not implement any complicated checks and
filters such as email and credit card matching. The basic idea of this
module is to provide the validation functionality, and leave it up to the
user to write their own data filters and checks. If you need a complete
data validation solution that comes with many ready features, I recommend
you to take a look at L<Data::FormValidator>. If your validation logic is
not too complicated or your form is relatively short, this module is a
decent candidate for your project.

=head1 LOGIC

The basic principle of data/form validation is that any user input must be
sanitized and checked for errors before used in the logic of the program.
Validate::Tiny breaks this process in three steps:

=over

=item 1

Specify the fields you want to work with via L</fields>.
All others will be disregarded.

=item 2

Filter the fields' values using L</filters>. A filter
can be as simple as changing to lower case or removing excess white space,
or very complicated such as parsing and removing HTML tags.

=item 3

Perform a series of L</checks> on the filtered values, to make sure
they match the requirements. Again, the checks can be very simple as in
checking if the value was defined, or very complicated as in checking if
the value is a valid credit card number.

=back

The validation returns a hash ref which contains C<success> => 1|0,
C<data> and C<error> hashes. If success is 1, C<data> will contain the
filtered values, otherwise C<error> will contain the error messages for
each field.

=head1 EXPORT

This module does not automatically export anything. You can optionally
request any of the below subroutines or use ':all' to export all.

=head1 PROCEDURAL INTERFACE

=head2 validate

    use Validate::Tiny qw/validate/;

    my $result = validate( \%input, \%rules );

Validates user input against a set of rules. The input is expected to be
a reference to a hash.

=head3 %rules

    my %rules = (
        fields  => \@field_names,
        filters => \@filters_array,
        checks  => \@checks_array
    );

C<rules> is a hash containing references to the following three
arrays: L</fields>, L</filters> and L</checks>.

=head4 fields

An array containing the names of the fields that must be filtered,
checked and returned. All others will be disregarded.

    my @field_names = qw/username email password password2/;

=head4 filters

An array containing name matches and filter subs. The array must have
an even number of elements. Each I<odd> element is a field name match and
each I<even> element is a reference to a filter subroutine or a chain of
filter subroutines. A filter subroutine takes one parameter - the value
to be filtered, and returns the modified value.

    my @filters_array = (
        email => sub { return lc $_[0] },    # Lowercase the email
        password =>
          sub { $_[0] =~ s/\s//g; $_[0] }    # Remove spaces from password
    );

The field name is matched with the perl smart match operator, so you could
have a regular expression or a reference to an array to match several
fields:

    my @filters_array = (
        qr/.+/ => sub { lc $_[0] },    # Lowercase ALL

        [qw/password password2/] => sub {    # Remove spaces from both
            $_[0] =~ s/\s//g;                # password and password2
            $_[0];
        }
    );

Instead of a single filter subroutine, you can pass an array of subroutines
to provide a chain of filters:

    my @filters_array = (
        qr/.+/ => [ sub { lc $_[0] }, sub { ucfirst $_[0] } ]
    );

The above example will first lowercase the value then uppercase its first
letter.

Some simple text filters are provided by the L</filter()> subroutine.

    use Validate::Tiny qw/validate :util/;

    my @filters_array = (
        name => filter(qw/strip trim lc/)
    );

=head4 checks

An array ref containing name matches and check subs. The array must have
an even number of elements. Each I<odd> element is a field name match and
each I<even> element is a reference to a check subroutine or a chain of
check subroutines.

A check subroutine takes two parameters - the value to be checked and a
reference to the filtered input hash.

A check subroutine must return undef if the check passes or a string with
an error message if the check fails.

B<Example:>

    # Make sure the password is good
    sub is_good_password {
        my ( $value, $params ) = @_;

        if ( !defined $value or $value eq '' ) {
            return undef;
        }

        if ( length($value) < 6 ) {
            return "The password is too short";
        }

        if ( length($value) > 40 ) {
            return "The password is too long";
        }

        if ( $value eq $params->{username} ) {
            return "Your password can not be the same as your username";
        }

        # At this point we're happy with the password
        return undef;
    }

    my $rules = {
        fields => [qw/username password/],
        checks => [
            password => \&is_good_password
        ]
    };

It may be a bit counter-intuitive for some people to return undef when the
check passes and a string when it fails. If you have a huge problem with
this concept, then this module may not be right for you.

B<Important!> Notice that in the beginning of C<is_good_password> we check
if C<$value> is defined and return undef if it is not. This is because it
is not the job of C<is_good_password> to check if C<password> is required.
Its job is to determine if the password is good. Consider the following
example:

    # Password is required and it must pass the check for good password
    #
    my $rules = {
        fields => [qw/username password/],
        checks => [
            password => [ is_required(), \&is_good_password ]
        ]
    };

and this one too:

    # Password is not required, but if it's provided then
    # it must pass the is_good_password constraint.
    #
    my $rules = {
        fields => [qw/username password/],
        checks => [
            username => is_required(),
            password => \&is_good_password
        ]
    };

The above examples show how we make sure that C<password> is defined
and not empty before we check if it is a good password.
Of course we can check if C<password> is defined inside C<is_good_password>,
but it would be redundant. Also, this approach will fail if C<password> is
not required, but must pass the rules for a good password if provided.

=head4 Chaining

The above example also shows that chaining check subroutines
is available in the same fashion as chaining filter subroutines.
The difference between chaining filters and chaining checks is that
a chain of filters will always run B<all> filters, and a chain of checks
will exit after the first failed check and return its error message.
This way the C<$result-E<gt>{error}> hash always has a single error message
per field.

=head4 Using closures

When writing reusable check subroutines, sometimes you will want to
be able to pass arguments. Returning closures (anonymous subs) is the
recommended approach:

    sub is_long_between {
        my ( $min, $max ) = @_;
        return sub {
            my $value = shift;
            return length($value) >= $min && length($value) <= $max
              ? undef
              : "Must be between $min and $max symbols";
        };
    }

    my $rules = {
        fields => qw/password/,
        checks => [
            password => is_long_between( 6, 40 )
        ]
    };


=head3 Return value

C<validate> returns a hash ref with three elements:

    my $result = validate(\%input, \%rules);

    # Now $result looks like this
    $result = {
        success => 1,       # or 0 if checks didn't pass
        data    => \%data,
        error   => \%error
    };

If C<success> is 1 all of the filtered input will be in C<%data>,
otherwise the error messages will be stored in C<%error>. If C<success>
is 0, C<%data> may or may not contain values, but its use is not
recommended.

=cut

sub validate {
    my ( $input, $rules ) = @_;
    my $error = {};

    # Sanity check
    #
    if ( !defined $rules->{fields} || !@{ $rules->{fields} } ) {
        die 'You must define some fields';
    }

    for (qw/filters checks/) {
        next unless exists $rules->{$_};
        if ( ref( $rules->{$_} ) ne 'ARRAY' || @{ $rules->{$_} } % 2 ) {
            die "$_ must be an array with an even number of elements";
        }
    }

    for ( keys %$rules ) {
        if ( $_ ne 'fields' && $_ ne 'filters' && $_ ne 'checks' ) {
            die "Unknown key $_";
        }
    }

    my $param = {};
    my @fields = @{ $rules->{fields} };

    # Add existing, filtered input to $param
    #
    for my $key ( @fields ) {
        if ( defined $input->{$key} ) {
            $param->{$key} = _process( $rules->{filters}, $input, $key );
        }
    }

    # Process all checks for $param
    #
    for my $key ( @fields ) {
        my $err = _process( $rules->{checks}, $param, $key, 1 );
        $error->{$key} ||= $err if $err;
    }

    return {
        success => keys %$error ? 0 : 1,
        error   => $error,
        data    => $param
    };

}

sub _run_code {
    my ( $code, $value, $param ) = @_;
    my $result = $value;
    if ( ref $code eq 'CODE' ) {
        $result = $code->( $value, $param );
        $value = $result unless defined $param;
    }
    elsif ( ref $code eq 'ARRAY' ) {
        for (@$code) {
            $result = _run_code( $_, $value, $param );
            if ( defined $param ) {
                last if $result;
            }
            else {
                $value = $result;
            }
        }
    }
    else {
        die 'Filters and checks must be either sub{} or []';
    }

    return $result;
}

sub _process {
    my ( $pairs, $param, $key, $check ) = @_;
    my $value = $param->{$key};
    my $iterator = natatime(2, @$pairs);
    while ( my ( $match, $code ) = $iterator->() ) {
        if ( _match($key, $match) ) {
            my $temp = _run_code( $code, $value, $check ? $param : undef );
            if ( $check ) {
                return $temp if $temp
            }
            else {
                $value = $temp;
            }
        }
    }
    return $check ? undef : $value;
}

sub _match {
    my ( $a, $b ) = @_;
    if ( !ref($b) ) {
        return $a eq $b;
    }
    elsif ( ref($b) eq 'ARRAY' ) {
        return grep { $a eq $_ } @$b;
    }
    elsif ( ref($b) eq 'Regexp' ) {
        return $a =~ $b;
    }
    else {
        return 0;
    }
}

=head2 filter

    filter( $name1, $name2, ... );

Provides a shortcut to some basic text filters. In reality, it returns
a list of anonymous subs, so the following:

    my $rules = {
        filters => [
            email => filter('lc', 'ucfirst')
        ]
    };

is equivalent to this:

    my $rules = {
        filters => [
            email => [ sub{ lc $_[0] }, sub{ ucfirst $_[0] } ]
        ]
    };

It provides a shortcut for the following filters:

=head3 trim

Removes leading and trailing white space.

=head3 strip

Shrinks two or more white spaces to one.

=head3 lc

Lower case.

=head3 uc

Upper case.

=head3 ucfirst

Upper case first letter

=cut

sub filter {
    my $FILTERS = {
        trim => sub { $_[0] =~ s/^\s+//; $_[0] =~ s/\s+$//; $_[0] },
        strip => sub { $_[0] =~ s/\s{2,}/ /g; $_[0] },
        lc    => sub { lc $_[0] },
        uc    => sub { uc $_[0] },
        ucfirst => sub { ucfirst $_[0] },
    };
    my @result = ();
    for (@_) {
        if ( ref $FILTERS->{$_} eq 'CODE' ) {
            push @result, $FILTERS->{$_};
        }
        else {
            die "Invalid filter: $_";
        }
    }
    return \@result;
}

=head2 is_required

    is_required( $opt_error_msg );

C<is_required> provides a shortcut to an anonymous subroutine that checks
if the matched field is defined and it is not an empty string. Optionally,
you can provide a custom error message to be returned.

=cut

sub is_required {
    my $err_msg = shift || 'Required';
    return sub { defined $_[0] && $_[0] ne '' ? undef : $err_msg  }
}

=head2 is_equal

    is_equal( $other_field_name, $opt_error_msg )

C<is_equal> checks if the value of the matched field is the same as the
value of another field within the input hash. Example:

    my $rules = {
        checks => [
            password2 => is_equal("password", "Passwords don't match")
        ]
    };

=cut

sub is_equal {
    my ( $other, $err_msg ) = @_;
    $err_msg ||= 'Invalid value';
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        return defined $_[1]->{$other} && $_[0] eq $_[1]->{$other}
          ? undef
          : $err_msg;
    };
}


=head2 is_long_between

    my $rules = {
        checks => [
            username => is_long_between( 6, 25, 'Bad username' )
        ]
    };

Checks if the length of the value is >= C<$min> and <= C<$max>. Optionally you
can provide a custom error message. The default is I<Invalid value>.

=cut

sub is_long_between {
    my ( $min, $max, $err_msg ) = @_;
    $err_msg ||= "Must be between $min and $max symbols";
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        length( $_[0] ) >= $min && length( $_[0] ) <= $max
          ? undef
          : $err_msg;
    };
}

=head2 is_long_at_least

    my $rules = {
        checks => [
            zip_code => is_long_at_least( 5, 'Bad zip code' )
        ]
    };

Checks if the length of the value is >= C<$length>. Optionally you can
provide a custom error message. The default is I<Must be at least %i symbols>.

=cut

sub is_long_at_least {
    my ( $length, $err_msg ) = @_;
    $err_msg ||= "Must be at least $length symbols";
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        length( $_[0] ) >= $length ? undef : $err_msg;
    };
}

=head2 is_long_at_most

    my $rules = {
        checks => [
            city_name => is_long_at_most( 40, 'City name is too long' )
        ]
    };

Checks if the length of the value is <= C<$length>. Optionally you can
provide a custom error message. The default is
I<Must be at the most %i symbols>.

=cut

sub is_long_at_most {
    my ( $length, $err_msg ) = @_;
    $err_msg ||= "Must be at the most $length symbols";
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        length( $_[0] ) <= $length ? undef : $err_msg;
    };
}

=head2 is_a

    use DateTime::Format::Natural;
    use Try::Tiny;

    my $parser = DateTime::Format::Natural->new;

    my $rules = {
        fields  => ['date'],

        filters => [
            date => sub {
                try {
                    $parser->parse_datetime( $_[0] );
                }
                catch {
                    $_[0]
                }
            }
        ],

        checks => [
            date => is_a("DateTime", "Ivalid date")
        ]
    };

Checks if the value is an instance of a class. This can be particularly useful,
when you need to parse dates or other user input that needs to get converted to
an object. Since the filters get executed before checks, you can use them to
instantiate the data, then use C<is_a> to check if you got a successful object.

=cut

sub is_a {
    my ( $class, $err_msg ) = @_;
    $err_msg ||= "Invalid value";
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        ref($_[0]) eq $class ? undef : $err_msg;
    }
}

=head2 is_like

    my $rules = {
        checks => [
            username => is_like( qr/^[a-z0-9_]{6,20}$/, "Bad username" )
        ]
    };

Checks if the value matches a regular expression. Optionally you can provide a
custom error message.

=cut

sub is_like {
    my ( $regexp, $err_msg ) = @_;
    $err_msg ||= "Invalid value";
    croak 'Regexp expected' unless ref($regexp) eq 'Regexp';
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        $_[0] =~ $regexp ? undef : $err_msg;
      }
}

=head2 is_in

    my @cities = qw/Alchevsk Kiev Odessa/;
    my $rules = {
        checks => [
            city => is_in( \@cities, "We only deliver to " . join(',', @cities))
        ]
    };

Checks if the value matches a set of values. Optionally you can provide a
custom error message.

=cut

sub is_in {
    my ( $arrayref, $err_msg ) = @_;
    $err_msg ||= "Invalid value";
    croak 'ArrayRef expected' unless ref($arrayref) eq 'ARRAY';
    return sub {
        return undef if !defined($_[0]) || $_[0] eq '';
        _match( $_[0], $arrayref ) ? undef : $err_msg;
      }
}

=head1 OBJECT INTERFACE

=head2 new

Validates the input against the rules and returns a class instance.

    use Validate::Tiny;

    my $result = Validate::Tiny->new( $input, $rules );
    if ( $result->success ) {

        # Do something with the data
        $result->data->{name};
        $result->data('name');
    }
    else {

        # Do something with the errors
        $result->error->{name};
        $result->error('name');
    }

=head2 success

Returns a true value if the input passed all the rules.

=head2 data

Returns a hash reference to all filtered fields. If called with a parameter,
it will return the value of that field or croak if there is no such field defined
in the fields array.

    my $all_fields = $result->data;
    my $email      = $result->data('email');

=head2 error

Returns a hash reference to all error messages. If called with a parameter,
it will return the error message of that field, or croak if there is no such
field.

    my $errors = $result->error;
    my $email = $result->error('email');

=head2 error_string

Returns a string with all errors. Sometimes you may want to display all errors
together in a string. This function makes that easy.

    my $str = $result->error_string;    # return a string with all errors
    my $str = $result->error_string(
        template  => '%s is %s',
        separator => '<br>',
        names     => {
            f_name => 'First name',
            l_name => 'Last name'
        }
    );

    # An example output for the above would be:
    # "First name is required<br>Last name is required"

C<error_string> takes the following optional parameters:

=head3 template

A string for the C<sprintf> function. It has to have two %s's in it:
one for the field name and one for the error message.

    my $str = $result->error_string(
        template => '(%s)%s'
    );

    # Result: "(field_name):Error message"

The default value is C<[%s] %s>.

=head3 separator

A character or a string which will be used to join all error messages.
The default value is C<";">.

=head3 names

A HASH reference, which contains field_name => "Field description"
values, so instead of C<field_name> your users will see a meaningful description
for the field.

    my $str = $result->error_string(
        template => '%s %s',
        names => {
            pass  => 'Chosen password',
            pass2 => 'Password verification'
        }
    );

    # Result: "Password verification does not match."

If a field description is not defined then the field name will be used.
The default value for C<names> is an empty hash.

=head3 single

If this is non-zero, the result will contain the error message only for B<one> of the fields.
This can be useful when you want to display a single error at a time. The value of
C<separator> in this case is disregarded.
Default value C<0>.

=head2 to_hash

Return a result hash, much like using the procedural interface. See the output
of L</validate> for more information.

=cut

sub new {
    my ( $class, $input, $rules ) = @_;
    if ( ref $input ne 'HASH' || ref $rules ne 'HASH' ) {
        confess("Parameters and rules HASH refs are needed");
    }
    bless {
        input  => $input,
        rules  => $rules,
        result => validate( $input, $rules )
    }, $class;
}

sub error_string {
    my ( $self, %args ) = @_;
    return "" if $self->success;

    $args{separator} = defined $args{separator} ? $args{separator} : ';';
    $args{names} = defined $args{names} ? $args{names} : {};
    $args{template} = defined $args{template} ? $args{template} : '[%s] %s';

    if ( ref($args{names}) ne 'HASH' ) {
        croak("names must be a reference to a HASH");
    }

    my @errors = map {
        sprintf( $args{template}, ($args{names}->{$_} || $_), $self->error($_) )
    } keys %{$self->error};

    return $args{single}
        ? shift @errors
        : join( $args{separator}, @errors );
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $sub = $AUTOLOAD =~ /::(\w+)$/ ? $1 : undef;
    if ( $sub eq 'params' || $sub eq 'rules' ) {
        return $self->{$sub};
    }
    elsif ( $sub eq 'data' || $sub eq 'error' ) {
        if ( my $field = shift ) {
            return _match($field, $self->{rules}->{fields})
                ? $self->{result}->{$sub}->{ $field }
                : croak("Undefined field $sub($field)");
        }
        else {
            return {%{$self->{result}->{$sub}}};
        }
    }
    elsif ( $sub eq 'success' ) {
        return $self->{result}->{success}
    }
    elsif ( $sub eq 'to_hash' ) {
        return {%{$self->{result}}}
    }
    else {
        confess "Undefined method $AUTOLOAD";
    }
}

sub DESTROY {}

=head1 SEE ALSO

L<Data::FormValidator>, L<Validation::Class>

=head1 AUTHOR

minimalist, C<< <minimalist at lavabit.com> >>

=head1 BUGS

Bug reports and patches are welcome. Reports which include a failing
Test::More style test are helpful and will receive priority.

You may also fork the module on Github:
https://github.com/naturalist/Validate--Tiny

=head1 LICENSE AND COPYRIGHT

Copyright 2011 minimalist.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

1; # End of Validate::Tiny
