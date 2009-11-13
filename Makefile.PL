# $Revision: 70 $
# $Date: 2009-05-10 01:10:48 -0400 (Sun, 10 May 2009) $
# $Author: drewgstephens $
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Mac::iTunes::Library',
    ABSTRACT        => 'Interact with iTunes libraries in Perl',
    VERSION_FROM	=> 'lib/Mac/iTunes/Library.pm',
    LICENSE         => "perl",
    AUTHOR			=> 'Drew Stephens <drew@dinomite.net>',
    PREREQ_PM		=> {
				'XML::Parser'	=> '2.36',
				},
);
