package Statistics::RankCorrelation;
use strict;
use vars qw($VERSION); $VERSION = '0.01';
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(
    binary
    spearman
);

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
        my $rank = $u->[$i] - $v->[$i];
        $sum += $rank ** 2;
    }

    # Return the rank correlation coefficient.
    return 1 - ((6 * $sum) / (@$u * ((@$u ** 2) - 1)));
}

# Get the "rank correlation" number - a single dimensional measure of
# higher or lower value between two vectors.
sub binary {
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

  use Statistics::RankCorrelation qw(binary spearman);

  $n = binary(
      [1,   2, 3,   4,      5],
      [0.1, 2, 1.3, 0.004, 50]
  );

  $n = spearman(
      [1,   2, 3,   4,      5],
      [0.1, 2, 1.3, 0.004, 50]
  );

=head1 DESCRIPTION

This module computes the rank correlation coefficient between two 
samples.

This can be thought of as vector similarity in terms of a single value.

As an example, this metric is employed in the study of musical 
contour similarity and "sample agreement".

=head1 EXPORTED FUNCTIONS

=over 4

=item binary $VECTOR1, $VECTOR2

  $n = binary($u, $v);

Return the "rank correlation" number, which is a single dimensional 
measure of the values between two vectors.

This returns a measure in the range [-1 .. 1] and is computed using
matrices of binary data representing "higher or lower" values in the
original vectors.

Please consult the C<binary> item under the C<SEE ALSO> section.

=item spearman $VECTOR1, $VECTOR2

  $n = spearman($u, $v);

Return the "rank correlation" number, which is a single dimensional 
measure of the values between two vectors.

Please consult the C<spearman> item under the C<SEE ALSO> section.

=back

=head1 PRIVATE FUNCTIONS

=over 4

=item _pad_vectors()

  ($u, $v) = _pad_vectors($u, $v);

Append zeros to either input vector for all values in the other that 
do not have a corresponding value.  That is, "pad" the tail of the 
shorter vector with zero values.

=item _correlation_matrix()

  $matrix = _correlation_matrix($u);

Return the correlation matrix for a single vector.

This function builds a square, binary matrix that represents "higher 
or lower" value within the vector itself.

=back

=head1 SEE ALSO

For the C<binary> function:

C<http://www2.mdanderson.org/app/ilya/Publications/JNMRcontour.pdf>

For the C<spearman> function:

C<http://www.pinkmonkey.com/studyguides/subjects/stats/chap6/s0606801.asp>

=head1 TO DO

Remember how to export without using the bloated C<Exporter> module.

Implement other rank correlation measures (as referred to in the
C<SEE ALSO> literature).

Add more literature references!

Add the ability to compare more than two phrases simultaneously?

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
