#!/usr/bin/perl -w

use strict;
use HTML::FormEngine::DBSQL::PGSQL;
use DBI;
use CGI;
#use POSIX;
#setlocale(LC_MESSAGES, 'german');

my $q = new CGI;
print $q->header;

my $dbh = DBI->connect('dbi:Pg:dbname=test', 'test');
my $Form = HTML::FormEngine::DBSQL::PGSQL->new(scalar $q->Vars, $dbh);
my %preconf = (
	       phone => {
		   SIZE => [[5,13]],
		   SUBTITLE => [['', '&nbsp;/&nbsp;']]
		   }
	       );
$Form->dbsql_set_secret('te123st');
#$Form->dbsql_set_row(0);
$Form->dbsql_preconf(\%preconf, undef, {templ => 'text', TYPE => 'password', TITLE => 'Conf. Password', NAME => 'passconf', ERROR => 'fmatch', fmatch => 'login.password'});
$Form->dbsql_conf(['user','login'], {user => 'uid IS NOT NULL', login => 'uid IS NOT NULL'});
print $q->start_html('FormEngine-dbsql example: User Administration');
$Form->make();
if($Form->ok) {
    $_ = $Form->dbsql_update();
    print "Successfully updated $_ user(s)" if($_);
}

print $Form->get,
      $q->end_html;
$dbh->disconnect;
