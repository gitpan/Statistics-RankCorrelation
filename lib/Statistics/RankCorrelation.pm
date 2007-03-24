# $Id: RankCorrelation.pm,v 1.26 2007/03/24 17:50:59 gene Exp $

package Statistics::RankCorrelation;
our $VERSION = '0.10';
use strict;
use warnings;
use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Handle the unnamed single, pair and optional parameters.
    my( $u, $v ) = ( shift, shift );
    my %args = ();
    # Two vectors and parameters given.
    if( @_ ) {
        %args = @_;
    }
    # Parameters given but no vectors.
    elsif( $u =~ /^\D+$/ && $v ) {
        $args{$u} = $v;
    }
    else {
        # Empty object created.
    }

    my $self  = {
        x_data => $u || [],
        y_data => $v || [],
        sorted => $args{sorted},
    };

    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;

    # Automatically compute the statistical ranks if given data.
    if( $self->x_data && $self->y_data &&
        @{ $self->x_data } && @{ $self->y_data }
    ) {
        # "Co-normalize" the vectors if they are unequal.
        my( $x, $y ) = pad_vectors( $self->x_data, $self->y_data );

        # "Co-sort" the vector pair by the first one.
        ( $x, $y ) = co_sort( $x, $y ) if $self->{sorted};

        # Set the massaged data.
        $self->x_data( $x );
        $self->y_data( $y );

        # Set the size of the data vector.
        $self->size( scalar @{ $self->x_data } );

        # Set the ranks of the vectors.
        $self->x_rank( rank( $self->x_data ) );
        $self->y_rank( rank( $self->y_data ) );
    }
}

sub size {
    my $self = shift;
    $self->{size} = shift if @_;
    return $self->{size};
}

sub x_data {
    my $self = shift;
    $self->{x_data} = shift if @_;
    return $self->{x_data};
}

sub y_data {
    my $self = shift;
    $self->{y_data} = shift if @_;
    return $self->{y_data};
}

sub x_rank {
    my $self = shift;
    $self->{x_rank} = shift if @_;
    return $self->{x_rank};
}

sub y_rank {
    my $self = shift;
    $self->{y_rank} = shift if @_;
    return $self->{y_rank};
}

sub spearman {
# Return Spearman's rho correlation coefficient.
    my $self = shift;

    # Initialize the squared rank difference sum.
    my $sq_sum = 0;

    # Compute the sum of the absolute difference of the squared ranks.
    for( 0 .. $self->size - 1 ) {
        $sq_sum += (abs(
            $self->{x_rank}[$_] - $self->{y_rank}[$_]
        )) ** 2;
#warn "$sq_sum\n += ( $self->{x_rank}[$_] - $self->{y_rank}[$_] ) ** 2";
    }

#     warn "1 - ( (6 * $sq_sum) / ( $self->size * (( $self->size ** 2 ) - 1))\n";
    return 1 - ( (6 * $sq_sum) / ( $self->size * (( $self->size ** 2 ) - 1))
    );
}


sub rank {
    my $u = shift;

    # Make a list of ranks for each datum.
    my %rank;
    push @{ $rank{ $u->[$_] } }, $_ for 0 .. @$u - 1;

    my ($old, $cur) = (0, 0);

    # Set the averaged ranks.
    my @ranks;
    for my $x (sort { $a <=> $b } keys %rank) {
        # Get the number of ties.
        my $ties = @{ $rank{$x} };
        $cur += $ties;

        if ($ties > 1) {
            # Average the tied data.
            my $average = $old + ($ties + 1) / 2;
            $ranks[$_] = $average for @{ $rank{$x} };
        }
        else {
            # Add the single rank to the list of ranks.
            $ranks[ $rank{$x}[0] ] = $cur;
        }

        $old = $cur;
    }

    return \@ranks;
}

