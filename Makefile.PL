# $Revision: 49 $
# $Date: 2008-08-05 22:52:19 -0700 (Tue, 05 Aug 2008) $
# $Author: drewgstephens $
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Mac::iTunes::Library',
    VERSION_FROM	=> 'lib/Mac/iTunes/Library.pm',
	LICENSE			=> 'perl',
    AUTHOR			=> 'Drew Stephens <drewgstephens@gmail.com>',
    PREREQ_PM		=> {
				'XML::Parser'	=> '0',
				},
);
