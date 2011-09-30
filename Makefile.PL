use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Data::BitStream',
    ABSTRACT     => "A class implementing a stream of bits and coding methods",
    VERSION_FROM => 'lib/Data/BitStream.pm', # finds $VERSION

    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl') : ()),

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Dana A Jacobsen <dana@acm.org>') : ()),

    PREREQ_PM => {
                     # Tested with 0.92 and 0.98
                     'Test::More'       => '0.82',
                     # I normally use 0.93, but tested with RHEL6's 0.58
                     'Mouse'            => '0.58',
                     'Mouse::Role'      => '0.58',
                 },

);