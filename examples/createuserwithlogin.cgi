#!/usr/bin/perl -w

use strict;
use HTML::FormEngine::DBSQL::PGSQL;
use DBI;
use CGI;
#use POSIX; #for setlocale
#setlocale(LC_MESSAGES, 'german'); #for german error messages

my $q = new CGI;
print $q->header;

my $dbh = DBI->connect('dbi:Pg:dbname=test', 'test');
my $Form = HTML::FormEngine::DBSQL::PGSQL->new(scalar $q->Vars, $dbh);
my %preconf = (
	       phone => {
		   SIZE => [[5,13]],
		   SUBTITLE => [['', '&nbsp;/&nbsp;']],
		   }
	       );
$Form->dbsql_preconf(\%preconf, undef, {templ => 'text', TYPE => 'password', TITLE => 'Conf. Password', NAME => 'passconf', ERROR => 'fmatch', fmatch => 'login.password'});
$Form->dbsql_conf(['user','login']);
$Form->make();
print $q->start_html('FormEngine-dbsql example: User Administration');
if($Form->ok) {
    if($_ = $Form->dbsql_insert()) {
	print "Sucessfully added $_ user(s)!<br>";
	$Form->clear;
    }
}
print $Form->get,
      $q->end_html;
$dbh->disconnect;
