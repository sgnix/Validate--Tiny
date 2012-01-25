use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Validate::Tiny',
    AUTHOR              => q{minimalist <minimalist@lavabit.com>},
    VERSION_FROM        => 'lib/Validate/Tiny.pm',
    ABSTRACT_FROM       => 'lib/Validate/Tiny.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.94,
        'List::MoreUtils' => 0
      },
    MIN_PERL_VERSION    => '5.008',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Validate-Tiny-*' },
);
