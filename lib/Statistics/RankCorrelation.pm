# $Id: RankCorrelation.pm,v 1.6 2003/08/06 17:00:36 gene Exp $

package Statistics::RankCorrelation;
use vars qw($VERSION); $VERSION = '0.04';
use strict;
use Carp;

sub new {  # {{{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {
        x_data => shift,
        y_data => shift,
    };
    bless $self, $class;
    $self->_init;
    return $self;
}  # }}}

sub _init {  # {{{
    my $self = shift;

    # Bail if either vector is empty. 
    croak "Both vectors must be defined with numerical elements\n"
        unless ($self->{x_data} && $self->{y_data}) &&
               (@{$self->{x_data}} && @{$self->{y_data}});

    # "co-normalize" the vectors.
    ($self->{x_data}, $self->{y_data}) = _pad_vectors(
        $self->{x_data}, $self->{y_data}
    );

    # Get the size of the data vector.
    $self->{size} = @{ $self->{x_data} };

    # Rank the vectors.
    $self->x_rank(_rank($self->{x_data}));
    $self->y_rank(_rank($self->{y_data}));
}  # }}}

# Accessors {{{
sub x_data {
    my $self = shift;
    return $self->{x_data};
}

sub y_data {
    my $self = shift;
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
}  # }}}

# Retrn Spearman's rho correlation coefficient.
sub spearman {  # {{{
    my $self = shift;

    # Initialize the squared rank difference sum.
    my $sq_sum = 0;

    # Compute the squared rank difference sum.
    for (0 .. $self->{size} - 1) {
        $sq_sum += ($self->{x_rank}[$_] - $self->{y_rank}[$_]) ** 2;
#warn "$sq_sum\n += ($self->{x_rank}[$_] - $self->{y_rank}[$_]) ** 2";
    }

#warn "1 - ( (6 * $sq_sum) / ( $self->{size} * (( $self->{size} ** 2 ) - 1))\n";
    return 1 - ( (6 * $sq_sum) /
        ( $self->{size} * (( $self->{size} ** 2 ) - 1))
    );
}  # }}}

# Return vector ranks, with averaged ties.
sub _rank {  # {{{
    my $u = shift;

    # Rank the sorted vector with an HoL.
    my %rank;
    push @{ $rank{$u->[$_]} }, $_ + 1 for 0 .. @$u - 1;

    # Set the ranks and average any tied data.
    my @ranks;
    for my $x (sort { $a <=> $b } keys %rank) {
        # Get the number of ties.
        my $ties = @{ $rank{$x} };

        if ($ties > 1) {
            # Average the tied data.
            my $average = 0;
            $average += $_ for @{ $rank{$x} };
            $average /= $ties;
            # Add the tied rank average to the array of ranks.
            push @ranks, ($average) x $ties;
        }
        else {
            # Add the sole rank to the list of ranks.
            push @ranks, $rank{$x}[0];
        }
    }

    return \@ranks;
}  # }}}

# Return the "contour similarity index measure".
sub csim {  # {{{
    my $self = shift;

    # Get the pitch matrices for each vector.
    my $m1 = _correlation_matrix($self->{x_data});
#warn map { "@$_\n" } @$m1;
    my $m2 = _correlation_matrix($self->{y_data});
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
}  # }}}

# Append zeros to either vector for all values in the other that do
# not have a corresponding value.
sub _pad_vectors {  # {{{
    my ($u, $v) = @_;

    if (@$u > @$v) {
        $v = [ @$v, (0) x (@$u - @$v) ];
    }
    elsif (@$u < @$v) {
        $u = [ @$u, (0) x (@$v - @$u) ];
    }

    return $u, $v;
}  # }}}

# Build a square, binary matrix that represents "higher or lower"
# value within the given vector.
sub _correlation_matrix {  # {{{
    my $u = shift;
    my $c;

    # Is a row value (i) lower than a column value (j)?
    for my $i (0 .. @$u - 1) {
        for my $j (0 .. @$u - 1) {
            $c->[$i][$j] = $u->[$i] < $u->[$j] ? 1 : 0;
        }
    }

    return $c;
}  # }}}

1;

__END__

=head1 NAME

Statistics::RankCorrelation - Compute the rank correlation between two vectors 

=head1 SYNOPSIS

  use Statistics::RankCorrelation;

  $c = Statistics::RankCorrelation->new(\@u, \@v);

  $n = $c->spearman;
  $n = $c->csim;

=head1 DESCRIPTION

This module computes the rank correlation coefficient between two 
sample vectors.

Some definitions are always in order:

Statistical rank:  The ordinal number of a value's position in a list 
sorted in a specified order (usually decreasing).

Tied ranks:

=head1 PUBLIC METHODS

=head2 new VECTOR1, VECTOR2

  $c = Statistics::RankCorrelation->new(\@u, \@v);

This method constructs a new C<Statistics::RankCorrelation> object,
"co-normalizes" (i.e. pad with trailing zero values) the vectors if 
they are not the same size, and finds their statistical ranks.

=head2 x_data, y_data

  $x = $c->x_data;
  $y = $c->y_data;

Return the original data samples that were provided to the constructor 
as array references.

=head2 x_rank, y_rank

  $x = $c->x_rank;
  $y = $c->y_rank;

Return the statistically ranked data samples that were provided to 
the constructor as array references.

=head2 spearman

  $n = $c->spearman;

Spearman's rho rank-order correlation is a nonparametric measure of 
association based on the rank of the data values.  The formula is:

      6 * sum( (Ri - Si)^2 )
  1 - ----------------------
          N * (N^2 - 1)

Where Ri and Si are the ranks of the values of the two data vectors,
and N is the number of samples in the vectors.

The Spearman correlation is a special case of the Pearson 
product-moment correlation.

=head2 csim

  $n = $c->csim;

Return the "contour similarity index measure", which is a single 
dimensional measure of the similarity between two vectors.

This returns a measure in the range [-1..1] and is computed using
matrices of binary data representing "higher or lower" values in the
original vectors.

Please consult the C<csim> item under the C<SEE ALSO> section.

=head1 PRIVATE FUNCTIONS

=head2 _rank

  $u_ranks = _rank(\@u);

Return an array reference of the ordinal ranks of the given data.

In the case of a tie in the data (identical values) the rank numbers
are averaged.  An example will help:

  data  = [1.0, 2.1, 3.2,   3.2,   3.2,   4.3]
  ranks = [1,   2,   9.6/3, 9.6/3, 9.6/3, 4]

=head2 _pad_vectors

  ($u, $v) = _pad_vectors($u, $v);

Append zeros to either input vector for all values in the other that 
do not have a corresponding value.  That is, "pad" the tail of the 
shorter vector with zero values.

=head2 _correlation_matrix

  $matrix = _correlation_matrix($u);

Return the correlation matrix for a single vector.

This function builds a square, binary matrix that represents "higher 
or lower" value within the vector itself.

=head1 SEE ALSO

For the C<csim> method:

C<http://www2.mdanderson.org/app/ilya/Publications/JNMRcontour.pdf>

For the <Cspearman> method:

C<http://mathworld.wolfram.com/SpearmanRankCorrelationCoefficient.html>

C<http://faculty.vassar.edu/lowry/ch3b.html>

C<http://www.pinkmonkey.com/studyguides/subjects/stats/chap6/s0606801.asp>

C<http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html>

C<http://www.statsoftinc.com/textbook/stnonpar.html#correlations>

C<http://software.biostat.washington.edu/~rossini/courses/intro-nonpar/text/Tied_Data.html#SECTION00427000000000000000>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
