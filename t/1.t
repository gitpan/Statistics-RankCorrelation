use strict;
use Test::More tests => 23;
BEGIN { use_ok 'Statistics::RankCorrelation' }

my $r;  # result display confirmation

my @x      = qw( 0 0 0 0 );
my @x_rank = qw( 2.5 2.5 2.5 2.5 ); 
my @y      = qw( 0 );
my @y_rank = qw( 2.5 2.5 2.5 2.5 );
my $obj = eval { Statistics::RankCorrelation->new( \@x, \@y ) };
isa_ok $obj, 'Statistics::RankCorrelation';
is_deeply $obj->x_data, \@x, 'all zero x_data';
is_deeply $obj->y_data, \@x, 'all zero y_data zero padded';
is_deeply $obj->x_rank, \@x_rank, 'x_rank';
is_deeply $obj->y_rank, \@y_rank, 'y_rank';
is $obj->spearman, 1, '1 spearman perfect positive correlation'; 
#use Data::Dumper;warn Dumper($obj->spearman);
is $obj->csim, 1, '1 csim perfect positive correlation';
#use Data::Dumper;warn Dumper($obj->csim);

@x      = qw( 1   2   3   4 );
@x_rank = qw( 1   2   3   4 );
@y      = qw( 0.1 0.2 0.3 0.4 );
@y_rank = qw( 1   2   3   4 );
$obj = eval { Statistics::RankCorrelation->new(\@x, \@y) };
isa_ok $obj, 'Statistics::RankCorrelation';
is_deeply $obj->x_data, \@x, 'x_data';
is_deeply $obj->y_data, \@y, 'y_data';
is_deeply $obj->x_rank, \@x_rank, 'x_rank';
is_deeply $obj->y_rank, \@y_rank, 'y_rank';
is $obj->spearman, 1, '1 spearman perfect positive correlation'; 
is $obj->csim, 1, '1 csim perfect positive correlation';

@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 8 7 6 5 4 3 2 1 );
$obj = Statistics::RankCorrelation->new(\@x, \@y);
is $obj->spearman, -1, '-1 spearman perfect negative correlation'; 
$r = 0.125;
is $obj->csim, $r, "$r csim positive correlation";

# http://faculty.vassar.edu/lowry/ch3b.html
@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 2 1 5 3 4 7 8 6 );
$obj = Statistics::RankCorrelation->new(\@x, \@y);
$r = 0.833333333333333;
is $obj->spearman, $r, "$r spearman positive correlation";
$r = 0.84375;
is $obj->csim, $r, "$r csim positive correlation";

# http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html
@x = qw( 579 509 527 516 592 503 511 517 538 );
@y = qw( 594 513 566 588 584 510 535 514 582 );
$obj = Statistics::RankCorrelation->new( \@x, \@y );
$r = 0.766666666666667;
is $obj->spearman, $r, "$r spearman positive correlation";
$r = 0.851851851851852;
is $obj->csim, $r, "$r csim positive correlation";

# http://www.cohort.com/costatnonparametric.html
@x = qw( 8.7  8.5  9.4 10   6.3  7.8  11.9 6.5  6.6  10.6 10.2 7.2  8.6  11.1 11.6 );
@y = qw( 5.95 5.65 6   5.7  4.7  5.53 6.4  4.18 6.15 5.93  5.7 5.68 6.13  6.3  6.03 );
$obj = Statistics::RankCorrelation->new( \@x, \@y );
$r = 0.649107142857143;
is $obj->spearman, $r, "$r spearman positive correlation";
$r = 0.764444444444444;
is $obj->csim, $r, "$r csim positive correlation";
