use Test::More 'no_plan';#tests => 1;
use strict;

BEGIN {
    use_ok 'Statistics::RankCorrelation', qw(binary spearman);
}

my $n;

# binary {{{
$n = eval { binary() };
ok $@, 'with no arguments';

$n = eval { binary([]) };
ok $@, 'with one blank argument';

$n = eval { binary([], []) };
ok $@, 'with two blank arguments';

$n = eval { binary([1, 2]) };
ok $@, 'with one vector argument';

$n = eval { binary([1], [1]) };
is $n, 1, 'with two, identical, single element vector arguments';

$n = eval { binary([1], [2]) };
is $n, 1, 'with two, different, single element vector arguments';

$n = eval { binary([1, 1], [1, 1]) };
is $n, 1, 'with two, identical, double element vector arguments';

$n = eval { binary([1, 1], [2, 2]) };
is $n, 1, 'with two, "same interval", double element vector arguments';

$n = eval { binary([1, 2], [2, 1]) };
is $n, 0.5, 'with two, different, double element vector arguments';
# }}}

# spearman {{{
$n = eval { spearman() };
ok $@, 'with no arguments';

$n = eval { spearman([]) };
ok $@, 'with one blank argument';

$n = eval { spearman([], []) };
ok $@, 'with two blank arguments';

$n = eval { spearman([1, 2]) };
ok $@, 'with one vector argument';

$n = eval { spearman([1], [1]) };
is $n, undef, 'with two, identical, single element vector arguments';

$n = eval { spearman([1], [2]) };
is $n, undef, 'with two, different, single element vector arguments';

$n = eval { spearman([1, 1], [1, 1]) };
is $n, 1, 'with two, identical, double element vector arguments';

$n = eval { spearman([1, 1], [2, 2]) };
is $n, -1, 'with two, "same interval", double element vector arguments';

$n = eval { spearman([1, 2], [2, 1]) };
is $n, -1, 'with two, different, double element vector arguments';
# }}}
