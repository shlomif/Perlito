
package Perlito5::Grammar::Map;

use strict;

Perlito5::Precedence::add_term( 'map'   => sub { Perlito5::Grammar::Map->term_map_or_grep( $_[0], $_[1] ) } );
Perlito5::Precedence::add_term( 'grep'  => sub { Perlito5::Grammar::Map->term_map_or_grep( $_[0], $_[1] ) } );
Perlito5::Precedence::add_term( 'sort'  => sub { Perlito5::Grammar::Map->term_sort( $_[0], $_[1] ) } );

token map_or_grep { 'map' | 'grep' };

token term_map_or_grep {
    # Note: this is map-block; map-expr is parsed as a normal subroutine
    <map_or_grep> <.Perlito5::Grammar::Space.opt_ws>
    <before '{'> <Perlito5::Expression.term_curly> 
    <Perlito5::Expression.list_parse>
    {
        $MATCH->{capture} = [ 'term',
             Perlito5::AST::Apply->new(
                code      => Perlito5::Match::flat($MATCH->{map_or_grep}),
                arguments => [
                    Perlito5::AST::Lit::Block->new( stmts => $MATCH->{'Perlito5::Expression.term_curly'}{capture}[2] ),
                    @{ Perlito5::Expression::expand_list($MATCH->{'Perlito5::Expression.list_parse'}{capture}) }
                ], 
                namespace => ''
             )
           ]
    }
};

# TODO: sort SUBNAME
# 
#     Warning: syntactical care is required when sorting the list
#     returned from a function. If you want to sort the list returned
#     by the function call "find_records(@key)", you can use:
# 
#         @contact = sort { $a cmp $b } find_records @key;
#         @contact = sort +find_records(@key);
#         @contact = sort &find_records(@key);
#         @contact = sort(find_records(@key));
# 
#     If instead you want to sort the array @key with the comparison
#     routine "find_records()" then you can use:
# 
#         @contact = sort { find_records() } @key;
#         @contact = sort find_records(@key);
#         @contact = sort(find_records @key);
#         @contact = sort(find_records (@key));

token term_sort {
    # Note: this is sort-block; sort-expr is parsed as a normal subroutine
    'sort' <.Perlito5::Grammar::Space.opt_ws>
    [
        <before '{'> <Perlito5::Expression.term_curly> 
        <Perlito5::Expression.list_parse>
        {
            $MATCH->{capture} = [ 'term',
                 Perlito5::AST::Apply->new(
                    code      => 'sort',
                    arguments => [
                        Perlito5::AST::Lit::Block->new( stmts => $MATCH->{'Perlito5::Expression.term_curly'}{capture}[2] ),
                        @{ Perlito5::Expression::expand_list($MATCH->{'Perlito5::Expression.list_parse'}{capture}) }
                    ], 
                    namespace => ''
                 )
               ]
        }
    |
        '('
        {
            # TODO:  '(' <opt_ws> SUBNAME <ws> LIST ')'
            return;
        }
    |
        {
            # TODO:  SUBNAME LIST
            return;
        }
    ]
};

1;