sub co_sort {
    my( $u, $v ) = @_;
    return unless @$u == @$v;
    # Ye olde Schwartzian Transforme:
    $v = [
        map { $_->[1] }
            sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
                map { [ $u->[$_], $v->[$_] ] }
                    0 .. @$u - 1
    ];
    # Sort the independent vector last.
    $u = [ sort { $a <=> $b } @$u ];
    return $u, $v;
}

sub csim {
    my $self = shift;

    # Get the pitch matrices for each vector.
    my $m1 = correlation_matrix($self->{x_data});
#warn map { "@$_\n" } @$m1;
    my $m2 = correlation_matrix($self->{y_data});
#warn map { "@$_\n" } @$m2;

    # Compute the rank correlation.
    my $k = 0;
    for my $i (0 .. @$m1 - 1) {
        for my $j (0 .. @$m1 - 1) {
            $k++ if $m1->[$i][$j] == $m2->[$i][$j];
        }
    }

    # Return the rank correlation normalized by the number of rows in
    # the pitch matrices.
    return $k / (@$m1 * @$m1);
}

sub pad_vectors {
# Append zeros to either vector for all values in the other that do
# not have a corresponding value.
    my ($u, $v) = @_;

    if (@$u > @$v) {
        $v = [ @$v, (0) x (@$u - @$v) ];
    }
    elsif (@$u < @$v) {
        $u = [ @$u, (0) x (@$v - @$u) ];
    }

    return $u, $v;
}

sub correlation_matrix {
# Build a square, binary matrix that represents "higher or lower"
# value within the given vector.
    my $u = shift;
    my $c;

    # Is a row value (i) lower than a column value (j)?
    for my $i (0 .. @$u - 1) {
        for my $j (0 .. @$u - 1) {
            $c->[$i][$j] = $u->[$i] < $u->[$j] ? 1 : 0;
        }
    }

    return $c;
}

sub kendall_tau {
# Return Kendall's tau correlartion coefficient
    my $self = shift;

    # Initialize number of concordant and discordant values.
    my $concordant = 0;
    my $discordant = 0;

    # Get a list of the order of the index of the sorted ranks of the
    # first list.
    my @list =
    map $_->[0] + 1,
        sort { $a->[1] <=> $b->[1] }
            map [ $_, $self->{x_rank}[$_] ],
                0 .. $self->size - 1;

    # calculate number of concordant and number of discordant
    while (my $index = shift @list) {
        for (@list) {
            $concordant++
                if $self->{x_rank}[ $index - 1 ] < $self->{y_rank}[ $_ - 1 ];
            $discordant++
                if $self->{y_rank}[ $index - 1 ] > $self->{y_rank}[ $_ - 1 ] ;
        }
    }

    return (2 * ($concordant - $discordant)) /
           ($self->size * ($self->size - 1));
}

1;

__END__

=head1 NAME

Statistics::RankCorrelation - Compute the rank correlation between two vectors 

=head1 SYNOPSIS

  use Statistics::RankCorrelation;

  $x = [ 8, 7, 6, 5, 4, 3, 2, 1 ];
  $y = [ 2, 1, 5, 3, 4, 7, 8, 6 ];

  $c = Statistics::RankCorrelation->new( $x, $y, sorted => 1 );

  $s = $c->size;
  $xd = $c->x_data;
  $yd = $c->y_data;
  $xr = $c->x_rank;
  $yr = $c->y_rank;

  $n = $c->spearman;
  $m = $c->csim;
  $t = $c->kendall_tau;

=head1 DESCRIPTION

This module computes rank correlation coefficient measures between two 
sample vectors.

Working examples may be found in the distribution C<eg/> directory and 
the module test file.

Also the C<HANDY FUNCTIONS> section below has some ..handy functions 
to use when computing sorted rank coefficients by hand.

=head1 METHODS

=head2 new

  $c = Statistics::RankCorrelation->new( \@u, \@v );

This method constructs a new C<Statistics::RankCorrelation> object.

If given two numeric vectors (as array references), the object is
initialized by computing the statistical ranks of the vectors.  If
they are of different cardinality the shorter vector is first padded
with trailing zeros.

