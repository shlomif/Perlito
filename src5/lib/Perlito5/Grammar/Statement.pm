
package Perlito5::Grammar::Statement;


my @Statement_chars;
my %Statement;

sub add_statement {
    my $name = shift;
    my $param = shift;
    $Statement{$name} = $param;
    unshift @Statement_chars, scalar(@Statement_chars) + 1
        while @Statement_chars < length($name);
}

# --- TODO - move this to its own module
Perlito5::Grammar::Statement::add_statement( '...'      => sub { Perlito5::Grammar::Statement->stmt_yadayada( $_[0], $_[1] ) } );
Perlito5::Grammar::Statement::add_statement( 'package'  => sub { Perlito5::Grammar::Statement->stmt_package( $_[0], $_[1] ) } );
Perlito5::Grammar::Statement::add_statement( 'format'   => sub { Perlito5::Grammar::Statement->stmt_format( $_[0], $_[1] ) } );

token stmt_yadayada {
    '...' 
    {
        $MATCH->{capture} = Perlito5::AST::Apply->new(
            code      => 'die',
            namespace => '',
            arguments => [ Perlito5::AST::Val::Buf->new( buf => 'Unimplemented' ) ],
        );
    }
};

token stmt_format {
    'format' <.Perlito5::Grammar::Space.ws> 
    [ <Perlito5::Grammar.full_ident>
    | { $MATCH->{'Perlito5::Grammar.full_ident'} = 'STDOUT' }
    ]
    {
        # inject a here-doc request - see Perlito5::Grammar::String
        my $placeholder = Perlito5::AST::Apply->new(
            code      => 'list:<.>',
            namespace => '',
            arguments => [
                # XXX - this comment was originally on Perlito5::Grammar::String
                # XXX - test 12 t/base/lex.t fails if we don't use this "double-pointer"   '
                Perlito5::AST::Apply->new(
                    code      => 'list:<.>',
                    namespace => '',
                    arguments => []
                  )
            ]
        );
        push @Perlito5::Grammar::String::Here_doc, [
            'single_quote',
            $placeholder->{arguments}[0]{arguments},
            '.',  # delimiter
        ];
        $MATCH->{capture} =
            Perlito5::AST::Apply->new(
                code      => 'p5:format',
                namespace => '',
                arguments => [
                    Perlito5::Match::flat($MATCH->{'Perlito5::Grammar.full_ident'}),
                    $placeholder,
                ]
            );
    }
    <.Perlito5::Grammar::Space.opt_ws>
    '=' 
    # TODO - make sure there are only spaces or comments until the end of the line
    <.Perlito5::Grammar::Space.ws>  # this will read the 'here-doc' we are expecting
};

token stmt_package {
    'package' <.Perlito5::Grammar::Space.ws> <Perlito5::Grammar.full_ident>
    [
        # package X { block }
        <.Perlito5::Grammar::Space.opt_ws>
        {
            # set the package name before parsing the block
            my $name = Perlito5::Match::flat($MATCH->{"Perlito5::Grammar.full_ident"});
            $Perlito5::PACKAGES->{$name} = 1;
            $Perlito5::PKG_NAME = $name;
        }
        <Perlito5::Grammar::Expression.term_curly> 
        {
            $MATCH->{capture} = 
                Perlito5::AST::Lit::Block->new(
                    stmts => [
                        Perlito5::AST::Apply->new(
                            code      => 'package',
                            arguments => [], 
                            namespace => Perlito5::Match::flat($MATCH->{"Perlito5::Grammar.full_ident"}),
                        ),
                        @{ $MATCH->{'Perlito5::Grammar::Expression.term_curly'}{capture}[2] }
                    ]
                );
        }
    |
        # old syntax - set the package name in the same lexical context
        {
            my $name = Perlito5::Match::flat($MATCH->{"Perlito5::Grammar.full_ident"});
            $Perlito5::PACKAGES->{$name} = 1;
            $Perlito5::PKG_NAME = $name;
            $MATCH->{capture} = 
                 Perlito5::AST::Apply->new(
                    code      => 'package',
                    arguments => [], 
                    namespace => $name
                 );
        }
    ]
};


sub exp_stmt {
    my $self = $_[0];
    my $str = $_[1];
    my $pos = $_[2];
    for my $len ( @Statement_chars ) {
        my $term = substr($str, $pos, $len);
        if (exists($Statement{$term})) {
            my $m = $Statement{$term}->($str, $pos);
            return $m if $m;
        }
    }
    return 0;
}


my @Modifier_chars = (7, 6, 5, 4, 3, 2);
my %Modifier = (
    'if'     => 1, 
    'unless' => 1,  
    'when'   => 1, 
    'for'    => 1, 
    'foreach'=> 1, 
    'while'  => 1, 
    'given'  => 1,
);

