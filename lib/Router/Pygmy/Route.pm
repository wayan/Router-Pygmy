package Router::Pygmy::Route;

use strict;
use warnings;

# ABSTRACT: simple route object 

use Carp;

sub spec { shift()->{spec}; }

sub arg_names { shift()->{arg_names}; }

sub arg_idxs { shift()->{arg_idxs}; }

sub parts { shift()->{parts}; }

sub new {
    my ($class, %fields) = @_;
    return bless(\%fields, $class);
}

sub parse {
    my ( $class, $spec ) = @_;

    my ( @arg_names, @arg_idxs, @parts );
    my $i = 0;
    for my $part ( grep { $_ } split m{/}, $spec ) {
        my $is_arg = $part =~ s/^://;
        if ($is_arg) {
            push @parts,     undef;
            push @arg_idxs,  $i;
            push @arg_names, $part;
        }
        else {
            push @parts, $part;
        }
        $i++;
    }
    return $class->new(
        spec      => $spec,
        parts     => \@parts,
        arg_names => \@arg_names,
        arg_idxs  => \@arg_idxs,
    );
}

sub path_for {
    my $this = shift;

    my @parts = @{ $this->parts };
    @parts[ @{ $this->arg_idxs } ] = $this->args_for(@_);
    return join '/', @parts;
}

sub args_for {
    my $this = shift;
    my $args
        = !@_ || !defined $_[0] ? []
        : !ref $_[0] ? [ shift() ]
        :              shift();

    my $arg_names = $this->arg_names;

    if ( ref $args eq 'ARRAY' ) {

        # positional args
        @$args == @$arg_names
            or croak sprintf
            "Invalid arg count for route '%s', got %d args, expected %d",
            $this->spec, scalar @$args, scalar @$arg_names;
        return @$args;
    }
    elsif ( ref $args eq 'HASH' ) {

        # named args
        keys %$args == @$arg_names
            && not( grep { !exists $args->{$_}; } @$arg_names )
            or croak sprintf
            "Invalid args for route '%s', got (%s) expected (%s)",
            $this->spec,
            join( ', ', map {"'$_'"} sort { $a cmp $b } keys %$args ),
            join( ', ', map {"'$_'"} @$arg_names );

        return @$args{@$arg_names};
    }
    else {
        croak sprintf "Invalid args for route '%s' (%s)", $this->spec, $args;
    }
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 
