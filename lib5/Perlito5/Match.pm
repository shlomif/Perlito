# Do not edit this file - Generated by Perlito5 8.0
use v5;
use utf8;
use strict;
use warnings;
no warnings ('redefine', 'once', 'void', 'uninitialized', 'misc', 'recursion');
use Perlito5::Perl5::Runtime;
our $MATCH = Perlito5::Match->new();
{
package main;
    sub new { shift; bless { @_ }, "main" }
    use v5;
    package Perlito5::Match;
    sub new {
        my $List__ = bless \@_, "ARRAY";
        ((my  $class) = shift());
        bless((do {
    (my  $Hash_a = bless {}, 'HASH');
    (do {
        ((my  $_i) = 0);
        ((my  $List__a = bless [], 'ARRAY') = $List__);
        for ( ; (($_i < scalar( @{$List__a} )));  ) {
            ($Hash_a->{$List__a->[$_i]} = $List__a->[($_i + 1)]);
            ($_i = ($_i + 2))
        }
    });
    $Hash_a
}), $class)
    };
    sub from {
        my $List__ = bless \@_, "ARRAY";
        $List__->[0]->{'from'}
    };
    sub to {
        my $List__ = bless \@_, "ARRAY";
        $List__->[0]->{'to'}
    };
    sub str {
        my $List__ = bless \@_, "ARRAY";
        $List__->[0]->{'str'}
    };
    sub bool {
        my $List__ = bless \@_, "ARRAY";
        $List__->[0]->{'bool'}
    };
    sub capture {
        my $List__ = bless \@_, "ARRAY";
        $List__->[0]->{'capture'}
    };
    sub flat {
        my $List__ = bless \@_, "ARRAY";
        ((my  $self) = $List__->[0]);
        if (($self->{'bool'})) {
            if ((defined($self->{'capture'}))) {
                return ($self->{'capture'})
            };
            return (substr($self->{'str'}, $self->{'from'}, (($self->{'to'} - $self->{'from'}))))
        }
        else {
            return ('')
        }
    }
}

1;