sub statement_modifier {
    my $self = $_[0];
    my $str = $_[1];
    my $pos = $_[2];
    my $expression = $_[3]; 
    for my $len ( @Modifier_chars ) {
        my $term = substr($str, $pos, $len);
        if (exists($Modifier{$term})) {
            my $m = $self->modifier($str, $pos + $len, $term, $expression);
            return $m if $m;
        }
    }
    return 0;
}

sub modifier {
    my $self = $_[0];
    my $str = $_[1];
    my $pos = $_[2];
    my $modifier = $_[3];
    my $expression = $_[4]; 

    my $modifier_exp = Perlito5::Grammar::Expression->exp_parse($str, $pos);
    # say "# statement modifier [", Perlito5::Match::flat($modifier), "] exp: ", $modifier_exp->perl;
    if (!$modifier_exp) {
        die "Expected expression after '", Perlito5::Match::flat($modifier), "'";
    }
    # TODO - require a statement terminator
    # say "# statement_parse modifier result: ", $modifier_exp->perl;

    if ($modifier eq 'if') {
        return {
            'str' => $str, 'from' => $pos, 'to' => $modifier_exp->{to},
            capture => Perlito5::AST::If->new(
                cond      => Perlito5::Match::flat($modifier_exp),
                body      => $expression,
            ),
        };
    }
    if ($modifier eq 'unless') {
        return {
            'str' => $str, 'from' => $pos, 'to' => $modifier_exp->{to},
            capture => Perlito5::AST::If->new(
                cond      => Perlito5::Match::flat($modifier_exp),
                otherwise => $expression, 
            ),
        };
    }
    if ($modifier eq 'when') {
        return {
            'str' => $str, 'from' => $pos, 'to' => $modifier_exp->{to},
            capture => Perlito5::AST::When->new(
                cond      => Perlito5::Match::flat($modifier_exp),
                body      => $expression,
            ),
        };
    }
    if ($modifier eq 'while') {
        return {
            'str' => $str, 'from' => $pos, 'to' => $modifier_exp->{to},
            capture => Perlito5::AST::While->new(
                cond     => Perlito5::Match::flat($modifier_exp),
                body     => $expression,
            ) 
        };
    }
    if  (  $modifier eq 'for'
        || $modifier eq 'foreach'
        ) 
    {
        return {
            'str' => $str, 'from' => $pos, 'to' => $modifier_exp->{to},
            capture => Perlito5::AST::For->new(
                cond     => Perlito5::Match::flat($modifier_exp),
                body     => $expression,
            ) 
        };
    }
    die "Unexpected statement modifier '$modifier'";
}


sub statement_parse {
    my $self = $_[0];
    my $str = $_[1];
    my $pos = $_[2];
    # say "# statement_parse input: ",$str," at ",$pos;

    # the rule for subroutines seems to be: 
    # named subs are statements,
    # anonymous subs are plain terms.

    my $res = $self->exp_stmt($str, $pos);
    if ($res) {
        # say "# statement result: ", $res->perl;
        return $res;
    }
    $res = Perlito5::Grammar::Expression->exp_parse($str, $pos);
    if (!$res) {
        # say "# not a statement or expression";
        return;
    }

    # did we just see a label?
    if (  substr($str, $res->{to}, 1) eq ':'
       && $res->{capture}->isa('Perlito5::AST::Apply')
       && $res->{capture}{bareword}
       )
    {
        my $label = $res->{capture}{code};
        # say "label $label";
        my $ws   = Perlito5::Grammar::Space->opt_ws( $str, $res->{to} + 1 );
        my $stmt = $self->statement_parse( $str, $ws->{to} );
        if ($stmt) {
            $stmt->{capture}{label} = $label;
            return $stmt;
        }
        $res->{to} = $ws->{to};
        $res->{capture} = Perlito5::AST::Apply->new(
                'arguments' => [],
                'code'      => 'undef',
                'namespace' => '',
                'label'     => $label,
            );
        return $res;
    }

    # say "# look for a statement modifier";
    my $modifier = $self->statement_modifier($str, $res->{to}, Perlito5::Match::flat($res));

    my $p = $modifier ? $modifier->{to} : $res->{to};
    my $terminator = substr($str, $p, 1);
    die "Number or Bareword found where operator expected"
        if $terminator ne ';'
        && $terminator ne '}'
        && $terminator ne '';

    if (!$modifier) {
        # say "# statement expression no modifier result: ", $res->perl;
        # TODO - require a statement terminator
        return $res;
    }
    return $modifier;
}

1;

=begin

=head1 NAME

Perlito5::Grammar::Statement - Parser and AST generator for Perlito

=head1 SYNOPSIS

    statement_parse($str)

=head1 DESCRIPTION

This module parses source code for Perl 5 statements and generates Perlito5 AST.

=head1 AUTHORS

Flavio Soibelmann Glock <fglock@gmail.com>.
The Pugs Team E<lt>perl6-compiler@perl.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2011, 2012 by Flavio Soibelmann Glock and others.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=end

