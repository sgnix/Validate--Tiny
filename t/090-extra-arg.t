#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Validate::Tiny;

{
  package Validate::Tiny::TestObj;
  
}

{
  #args is a object
  my $rules = {
      args => bless({}, 'Validate::Tiny::TestObj'),
      fields => [qw/a b/],
      checks => [ a => sub {
        my ($value, $input, $name, $args) = @_;
        cmp_ok(ref($args), 'eq', 'Validate::Tiny::TestObj', '4th param is object of type Validate::Tiny::TestObj');
        return; #Make it valid
      } ]
  };
  my $result = Validate::Tiny->new( { a=> 1 }, $rules );
  my $r2 = Validate::Tiny::validate( { a => 1 }, $rules );
}

{
  #args is a arrayref
  my $rules = {
      args => [1, 2, 3],
      fields => [qw/a b/],
      checks => [ a => sub {
        my ($value, $input, $name, $args) = @_;
        is_deeply($args, [1, 2, 3], "4th param is an arrayref");
        return; #Make it valid
      } ]
  };
  my $result = Validate::Tiny->new( { a=> 1 }, $rules );
  my $r2 = Validate::Tiny::validate( { a => 1 }, $rules );
}

{
  #args is a hashref of objects
  my $rules = {
      args => { a => 'b'},
      fields => [qw/a b/],
      checks => [ a => sub {
        my ($value, $input, $name, $args) = @_;
        ok(exists $args->{a}, "Key a exists");
        cmp_ok($args->{a}, 'eq', 'b', '4th param is hashref with key a => b');
        return; #Make it valid
      } ]
  };
  my $result = Validate::Tiny->new( { a=> 1 }, $rules );
  my $r2 = Validate::Tiny::validate( { a => 1 }, $rules );
}