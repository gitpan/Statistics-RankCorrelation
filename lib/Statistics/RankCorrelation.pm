# $Id: RankCorrelation.pm,v 1.2 2003/08/04 15:32:20 gene Exp $

package Statistics::RankCorrelation;
use strict;
use vars qw($VERSION); $VERSION = '0.02';
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(
    csim 
    spearman
    correlation_coefficient
);

#     6 * sum((X_i - Y_i)^2)
# 1 - ----------------------
#         N * (N^2 - 1)
sub spearman {
    my ($u, $v) = @_;

    # Bail if either vector is empty. 
    croak "Both vectors must be defined and have numerical elements\n"
        unless ($u && $v) && (@$u && @$v);

    # "Normalize" the vectors.
    ($u, $v) = _pad_vectors($u, $v);

    # Initialize the squared rank difference sum.
    my $sum = 0;
    # Compute the squared rank difference sum.
    for my $i (0 .. @$u - 1) {
        $sum += ($u->[$i] - $v->[$i]) ** 2;
    }

    # Return the rank correlation coefficient.
    return 1 - ((6 * $sum) / (@$u * ((@$u ** 2) - 1)));
}

#        sum[ (X_i - X_ave) * (Y_i - Y_ave) ]
# -------------------------------------------------------
# sqrt{ sum[ (X_i - X_ave)^2 ] * sum[ (Y_i - Y_ave)^2 ] }
#
#             sum(x * y) - [ sum(x) * sum(y) / N ]
# ----------------------------------------------------------------
#sqrt{ [ sum(x^2) - sum(x)^2 / N ] * [ sum(y^2) - sum(y)^2 / N ] }
sub correlation_coefficient {
    my ($u, $v) = @_;
    
    # Bail if either vector is empty. 
    croak "Both vectors must be defined and have numerical elements\n"
        unless ($u && $v) && (@$u && @$v);
        
    # "Normalize" the vectors.
    ($u, $v) = _pad_vectors($u, $v);

    my $u_ave = 0;
    $u_ave += $_ for @$u;
    $u_ave /= @$u;

    my $v_ave = 0;
    $v_ave += $_ for @$v;
    $v_ave /= @$v;

    my ($numerator, $denominator) = (0, 0);
    my ($u_denominator, $v_denominator) = (0, 0);

    for my $i (0 .. @$u - 1) {
        my $u_numerator = ($u->[$i] - $u_ave);
        my $v_numerator = ($v->[$i] - $v_ave);

        $numerator += $u_numerator * $v_numerator;

        $u_denominator += $u_numerator ** 2;
        $v_denominator += $v_numerator ** 2;
    }

    return $numerator / sqrt($u_denominator * $v_denominator);
}

# Get the "contour similarity index measure" number - a single 
# dimensional measure of higher or lower value between two vectors.
sub csim {
    my ($u, $v) = @_;

    # Bail if either vector is empty.
    croak "Both vectors must be defined and have numerical elements\n"
        unless ($u && $v) && (@$u && @$v);

    # "Normalize" the vectors.
    ($u, $v) = _pad_vectors($u, $v);

    # Get the pitch matrices for each vector.
    my $m1 = _correlation_matrix($u);
#warn map { "@$_\n" } @$m1;
    my $m2 = _correlation_matrix($v);
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

# Append zeros to either vector for all values in the other that do
# not have a corresponding value.
sub _pad_vectors {
    my ($u, $v) = @_;

    if (@$u > @$v) {
        $v = [ @$v, (0) x (@$u - @$v) ];
    }
    elsif (@$u < @$v) {
        $u = [ @$u, (0) x (@$v - @$u) ];
    }

    return $u, $v;
}

# Build a square, binary matrix that represents "higher or lower"
# value within the given vector.
sub _correlation_matrix {
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

1;

__END__

=head1 NAME

Statistics::RankCorrelation - Compute the rank correlation between two vectors 

=head1 SYNOPSIS

  use Statistics::RankCorrelation qw(
      csim
      spearman
      correlation_coefficient
  );

  $n = csim(\@u, \@v);

  $n = spearman(\@u, \@v);

  $n = correlation_coefficient(\@u, \@v);

=head1 DESCRIPTION

This module computes the rank correlation coefficient between two 
sample vectors.

As an example, this metric is employed in the study of musical 
contour similarity and "sample agreement".

Okay.  Some definitions are always in order:

Statistical rank: The ordinal number of a value in a list arranged in 
a specified order (usually decreasing).

=head1 EXPORTED FUNCTIONS

=head2 spearman $VECTOR1, $VECTOR2

  $n = spearman($u, $v);

Spearman rank-order correlation is a nonparametric measure of 
association based on the rank of the data values.

=head2 correlation_coefficient $VECTOR1, $VECTOR2

  $n = correlation_coefficient($u, $v);

A correlation describes the strength of an association between 
variables. An association between variables means that the value of 
one variable can be predicted, to some extent, by the value of the 
other.

Note: This function "will only work when there is a linear relation 
between the variables".

=head2 csim $VECTOR1, $VECTOR2

  $n = csim($u, $v);

Return the "contour similarity index measure", which is a single 
dimensional measure of the similarity between two vectors.

This returns a measure in the range [-1..1] and is computed using
matrices of binary data representing "higher or lower" values in the
original vectors.

Please consult the C<csim> item under the C<SEE ALSO> section.

=head1 PRIVATE FUNCTIONS

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

For the C<csim> function:

C<http://www2.mdanderson.org/app/ilya/Publications/JNMRcontour.pdf>

For the other functions:

C<http://mathworld.wolfram.com/SpearmanRankCorrelationCoefficient.html>

C<http://faculty.vassar.edu/lowry/ch3b.html>

C<http://www.pinkmonkey.com/studyguides/subjects/stats/chap6/s0606801.asp>

C<http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html>

=head1 TO DO

Remember how to export without using the bloated C<Exporter> module.

Make a comprehensive test suite with a data file for all functions 
to use.

Implement other rank correlation measures.  Here is a nice survey:

C<http://jeff-lab.queensu.ca/stat/sas/sasman/sashtml/proc/zompmeth.htm>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