=head2 x_data

  $c->x_data( $y );
  $x = $c->x_data;

Return and set the one dimensional array reference data.  This is the
"unit" array, used as a reference for size and iteration.

=head2 y_data

  $c->y_data( $y );
  $x = $c->y_data;

Return and set the one dimensional array reference data.  This vector
is dependent on the unit vector.

=head2 size

  $c->size( $s );
  $s = $c->size;

Return and set the number of elements in the unit array.

=head2 x_rank

  $c->x_rank( $rx );
  $rx = $c->x_rank;

Return and set the ranked "unit" data as an array reference.

=head2 y_rank

  $ry = $c->y_rank;
  $c->y_rank( $ry );

Return (and optionally set) the ranked data as array references.

=head2 spearman

  $n = $c->spearman;

Spearman's rho rank-order correlation is a nonparametric measure of 
association based on the rank of the data values and is a special 
case of the Pearson product-moment correlation.

The formula is:

      6 * sum( (Xi - Yi)^2 )
  1 - --------------------------
           n (n^2 - 1)

Where C<X> and C<Y> are the two rank vectors and C<i> is an index 
from one to C<n> number of samples.

=head2 kendall_tau

  $t = $c->kendall_tau;

         4P
  t = --------- - 1
      n (n - 1)

=head2 csim

  $n = $c->csim;

Return the contour similarity index measure.  This is a single 
dimensional measure of the similarity between two vectors.

This returns a measure in the (inclusive) range C<[-1..1]> and is 
computed using matrices of binary data representing "higher or lower" 
values in the original vectors.

This measure has been studied in musical contour analysis.

=head1 FUNCTIONS

=head2 rank

  $ranks = rank( [ 1.0, 3.2, 2.1, 3.2, 3.2, 4.3 ] );
  # [1, 4, 2, 4, 4, 6]

Return an array reference of the ordinal ranks of the given data.

Note that the data must be sorted as measurement pairs prior to 
computing the statistical rank.  This is done automatically by the
object initialization method.

In the case of a tie in the data (identical values) the rank numbers
are averaged.  An example will elucidate:

  sorted data:    [ 1.0, 2.1, 3.2, 3.2, 3.2, 4.3 ]
  ranks:          [ 1,   2,   3,   4,   5,   6   ]
  tied ranks:     3, 4, and 5
  tied average:   (3 + 4 + 5) / 3 == 4
  averaged ranks: [ 1,   2,   4,   4,   4,   6   ]

=head2 pad_vectors

  ( $u, $v ) = pad_vectors( [ 1, 2, 3, 4 ], [ 9, 8 ] );
  # [1, 2, 3, 4], [9, 8, 0, 0]

Append zeros to either input vector for all values in the other that 
do not have a corresponding value.  That is, "pad" the tail of the 
shorter vector with zero values.

=head2 co_sort

  ( $u, $v ) = co_sort( $u, $v );

Sort the vectors as two dimensional data-point pairs with B<u> values
sorted first.

=head2 correlation_matrix

  $matrix = correlation_matrix( $u );

Return the correlation matrix for a single vector.

This function builds a square, binary matrix that represents "higher 
or lower" value within the vector itself.

=head1 TO DO

Figure out what "> 0.5 discrepency" that Vladimir Babenko
E<lt>Vl_Babenko@softhome.netE<gt> saw.

Handle any number of vectors instead of just two.

Implement other rank correlation measures that are out there...

=head1 SEE ALSO

For the C<csim> method:

L<http://www2.mdanderson.org/app/ilya/Publications/JNMRcontour.pdf>

For the C<spearman> and C<kendall_tau> methods:

L<http://mathworld.wolfram.com/SpearmanRankCorrelationCoefficient.html>

L<http://en.wikipedia.org/wiki/Kendall's_tau>

=head1 THANK YOU

Thomas Breslin E<lt>thomas@thep.lu.seE<gt> for unsorted C<rank> code.

Jerome E<lt>jerome.hert@free.frE<gt> for Kendall's tau

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, Gene Boggs

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
