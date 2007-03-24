#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 32;
use_ok 'Statistics::RankCorrelation';

my $c = eval { Statistics::RankCorrelation->new };
isa_ok $c, 'Statistics::RankCorrelation', 'no argument constructor';

my $r;  # result display confirmation

my @x      = qw( 0 0 0 0 );
my @x_rank = qw( 2.5 2.5 2.5 2.5 ); 
my @y      = qw( 0 );
my @y_rank = qw( 2.5 2.5 2.5 2.5 );
$c = eval { Statistics::RankCorrelation->new( \@x, \@y ) };
isa_ok $c, 'Statistics::RankCorrelation';
is_deeply $c->x_data, \@x, "x data [@x]";
is_deeply $c->y_data, \@x, 'y data zero padded';
is_deeply $c->x_rank, \@x_rank, "x rank [@x_rank]";
is_deeply $c->y_rank, \@y_rank, "y rank [@y_rank]";
is $c->spearman, 1, '1 spearman perfect positive correlation'; 
is $c->csim, 1, '1 csim perfect positive correlation';

@x = @x_rank = @y_rank = qw( 1 2 3 4 );
@y = qw( 0.1 0.2 0.3 0.4 );
$c = eval { Statistics::RankCorrelation->new(\@x, \@y) };
isa_ok $c, 'Statistics::RankCorrelation';
is_deeply $c->x_data, \@x, "x data [@x]";
is_deeply $c->y_data, \@y, "y data [@y]";
is_deeply $c->x_rank, \@x_rank, "x rank [@x]";
is_deeply $c->y_rank, \@y_rank, "y rank [@y]";
is $c->spearman, 1, '1 spearman perfect positive correlation'; 
is $c->csim, 1, '1 csim perfect positive correlation';

@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 8 7 6 5 4 3 2 1 );
$c = Statistics::RankCorrelation->new(\@x, \@y);
is $c->spearman, -1, '-1 spearman perfect negative correlation'; 
$r = 0.125;
is $c->csim, $r, "$r csim positive correlation";

# http://faculty.vassar.edu/lowry/ch3b.html
@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 2 1 5 3 4 7 8 6 );
$c = Statistics::RankCorrelation->new(\@x, \@y);
$r = 0.833333333333333;
is $c->spearman, $r, "$r spearman positive correlation";
$r = 0.84375;
is $c->csim, $r, "$r csim positive correlation";

# tied ranks
@x = qw( 1   3   2   4   5   6   );
@y = qw( 1.0 3.2 2.1 3.2 3.2 4.3 );
$c = Statistics::RankCorrelation->new(\@x, \@y);
$r = 0.942857142857143;
is $c->spearman, $r, "$r tied rank spearman positive correlation";
$r = 0.916666666666667;
is $c->csim, $r, "$r tied rank csim positive correlation";

# http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html
@x = qw( 579 509 527 516 592 503 511 517 538 );
@y = qw( 594 513 566 588 584 510 535 514 582 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
$r = 0.766666666666667;
is $c->spearman, $r, "$r spearman positive correlation";
$r = 0.851851851851852;
is $c->csim, $r, "$r csim positive correlation";

# http://www.cohort.com/costatnonparametric.html
@x = qw( 8.7  8.5  9.4 10   6.3  7.8  11.9 6.5  6.6  10.6 10.2 7.2  8.6  11.1 11.6 );
@y = qw( 5.95 5.65 6   5.7  4.7  5.53 6.4  4.18 6.15 5.93  5.7 5.68 6.13  6.3  6.03 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
$r = 0.649107142857143;
is $c->spearman, $r, "$r spearman positive correlation";
$r = 0.764444444444444;
is $c->csim, $r, "$r csim positive correlation";

# http://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient
@x = qw( 106 86 100 100 99 103 97 113 113 110 );
@y = qw(   7  0  28  50 28  28 20  12   7  17 );
my @sx = qw( 86 97 99 100 100 103 106 110 113 113 );
my @sy = qw(  0 20 28  28  50  28   7  17   7  12 );
@x_rank = qw( 1 2 3 4.5  4.5 6 7   8 9.5 9.5 ); 
@y_rank = qw( 1 6 8 8   10   8 2.5 5 2.5 4   );
$c = Statistics::RankCorrelation->new( \@x, \@y, sorted => 1 );
is_deeply $c->x_data, \@sx, "x sorted data [@sx]";
is_deeply $c->y_data, \@sy, "y sorted by x data [@sy]";
is_deeply $c->x_rank, \@x_rank, "x rank [@x_rank]";
is_deeply $c->y_rank, \@y_rank, "y rank [@y_rank]";
$r = -0.187878787878788;
is $c->spearman, $r, "$r spearman negative correlation";

# http://en.wikipedia.org/wiki/Kendall's_tau
@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 3 4 1 2 5 7 8 6 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
$r = 0.571428571428571;
is $c->kendall_tau, $r, "$r kendall tau positive correlation";
