use strict;
use Test::More 'no_plan';
BEGIN {
    use_ok 'Statistics::RankCorrelation';
}

my @x      = qw( 1   2   3   4 );
my @x_rank = qw( 1   2   3   4 );
my @y      = qw( 0.1 0.2 0.3 0.4 );
my @y_rank = qw( 1   2   3   4 );

my $obj = eval {
    Statistics::RankCorrelation->new(\@x, \@y);
};
isa_ok $obj, 'Statistics::RankCorrelation';

is_deeply $obj->x_data, \@x, 'x_data';
is_deeply $obj->y_data, \@y, 'y_data';
is_deeply $obj->x_rank, \@x_rank, 'x_rank';
is_deeply $obj->y_rank, \@y_rank, 'y_rank';

is $obj->spearman, 1, 'spearman perfect positive correlation'; 
is $obj->csim, 1, 'csim perfect positive correlation';

@x = qw(1 2 3 4 5 6 7 8);
@y = qw(8 7 6 5 4 3 2 1);
$obj = Statistics::RankCorrelation->new(\@x, \@y);
is $obj->spearman, -1, 'spearman perfect negative correlation'; 
is $obj->csim, 0.125, 'csim small positive correlation';

# http://faculty.vassar.edu/lowry/ch3b.html
@x = qw(1 2 3 4 5 6 7 8);
@y = qw(2 1 5 3 4 7 8 6);
$obj = Statistics::RankCorrelation->new(\@x, \@y);
is $obj->spearman, 0.833333333333333, 'spearman large positive correlation';
is $obj->csim, 0.84375, 'csim large positive correlation';

__END__
# http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html
@x = qw(579 509 527 516 592 503 511 517 538);
@y = qw(594 513 566 588 584 510 535 514 582);
$obj = Statistics::RankCorrelation->new(\@x, \@y);
is $obj->spearman, 0.7667, 'spearman';

# http://www.cohort.com/costatnonparametric.html
@x = qw(8.7 8.5 9.4 10 6.3 7.8 11.9 6.5 6.6 10.6 10.2 7.2 8.6 11.1 11.6);
@y = qw(5.95 5.65 6 5.7 4.7 5.53 6.4 4.18 6.15 5.93 5.7 5.68 6.13 6.3 6.03);
$obj = Statistics::RankCorrelation->new(\@x, \@y);
is $obj->spearman, 0.64910714286, 'spearman';
