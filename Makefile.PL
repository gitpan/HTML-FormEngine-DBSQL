use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'HTML::FormEngine::DBSQL',
	VERSION_FROM => 'DBSQL.pm', # finds $VERSION
	PREREQ_PM => {
		'Clone' => 0.13,
		'Hash::Merge' => 0.07,
		'Locale::gettext' => 1.01,
		'Date::Pcalc' => 1.2,
		'HTML::FormEngine' => 0.7.1
	},
);
