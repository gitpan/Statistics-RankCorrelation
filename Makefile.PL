use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Statistics::RankCorrelation',
    VERSION_FROM => 'lib/Statistics/RankCorrelation.pm',
    PREREQ_PM    => {
        'Test::More' => 0,
        'Carp' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Statistics/RankCorrelation.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
