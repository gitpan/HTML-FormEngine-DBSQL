=head1 NAME

HTML::FormEngine::DBSQL - create html/xhtml forms for adding, updating
and removing records to / in / from sql database tables

=cut

######################################################################

package HTML::FormEngine::DBSQL;
require 5.004;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

use strict;
use vars qw(@ISA $VERSION);
use Locale::gettext;
use Digest::MD5 qw(md5_hex);
use HTML::FormEngine;
@ISA = qw(HTML::FormEngine);
$VERSION = '0.2';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	Carp 1.01

=head2 Nonstandard Modules

        HTML::FormEngine 0.7.2
        Clone 0.13
        Hash::Merge 0.07
        Locale::gettext 1.01

=cut

=head1 REQUIREMENTS

  Currently the only supported DBMS is PostgreSQL (see below for
  information on how to add support for your favorite DBMS).

  You'll need to create a view (column_info), this view supports
  information about the columns of the database tables. Please see the
  POD of PGSQL.pm for more information!

=cut

######################################################################

use Carp;
use Clone qw(clone);
use Hash::Merge qw(merge);
require HTML::FormEngine::DBSQL::Config;

######################################################################

=head1 SYNOPSIS

=head2 Example Code

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
    $Form->dbsql_preconf(\%preconf);
    $Form->dbsql_conf('user');
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

=head2 Example Database Table

Execute the following (Postgre)SQL commands to create the tables I used when developing the examples:

    CREATE SEQUENCE user_uid_seq;

    CREATE TABLE "user" (
	uid integer DEFAULT nextval('user_uid_seq'::text) NOT NULL,
	name character varying(40) NOT NULL,
	forename character varying(40) NOT NULL,
	street character varying(40) NOT NULL,
	zip integer NOT NULL,
	town character varying(40) NOT NULL,
	email character varying(40) NOT NULL,
	phone character varying(15)[] DEFAULT '{{,}}',
	birthday date NOT NULL,
	newsletter boolean DEFAULT 't'
    );

    ALTER TABLE ONLY "user"
	ADD CONSTRAINT user_pkey PRIMARY KEY (uid);

    COMMENT ON COLUMN "user".zip IS 'ERROR=digitonly;';

    COMMENT ON COLUMN "user".email IS 'ERROR=rfc822;';

    COMMENT ON COLUMN "user".phone IS 'ERROR_IN={{{not_null,digitonly},{not_null,digitonly}}};SUBTITLE={{,/}};SIZE={{5,10}};';

    COMMENT ON COLUMN "user".birthday IS 'ERROR=date;';

    CREATE TABLE login (
      uid integer DEFAULT currval('user_uid_seq'::text) NOT NULL,
      username character varying(30) DEFAULT '-' NOT NULL,
      "password" character varying(30) DEFAULT '-' NOT NULL
    );

    ALTER TABLE ONLY login
    ADD CONSTRAINT login_pkey PRIMARY KEY (uid);

    ALTER TABLE ONLY login
    ADD CONSTRAINT "$1" FOREIGN KEY (uid) REFERENCES "user"(uid) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;
 
    COMMENT ON COLUMN login.password IS 'TYPE=password;VALUE=;ERROR=regex;regex=".{5,}";errmsg="must have more than 4 chars!";';

    COMMENT ON COLUMN login.username IS 'ERROR=dbsql_unique;';

Of course you can use any other table(s) as well.

=head2 Example Output

This output is produced by FormEngine::DBSQL when using the example
code and the example table and no data was submitted:

    <form action="/cgi-bin/FormEngine-DBSQL/createuser.cgi" method="post">
    <table border=0 align="center" summary="">
    <tr>
    <td colspan=3>
    <table border=0 summary="">
    <tr>
       <td colspan=3>
         <input type="hidden" name=uid value="" />
       </td>
    </tr>
    <tr>
       <td valign="top">Name</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="name" maxlength="40" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Forename</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="forename" maxlength="40" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Street</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="street" maxlength="40" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Zip</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="zip" maxlength="" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Town</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="town" maxlength="40" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Email</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="email" maxlength="40" size="20" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Phone</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="phone[0][0]" maxlength="15" size="5" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td>&nbsp;/&nbsp;</td>
		    <td>
		      <input type="" value="" name="phone[0][1]" maxlength="15" size="13" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Birthday</td>
       <td>
	  <table border=0 cellspacing=0 cellpadding=0 summary="">
	    <tr>
	      <td valign="top">
		<table border=0 cellspacing=0 cellpadding=0 summary="">
		  <tr>
		    <td></td>
		    <td>
		      <input type="text" value="" name="birthday" maxlength="10" size="10" /><br/>
		    </td>
		  </tr>
		  <tr><td></td><td style="color:#FF0000"></td></tr>
		</table>
	      </td>
	    </tr>
	  </table>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td valign="top">Newsletter</td>
       <td>
	  <select size="1" name="newsletter">
	    <option value="1">Yes</option>
	    <option value="0">No</option>
	  </select>
       </td>
       <td style="color:#FF0000" valign="bottom"></td>
    </tr>
    <tr>
       <td colspan=3>&nbsp;</td>
    </tr>
    </table>
    </td>
    </tr>
    <tr>
       <td align="right" colspan=3>
	  <input type="submit" value="Ok" name="FormEngine" />
       </td>
    </tr>
    </table>
    </form>

=head1 DESCRIPTION

DBSQL.pm is a exentsion of HTML::FormEngine, that means it inherits
all functionality from HTML::FormEngine and adds some new features.

In web development, form data is mostly used to update a database. For
example most guestbooks or any similar webapplications store the
entered data in a database.  Often very large forms are needed,
e.g. when the user should provide his personal data to subscribe to an
certain service.

In most cases a SQL database is used. If you don't know anything about
SQL databases or you're not using such things, this module will hardly
help you. But if you do, you'll know that every record, that you want
to store in a certain SQL database table, has to have certain fields
and these fields must contain data of an certain type (datatype).  So
the tables structure already defines how a form, that wants to add
data to this table, might look like (in case that you don't want to
process the whole data before adding it to the table).

DBSQL.pm reads out the tables structure and creates a form definition
for HTML::FormEngine.

Two examples:

a field of type boolean will only accept 0 or 1, this is represented
in the form as 'Yes' or 'No'.

a field of type VARCHAR(30) will accept strings of maximal 30
characters, so it's represented as an one-line-text-input-field in
which you can put maximal 30 characters.

Of course you can fit the resulting form configuration to your needs,
but you don't have to!

DBSQL.pm also provides methods for adding and updating records. So you
don't have to deal with sql commands.

Provided that you have HTML::FormEngine and all its dependencies
installed, DBSQL.pm still won't be a working module. Its only a
template from which other modules shall inherit. These childs
(drivers) add DBMS specific features to the general DBSQL.pm module,
but they don't change DBSQLs API, so the here explained things are
valid for all drivers.  B<Currently the only supported DBMS is
PostgreSQL>, but it shouldn't be difficult to add support for other
DBMSs, e.g. MySQL. If you're interested in this task, see below for
further information.

=head1 OVERVIEW

You have to use the right module (driver) for your DBMS. Currently the
only available is PGSQL.pm which supports PostgreSQL.

We expect that you know how to use HTML::FormEngine, if not, please
first read its documentation.  Using HTML::FormEngine:DBSQL isn't much
diffrent: the C<conf> method is replaced by C<dbsql_conf> and you may
pass a database handle as second argument to the C<new> method, using
C<dbsql_set_dbh> is possible too. Before calling C<dbsql_conf>, you
may call C<dbsql_preconf> for setting some variables by hand.

To C<dbsql_conf> you pass the tables name and optionally a where
condition (for updating records) and/or an reference to an array with
fieldnames (for setting explecit which fields to show resp. not to
show).

=head1 USING FormEngine::DBSQL

=head2 Configuring The Form Through The Database

=head3 datatype handlers

In DBSQL::DtHandler.pm you'll find all DBMS independent datatype
handlers. The PostgreSQL specific datatype handlers are placed in
DBSQL::PGSQL::DtHandler.pm. Which handler to use for which datatype is
defined in DBSQL::PGSQL::Config.pm. If for a certain datatype no
handler is defined, the default handler will be called.

A handler creates the main part of the form field configuration.

You can easily add your own datatype handlers (see below).

=head4 array handling

Though the idea how to store arrays is taken from PostgreSQL, this
should work with any other DBMS too!

In PostgreSQL every datatype can be arrayed. PostgreSQL arrays have
the following structure: '{firstelem,secondelem}', a two dimensional
array looks like this: '{{first,second},{third,fourth}}'.  The problem
is that PostgreSQL arrays don't have a fixed size, but
FormEngine::DBSQL need such to represent the array in the form. Here
we use a trick: the size which should be represented in the form is
determined by the default value. So an field with '{,}' as default
value will be represented as an one dimensional array. Of course you
can put values between the commas, which will then printed as
defaults.

=head3 NOT NULL fields

The form value of fields which have the NOT NULL property will be
automatically passed to the I<not_null> check method. This means that
their I<ERROR> variable will be set to I<not_null>.

If the I<ERROR> variable was already set set through C<dbsql_preconf>,
nothing will be changed. If the variable was set through the fields
comment (see below), the I<not_null> check will be added in front.

If you called C<dbsql_set_show_default> and committed false (0), the
above described will only be done if the field hasn't a default value.

=head3 assigning FormEngine variables in the database

PostgreSQL offers to set comments on database objects. This feature
can be used to explicitly set form field variables in the database.

You might e.g. want to store emailadresses in a certain field of an
database table, it makes sense to validate an address before inserting
it. First possibility is to use C<dbsql_preconf> to set the ERROR
variable to 'email' or 'rfc822', but perhaps you've more than one
script which inserts or updates the table and so you're using several
forms. In every script you now have to call the C<dbsql_preconf> method and set
the ERROR variable for the email field. This isn't nice, because the
necessity to check this field is given by the table structure and so
the check should also be set by the database. You might set a check
constraint, but this will cause an ugly database error which the user
might not understand. So beside defining an constraint (which is
recommended), FormEngine::DBSQL should check the address before
inserting it. Setting the database fields comment to 'ERROR=rfc822;'
will force FormEngine::DBSQL to do so. You can still overwrite this
setting with C<dbsql_preconf>.

Below you see the whole command:

  COMMENT ON COLUMN "user".email IS 'ERROR=rfc822;'

Whenever you pass this tables name to the new method of
FormEngine::DBSQL, it'll remember to call the rfc822 check method
before inserting oder updating an I<email> field value.

You can even assign array structures to an variable:

  COMMENT ON COLUMN "user".phone IS 'ERROR_IN={{{not_null,digitonly},{not_null,digitonly}}};';

The I<phone> field is an string array, with the above command we
forbid NULL values and demand digits for the first two elements. More
about arrays and their representation in the form is described above.

It is possible to assign several variables:

  COMMENT ON COLUMN "user".zip IS 'ERROR=digitonly;TITLE=Postcode;';

Don't forget the ';' at the end of every assignment!

Of course you can still use the comment field to place normal comments
there as well:

  COMMENT ON COLUMN "user".birthday IS 'We\'re really a bit curious!;ERROR=date;';

Note the ';' at the end of the trivial comment!

In quoted areas ("..") '{', '}' and ',' are not interpreted. You can prevent the parsing of '"' and ';' by putting an '\' (backslash) in front.

=head2 Methods

=head3 dbsql_preconf ( HASHREF, PREPEND, APPEND )

In the referenced hash, you can predefine some parts of the form
configuration by hand. The hash keys must be named after the tables
fields. Every element must be a hash reference, in the referenced hash
you can set variables.

You can use the special keys I<prepend> and I<append> to add extra
fields before or after the field.

An example:

    my %preconf = (
		   name => {
                          TITLE => 'Fore- and Surname',
                          ERROR => sub {$_ = shift; m/\w\W\w/ ? return 0 : return 'failed';}
		       },
                   email => {
                          TITLE => 'Your Emailadress',
                          ERROR => 'email'
                       }
		   );
    $Form->dbsql_preconf(\%preconf);


With PREPEND and APPEND you can define extra fields which will then be
added to the top resp. the bottom of the generated form. If you want
to add more than one field, you have to reference the array which
contains the definitions, else you can reference the hash
directly. See the POD of HTML::FormEngine for information about field
definitions.

B<Note:> If you pass more than one table name to C<dbsql_conf>, you
must reference the fields with I<tablename.fieldname>!

=cut

######################################################################

sub dbsql_preconf {
  my ($self,$preconf,$prepend,$append) = @_;
  if(ref($preconf) eq 'HASH') {
    $self->{dbsql_preconf} = merge($preconf, $self->{dbsql_preconf});
  }
  $self->{dbsql_prepend} = retarref($prepend);
  $self->{dbsql_append} = retarref($append);
}

######################################################################

=head3 dbsql_conf ( TABLENAME|ARRAYREF, [ COUNT|WHERECONDITION|HASHREF, FIELDNAMES|HASHREF ] )

Creates an FormEngine-form-definition and calls FormEngines C<conf>
method.

Normally you only want to manage records out of one table, then it is
sufficient to give this tables name as first argument. But you can
also pass several table names by using an array reference.

If you provide COUNT, the form fields will be displayed COUNT times,
which means that you can insert COUNT records.

If you want to update records, you should provide WHERECONDITION
instead. This must be a valid where-condition B<without> the 'WHERE'
directive in front, or a hash reference. A hash reference you must
provide if you passed several tablenames and want to define diffrent
where conditions for theses tables. The keys must be the table names
and the elements the appendant conditions.

DBSQL then shows input fields for every found record and uses the
current values as defaults. The primary keys are stored in hidden
fields, so that they can't be changed. Later they're used for updating
the records.

If you'd like to set only some of the tables fields, put their names
in an array and pass a reference to that as third and last argument
(FIELDNAMES). If the first array element is '!', all fields which
B<aren't> found in the array will be displayed. You must use a hash
reference here, if you passed more than one table name.

=cut

######################################################################

sub dbsql_conf {
  my $self = shift;
  my (%donotuse, $sth, @pkeyval, @fconf, @conf, @fields, $i, $sql, $count, $tmp, %value, $struct, $field, $tbl, $where, @pkey, %pkey);

  $self->{dbsql_tables} = retarref(shift || $self->{dbsql_tables});
  if(! defined($self->{dbsql_tables}) || ! @{$self->{dbsql_tables}}) {
    croak 'undefined table!';
  }

  $self->{dbsql_where} = shift || $self->{dbsql_where};

  $self->{dbsql_fields} = shift || $self->{dbsql_fields};

  if(@{$self->{dbsql_tables}} > 1 && ref($self->{dbsql_fields}) ne 'HASH') {
    croak 'fields must be assigned to tables!';
  }
  elsif(@{$self->{dbsql_tables}} == 1 && ref($self->{dbsql_fields}) ne 'HASH') {
    $self->{dbsql_fields} = {$self->{dbsql_tables}->[0] => retarref($self->{dbsql_fields})};
  }
  if(ref($self->{dbsql_pkey}) ne 'HASH') {
    $_ = retarref($self->{dbsql_pkey});
    $self->{dbsql_pkey} = {$self->{dbsql_tables}->[0] => {}};
    foreach $_ (@{$_}) {
      $self->{dbsql_pkey}->{$self->{dbsql_tables}->[0]}->{$_} = 1;
    }
  }
  if(! ref($self->{dbsql_where}) and $self->{dbsql_where} =~ m/^[0-9]+$/) {
    $count = $self->{dbsql_where};
    $self->{dbsql_show_default} = 1 if($self->{dbsql_show_default} == -254);
  }
  elsif(ref($self->{dbsql_where}) ne 'HASH') {
    $where = $self->{dbsql_where};
    $self->{dbsql_where} = {};
  } else {
    $where = '';
  }
  foreach $tbl (@{$self->{dbsql_tables}}) {
    if(ref($self->{dbsql_fields}->{$tbl}) ne 'ARRAY' or ! @{$self->{dbsql_fields}->{$tbl}}) {
      $self->{dbsql_fields}->{$tbl} = ['%'];
    }
    $self->{dbsql_where}->{$tbl} = $where if(ref($self->{dbsql_where}) eq 'HASH' && ! defined($self->{dbsql_where}->{$tbl}));
    $donotuse{$tbl} = {};
    if($self->{dbsql_fields}->{$tbl}->[0] eq '!') {
      delete $self->{dbsql_fields}->{$tbl}->[0];
      foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
	$donotuse{$tbl}->{$_} = 1;
      }
      $self->{dbsql_fields}->{$tbl} = ['%']
    }
    if(! defined($self->{dbsql_pkey}->{$tbl})) {
      $self->{dbsql_pkey}->{$tbl} = {};
      foreach $_ ($self->{dbsql}->primary_key(undef, undef, $tbl)) {
    	$field = (@{$self->{dbsql_tables}} > 1 ? "$tbl.$_" : $_);
    	$self->{dbsql_pkey}->{$tbl}->{$field} = 1;
      }
    }
  }

  if(defined($self->{dbsql_prepend})) {
    push @fconf, @{retarref($self->{dbsql_prepend})};
  }

  foreach $tbl (@{$self->{dbsql_tables}}) {
    $struct = $self->get_tbl_struct($tbl,$self->{dbsql_fields}->{$tbl},$donotuse{$tbl});
    $self->{dbsql_fields}->{$tbl} = [];
    foreach $tmp (@{$struct}) {
      $_ = $self->_dbsql_makeconf($tmp,$tbl);
      push @{$self->{dbsql_fields}->{$tbl}}, $_->{fname};
      if(defined($_->{prepend})) {
	push @fconf, @{retarref($_->{prepend})};
	delete $_->{prepend};
      }
      push @fconf, $_;
      if(defined($_->{append})) {
	push @fconf, @{retarref($_->{append})};
	delete $_->{append};
      }
    }
  }

  if(defined($self->{dbsql_append})) {
    push @fconf, @{retarref($self->{dbsql_append})};
  }

  foreach $tbl (@{$self->{dbsql_tables}}) {
    foreach $field (keys(%{$self->{dbsql_pkey}->{$tbl}})) {
      delete $self->{dbsql_pkey}->{$tbl}->{$field} unless(grep {$field eq $_} @{$self->{dbsql_fields}->{$tbl}});
    }
  }

  if(! defined($count)) {
    $count = -254;
    foreach $tbl (@{$self->{dbsql_tables}}) {
      $sql = 'SELECT ';
      foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
	if(m/^(.+)?\.(.+)/) {
	  $sql .= $self->{dbsql}->quote_identifier($1) . '.' . $self->{dbsql}->quote_identifier($2);
	}
	else {
	  $sql .= $self->{dbsql}->quote_identifier($_);
	}
	$sql .= ',';
      }
      $sql =~ s/,$//;
      $sql .= ' FROM ' . $self->{dbsql}->quote_identifier($tbl);
      if($self->{dbsql_where}->{$tbl} ne '') {
	$sql .= ' WHERE '.$self->{dbsql_where}->{$tbl};
      }
      $sth = $self->{dbsql}->prepare($sql);
      if(! $sth->execute) {
	die($self->{dbsql}->errstr);
	$self->_dbsql_sql_error($sth->{Statement});
      }
      else {
	if($count == -254) {
	  $count = $sth->rows 
	}
	elsif($count ne $sth->rows) {
	  croak('There must be the same count of records for each table!');
	}
	while($self->{dbsql_show_value} && ($tmp = $sth->fetchrow_hashref)) {
	  foreach $_ (keys(%{$tmp})) {
	    $field = (@{$self->{dbsql_tables}} > 1 ? "$tbl.$_" : $_);
	    if(ref($value{$field}) ne 'ARRAY') {
	      $value{$field} = [];
	    }
	    if(defined($tmp->{$_}) and $tmp->{$_} =~ m/^({.*})$/) {
	      push @{$value{$field}}, ($self->_dbsql_parse($1));
	    }
	    else {
	      push @{$value{$field}}, $tmp->{$_};
	    }
	  }
	}
      }
    }
  }
  
  if($self->{dbsql_row} > 0 or $count > 1 and $self->{dbsql_row} == -254) {
    $self->{dbsql_row} = 1;
    $tmp = [];
    foreach $_ (@fconf) {
      push @{$tmp}, $_->{TITLE};
      $_->{TITLE} = '';
    }
    push @conf, {templ => 'title', TITLE => $tmp};
  }

  @pkey = ();
  foreach $_ (keys(%{$self->{dbsql_pkey}})) {
    push @pkey, keys(%{$self->{dbsql_pkey}->{$_}});
  }

  for($i=0; $i<$count; $i++) {
    @pkeyval = ();
    $tmp = clone(\@fconf);
    if(keys(%value) || $self->{dbsql_secret}) {
      foreach $field (@{$tmp}) {
	if(keys(%value)) {
	  if(defined($field->{fname}) && defined($value{$field->{fname}})) {
	    $field->{VALUE} = shift @{$value{$field->{fname}}} unless(defined($field->{VALUE}));
	  }
	}
	push @pkeyval, $field->{VALUE} if ($field->{fname} and $self->{dbsql_secret} && grep {$_ eq $field->{fname}} @pkey);
      }
    }

    $_ = md5_hex(join($self->{dbsql_secret}, @pkeyval) . $self->{dbsql_secret});
    push @{$tmp}, {templ => 'hidden', NAME => 'md5hash', VALUE => $_} if(@pkeyval);
    if($self->{dbsql_row} > 0) {
      push @conf, {templ => $self->{dbsql_row_tmpl}, ROWNUM => $i+1, sub => $tmp};
    }
    else {
      push @conf, @{$tmp}, {templ => $self->{dbsql_empty_tmpl}};
    }
  }
  
  $self->conf([{templ => 'body', sub => \@conf}]);
  if($self->{debug}) {
    foreach $_ (@fconf) {
      print $_->{NAME}, "\n";
    }
  }
}

######################################################################

=head3 dbsql_update

This method can only be used if a where-condition was passed to
C<dbsql_conf>. It updates the found table records to the submitted
values. If an error occurs, the update statement and the DBMSs error
message and number are printed. If you don't want all or some of this
information be displayed, see C<dbsql_set_sqlerr>.

Normally you must have defined a secret string if you want to use this
method, else an error message will be printed. See C<dbsql_set_secret>
for more information.

=cut

######################################################################

sub dbsql_update {
  my ($self) = @_;
  my ($md5hash, @pkeyval, @pkeyval2, $ok, $val, $tbl);
  $_ = 0;
  foreach $tbl (@{$self->{dbsql_tables}}) {
    $_ = $tbl and last unless(keys(%{$self->{dbsql_pkey}->{$tbl}}));
  }
  if($_) {
    $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Primary key is missing for table') . ' \'' . $_ . '\'!'});
    return 0;
  }
  if(! $self->{dbsql_hide_pkey} or $md5hash = $self->get_input_value('md5hash')) {
    if($self->{dbsql_hide_pkey}) {
      foreach $tbl (@{$self->{dbsql_tables}}) {
	foreach $_ (keys(%{$self->{dbsql_pkey}->{$tbl}})) {
	  push @pkeyval, $self->get_input_value($_);
	}
      }
      if(ref($md5hash) eq 'ARRAY') {
	$ok = 1;
	foreach $_ (@{$md5hash}) {
	  @pkeyval2 = ();
	  foreach $val (@pkeyval) {push @pkeyval2, shift @{$val} };
	  $ok-- && last unless $self->_dbsql_chk_check_sum($_, \@pkeyval2);
	}
      }
      else {
	$ok = $self->_dbsql_chk_check_sum($md5hash, \@pkeyval);
      }
    }
    else {
      $ok = 1;
    }

    return $self->_dbsql_write(1) if($ok);
    $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Can\'t update record(s) due to primary key cheksum mismatch').'!'});
    return 0;
  }

  $self->_add_to_output($self->{dbsql_errmsg_tmpl}, {ERRMSG => gettext('Can\'t update record(s) due to missing primary key checksum').'!'});

  return 0;
}

######################################################################

=head3 dbsql_insert

This method inserts the transmitted data into the table.  If an error
occurs, the insert statement and the DBMSs error message and number are
printed. If you don't want all or some of this information be
displayed, see C<dbsql_set_sqlerr>.
Before calling this method, you should prove that the form content is 
valid (see FormEngines C<ok> method).

=cut

######################################################################

sub dbsql_insert {
  my ($self) = @_;
  return $self->_dbsql_write(0);
}

######################################################################

=head3 dbsql_set_dbh ( DBH )

Use this function to set the internally used database handle. If you
don't call this funtion, you must set it when creating the object with
the new method.

=cut

######################################################################

sub dbsql_set_dbh {
  my ($self, $dbh) = @_;
  $self->{dbsql} = $dbh;
  if(ref($self->{dbsql}) ne 'DBI::db') {
    croak 'No valid database connection!';
  }
}

######################################################################

=head3 dbsql_set_hide_pkey ( BOOLEAN )

By default the primary key fields are represented as I<hidden> form
fields. This makes sense, because when updating records they mustn't be
changed. Sometimes, especially when inserting new records, one might
want to set them by hand. Then he should pass false (0) to this method.

Passing false to this method will also disable the primary key md5
checksum check when calling C<dbsql_update>. This means that it'll be
allowed to change the primary keys even when updating records. By
default this is not allowed for security reasons. So be carefull with
this method!

You can as well define the template by hand using C<dbsql_preconf>.

=cut

######################################################################

sub dbsql_set_hide_pkey {
  my $self = shift;
  $self->{dbsql_hide_pkey} = shift;
}

######################################################################

=head3 dbsql_set_show_value ( BOOLEAN )

When you pass a valid where clause to the new method, the contents of
the found records will be read in and displayed as defaults. In
certain situations, one might like to have the fields empty
though. Passing false (0) to this method will do it.

=cut

######################################################################

sub dbsql_set_show_value {
  my $self = shift;
  $self->{dbsql_show_value} = shift;
}

######################################################################

=head3 dbsql_set_pkey ( SCALAR|ARRAYREF|HASHREF )

Normally the primary key of an database table is
autodetected. Sometimes someone might like to define other fields as
primary key though (the primary key is important when updating
records). You can pass a fieldname or an reference to an array with
fieldnames to this method. This method should be called before
C<dbsql_conf> (for being sure, call this method as early as possible).

B<Note>: If you pass several table names to dbsql_conf, you must pass
as hash reference here, else the passed pkeys will only be used for
the first table.

=cut

######################################################################

sub dbsql_set_pkey {
  my ($self,$pkey)= @_;
  my $tbl;
  if($pkey) {
    if(ref($pkey) ne 'HASH') {
      $self->{dbsql_pkey} = $pkey;
      return 1;
    }
    foreach $tbl (keys(%{$pkey})) {
      $self->{dbsql_pkey}->{$tbl} = {} if(ref($self->{dbsql_pkey}->{$tbl}) ne 'HASH');
      $pkey->{$tbl} = [$pkey->{$tbl}] if(ref($pkey->{$tbl}) ne 'ARRAY');
      foreach $_ (@{$pkey->{$tbl}}) {
	$self->{dbsql_pkey}->{$tbl}->{"$tbl.$_"} = 1;
      }
    }
    return 1;
  }
  return 0;
}

######################################################################

=head3 dbsql_set_show_default ( BOOLEAN )

In most DBMSs, you can define a default value for each field. Normally,
if you don't submit a where clause, this value is read out by
FormEngine::DBSQL and displayed as default value in the complying form
field. One might then change the value in the form and even remove it
completly, so that undef is transmitted. This will have the effect,
that when inserting or updating records, NULL is set for this field
(and not the defined default value). This is just logical, because the
user transmitted NULL for the field.

Perhaps you better don't want to display this default value, but like
to have it set in the database if undef was submitted for the field.

Passing false (0) to this method will cause the object to not display
any database defaults and to not pass undefined (NULL) field values to
the database when executing an INSERT. So, when inserting new records
in a database table, the default values will be set instead of the
submitted NULL values.

B<Note>: When updating records, empty field values will cause passing
NULL to the database, independ of wether this method was called or
not!

=cut

######################################################################

sub dbsql_set_show_default {
  my ($self, $set) = @_;
  $set-- if($set == -254);
  $self->{dbsql_show_default} = $set;
}

######################################################################

=head3 dbsql_set_errmsg_templ ( TEMPLATENAME )

If you want to modifiy the output of the system error messages, create a
new template (e.g. copy the default and fit it to your needs) and pass
the new templates name to this method. By default I<errmsg> of the
DBSQL skin is used.

=cut

######################################################################

sub dbsql_set_errmsg_templ {
  my($self, $set) = @_;
  $self->{dbsql_errmsg_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_sqlerr ( INTEGER )

Perhaps you already read, that whenever a database error occurs, the
error message, error number and query command is printed out by
default. Sometimes you might prove displaying the sql query a security
lack. With the help of this method, you can define which information
will be printed.

Listing of the bits and their influence:

1 error number

2 error message

4 sql command

So if you pass 3 to this method the error number and message will be
printed, but not the sql command.

=cut

######################################################################

sub dbsql_set_sqlerr {
  my($self, $set) = @_;
  $self->{dbsql_sqlerr_show} = $set;
}

######################################################################

=head3 dbsql_set_sqlerr_templ ( TEMPLATENAME )

If you want to modifiy the output of the sql error messages, create a
new template (e.g. copy the default and fit it to your needs) and pass
the new templates name to this method. By default I<sqlerror> of the
DBSQL skin is used.

=cut

######################################################################

sub dbsql_set_sqlerr_templ {
  my($self, $set) = @_;
  $self->{dbsql_sqlerr_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_secret ( SECRET )

If you want to update records, you can use the C<dbsql_update> method.
That method uses the given values of the primary key to create where
conditions, so that the right records are updated. The weak point is,
that someone could corrupt the input data, so that the primary key
values are changed and the wrong records are updated. To prevent this,
for every record a extra hidden field is created which contains the
md5 sum of the primary key concatenated with a secret string. So it is
recognized if a primary key value was changed (because the newly
created md5 sum won't match the submitted md5 sum).

With this method you can set the secret string. By default it is set
to NULL, which means that calling C<dbsql_conf> will raise an
error. For security reason an update isn't allowed without a secret
string, except you pass false (0) to C<dbsql_set_hide_pkey>, which
will allow changing the primary key and so no secret string will be
needed.

Another possibilty is changing the value of C<$secret> in I<Config.pm>
and so set a valid default secret string. But be careful, someone
might just edit Config.pm and so get the secret string, whereas using
diffrent keys in your scripts is much more secure.

It is recommended that you set the read permissions of scripts, which
define secret keys, as restrictive as possible. For cgi scripts this
means, that only the webserver user (mostly I<nobody> oder
I<www-data>) must be able to read them.

=cut

######################################################################

sub dbsql_set_secret {
  my ($self,$set) = @_;
  $self->{dbsql_secret} = $set if($set);
}

######################################################################

=head3 dbsql_set_row ( BOOLEAN )

If you provided a where-condition and more than one record was found,
or you provided a number instead and it was higher than 1, then by
default it'll be used only one line per record.

With this method you can force the object to use one line per field
(0) or to use one line per record (1).

=cut

######################################################################

sub dbsql_set_row {
  my($self,$set) = @_;
  $set -- if($set == -254);
  $self->{dbsql_row} = $set;
}

######################################################################

=head3 dbsql_set_row_tmpl ( TEMPLATENAME )

By default the I<row> template is used. If you want to use another
template for placing the fields which belong to one record into one
line, pass it to this method.

=cut

######################################################################

sub dbsql_set_row_tmpl {
  my ($self,$set) = @_;
  $self->{dbsql_row_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_set_empty_tmpl ( TEMPLATENAME )

By default the I<empty> template is used. If you want to use another
template for inserting space between the records, pass it to this method.
This space is only inserted if every field takes one line.

=cut

######################################################################

sub dbsql_set_empty_tmpl {
  my ($self,$set) = @_;
  $self->{dbsql_empty_tmpl} = $set if($set);
}

######################################################################

=head3 dbsql_get_sqlerr

This method returns an array with the error number and error message
from the last database error. The sql command which causes the error
will be the third and last element.

=cut


######################################################################

sub dbsql_get_sqlerr {
  my $self = shift;
  return @{$self->{dbsql_sqlerr}};
}

######################################################################

=head3 dbsql_add_extra_sql(SQLCOMMAND, ARRAY)

This method can be used to define some more sql commands which then
will be executed for each record when C<insert> or <update> is called.

The sql command might contain '?' (question marks). These will be
replaced with the current values of the fields defined by the second
argument. The first '?' is replaced with the value of the first
element and so on.

A backslash before an question mark will prevent it from being parsed.

=cut

######################################################################

sub dbsql_add_extra_sql {
  my($self,$sql,@vars) = @_;
  push @{$self->{dbsql_extra_sql}}, [$sql, @vars] if($sql);
}

######################################################################
# INTERNAL METHODS                                                   #
######################################################################

sub _initialize_child {
  my $self = shift;
  $self->dbsql_set_dbh(shift);
  $self->{dbsql_preconf} = {};
  $self->{dbsql_where} = 1;
  $self->{dbsql_pkey} = {};
  $self->{dbsql_tables} = [];
  $self->{dbsql_fields} = {};
  $self->{dbsql_hide_pkey} = 1;
  $self->{dbsql_show_value} = 1;
  $self->{dbsql_show_default} = -254;
  $self->{dbsql_sqlerr} = [];
  $self->{dbsql_sqlerr_show} = 7;
  $self->{dbsql_sqlerr_tmpl} = 'sqlerr';
  $self->{dbsql_errmsg_tmpl} = 'errmsg';
  $self->{dbsql_row_tmpl} = 'row';
  $self->{dbsql_empty_tmpl} = 'empty';
  $self->{dbsql_secret} = $HTML::FormEngine::DBSQL::Config::secret;
  $self->{dbsql_row} = -254;
  $self->{dbsql_extra_sql} = [];
  foreach $_ (keys(%HTML::FormEngine::DBSQL::Config::skin)) {
    $self->{skins_av}->{$_} = $HTML::FormEngine::DBSQL::Config::skin{$_};
  }
  foreach $_ (keys(%HTML::FormEngine::DBSQL::Config::checks)) {
    $self->{checks}->{$_} = $HTML::FormEngine::DBSQL::Config::checks{$_};
  }
  foreach $_ (keys(%HTML::FormEngine::DBSQL::Config::confirm_skin)) {
    $self->{confirm_skin}->{$_} = $HTML::FormEngine::DBSQL::Config::confirm_skin{$_};
  }
  foreach $_ (keys(%HTML::FormEngine::DBSQL::Config::confirm_handler)) {
    $self->{confirm_handler}->{$_} = $HTML::FormEngine::DBSQL::Config::confirm_handler{$_};
  }
  $self->set_skin('DBSQL');

  $self->_dbsql_initialize_child;
}

sub _dbsql_write {
  my $self = shift;
  my $update = shift;
  my %input = %{clone($self->{input})};
  my ($sql, $value, $tbl, %fields, %values, @sql, $i, $x, %pkey, $key);
  my $while = [];
  my $res = 0;
    
  $self->_dbsql_sum_arr_elems(\%input);
  
  foreach $tbl (@{$self->{dbsql_tables}}) {
    $fields{$tbl} = [];
    foreach $_ (@{$self->{dbsql_fields}->{$tbl}}) {
      if(defined($input{$_}) and $_ =~ m/^[^\]\[]+$/) {
	if(ref($input{$_}) ne 'ARRAY') {
	  $input{$_} = [$input{$_}]
	}
	if(@{$input{$_}} > @{$while}) {
	  $while = $input{$_};
	}
	push @{$fields{$tbl}}, $_;
      }
    }
  }
  $self->{dbsql}->begin_work;
  while(@{$while}) {
    @sql = ();
    foreach $tbl (@{$self->{dbsql_tables}}) {
      %pkey = ();
      %values = ();
      $i = 0;
      foreach $_ (@{$fields{$tbl}}) {
	$value = shift @{$input{$_}};
	if(! @{$input{$_}}) {
	  delete $fields{$tbl}->[$i];
	}
	if(($self->{dbsql_show_default} > 0 or $update) || ($value or $value eq '0') and defined($value) and !$self->{dbsql_pkey}->{$tbl}->{$_} || ($value or $value eq '0')) {
	  ($key = $_) =~ s/^(.+)\.(.+)$/$2/;
	  $key = $self->{dbsql}->quote_identifier($key);
	  if($self->{dbsql_pkey}->{$tbl}->{$_}) {
	    $pkey{$key} = $self->{dbsql}->quote($value);
	  }
	  $values{$key} = (($value or $value eq '0') ? $self->{dbsql}->quote($value) : 'NULL');
	}
	#elsif($update and defined($value) and !$self->{dbsql_pkey}->{$tbl}->{$_}) {
	#  push @setdefault, $value;
	#}
	$i ++;
      }
      
      if($update) {
	push @sql, $self->_dbsql_mk_update([keys(%values)], [values(%values)], \%pkey, $tbl);
      }
      else {
	push @sql, $self->_dbsql_mk_insert([keys(%values)], [values(%values)], $tbl);
      }
    }
    foreach $_ (@{$self->{dbsql_extra_sql}}) {
      $sql = $_->[0];
      for($x=1; $x<@{$_}; $x++) {
	$sql =~ s/(?!\\)(.)\?/$1.$values{$_->[$x]}/e;
      }
      $sql =~ s/\\\?/?/g;
      push @sql, $sql;
    }
    foreach $sql (@sql) {
      if($self->{debug}) {
	print $sql, "\n";
      }
      if(! $self->{dbsql}->do($sql)) {
	$self->_dbsql_sql_error($sql);
	return 0;
      }
    }
    $res ++;
  }
  $self->{dbsql}->commit;
  return $res;
}

sub _dbsql_sum_arr_elems {
  my $self = shift;
  my $input = shift;
  my $tmp;
  my %cache;
  my $point;
  my $start = 0;
  my ($fname, $ename, $i);
  my $old;
  my %arrfields;

  foreach $_ (keys(%{$input})) {
    if(m/^([^\]\[]+)(?:\[([0-9]+)\])+$/) {
      if(ref($arrfields{$1}) ne 'ARRAY') {
	$arrfields{$1} = [];
      }
      push @{$arrfields{$1}}, $_;
      $cache{$1} = [];
    }
  }
  
  while(keys(%arrfields)) {
    foreach $fname (keys(%arrfields)) {
      if(ref($cache{$fname}->[$start]) ne 'ARRAY') {
	$cache{$fname}->[$start] = [];
      }
      $i = 0;
      foreach $ename (@{$arrfields{$fname}}) {
	$point = $cache{$fname};
	$old = $start;
	$_ = $ename;
	while(s/\[([0-9]+)\]//) {
	  $point = $point->[$old];
	  if(ref($point->[$1]) ne 'ARRAY') {
	    $point->[$1] = [];
	  }
	  $old = $1;
	}
	if(ref($input->{$ename}) eq 'ARRAY') {
	  $point->[$old] = shift @{$input->{$ename}};
	  if(! @{$input->{$ename}}) {
	    delete $arrfields{$fname}->[$i];
	  }
	}
	else {
	  $point->[$old] = $input->{$ename};
	  delete $arrfields{$fname}->[$i];
	}
	$i ++;
      }
      if(! @{$arrfields{$fname}}) {
	delete $arrfields{$fname};
      }
    }
    $start ++;
  }
  
  foreach $tmp (keys(%cache)) {
    if (@{$cache{$tmp}} > 1) {
      $input->{$tmp} = [];
      foreach $_ (@{$cache{$tmp}}) {
	push @{$input->{$tmp}}, $self->_dbsql_arr2psql($_);
      }
    }
    else {
      $input->{$tmp} = $self->_dbsql_arr2psql($cache{$tmp}->[0]);
    }
  }
}

sub _dbsql_arr2psql {
  my $self = shift;
  my $elem = shift;
  my $res = '';
  if(ref($elem) eq 'ARRAY') {
    $res = '{';
    foreach $_ (@{$elem}) {
      $res .= $self->_dbsql_arr2psql($_) . ',';
    }
    $res =~ s/,$/\}/;
  }
  else {
    $res = $elem;
  }
  return $res;
}

sub _dbsql_mk_insert {
  my ($self,$fields,$values,$table) = @_;
  if(ref($fields) eq 'ARRAY' && ref($values) eq 'ARRAY' && $table ne '') {
    return 'INSERT INTO ' . $self->{dbsql}->quote_identifier($table) . ' ('.join(', ', @{$fields}).') VALUES ('.join(', ', @{$values}).')';
  }
  else {
    return '';
  }
}

sub _dbsql_mk_update {
  my ($self,$fields,$values,$pkey,$table) = @_;
  my $sql = '';
  my $i = 0;

  if(ref($fields) eq 'ARRAY' && ref($values) eq 'ARRAY' && ref($pkey) eq 'HASH' && $table ne '') {
    $sql =  'UPDATE "' . $table . '" SET ';
    foreach $_ (@{$fields}) {
      $sql .= "$_=" . $values->[$i] . ', ';
      $i ++;
    }
    $sql =~ s/, $//;
    $sql .= ' WHERE ';
    foreach $_ (keys(%{$pkey})) {
      $sql .= "$_=" . $pkey->{$_} . ' AND ';
    }
    $sql =~ s/ AND $//;
  }
  
  return $sql;
}

sub _dbsql_makeconf {
  my ($self,$info,$tbl) = @_;
  my %res = ();
  my $handler;
  my ($tmp,$var);
  if(ref($info) eq 'HASH') {
    #($res{TITLE} = $info->{name}) =~ s/^([a-z]{1})/uc($1)/e; does raise an endless loop
    $_ = $info->{name} and s/^([a-z]{1})/uc($1)/e and $res{TITLE} =  $_;
    $info->{name} = $tbl . '.' . $info->{name} if(@{$self->{dbsql_tables}} > 1);
    $res{fname} = $info->{name};
    #if(($info->{dtyp} =~ s/^_//) && ($info->{default} =~ m/^\'\{(.*)\}\'$/)) { # {{''},{''}}
    $info->{default} =~ s/^'(.*)'$/$1/ if($info->{default});
    if($info->{default} && $info->{default} =~ m/^(\{.*,.*\})$/) {
      ($tmp) = $self->_dbsql_parse($1);
      $res{NAME} = $self->_dbsql_parse_name($info->{name},$tmp);
      if($self->{dbsql_show_default} > 0) {
	$res{VALUE} = $tmp;
      }
    }
    else {
      $res{NAME} = $info->{name};
      if(($self->{dbsql_show_default} > 0 )&& ! $self->{dbsql_pkey}->{$tbl}->{$info->{name}}) {
	$res{VALUE} = $info->{default};
      }
    }
    $info->{dtyp} =~ s/^_//; # in postgresql arrays are marked by a leading '_'
    if(ref($self->{dbsql_dthandler}->{$info->{dtyp}}) eq 'CODE') {
      $handler = $self->{dbsql_dthandler}->{$info->{dtyp}};
    }
    else {
      $handler = $self->{dbsql_dthandler}->{default};
    }
    &$handler($self, \%res, $info);
    if($self->{dbsql_pkey}->{$tbl}->{$info->{name}} && $self->{dbsql_hide_pkey}) {
      $res{templ} = 'hidden';
      $res{TITLE} = '';
    }

    if($info->{description}) {
      while($info->{description} =~ m/\G.*?([A-Za-z_]+)\=(?:;|(.*?[^\\]{1});)/g) {
	$var = $1;
	if(defined($2)) {
	  ($_ = $2) =~ s/\\;/;/g;
	}
	else {
	  $_ = '';
	}
	($res{$var}) = $self->_dbsql_parse($_);
	$res{$var} = '' unless(defined($res{$var}));
      }
    }
    
    if(($self->{dbsql_show_default} > 0) || !$info->{default} and $info->{notnull}) {
      $res{ERROR} = ($res{ERROR} ? [$res{ERROR}] : []) unless(ref($res{ERROR}) eq 'ARRAY');
      push @{$res{ERROR}}, 'not_null';
    }
    if(ref($self->{dbsql_preconf}->{$info->{name}}) eq 'HASH') {
      foreach $_ (keys(%{$self->{dbsql_preconf}->{$info->{name}}})) {
	$res{$_} = $self->{dbsql_preconf}->{$info->{name}}->{$_};
      }
    }

  }
  return \%res;
}

# transform array string-notation into perl array
sub _dbsql_parse {
  my ($self,$struc) = @_;
  return [$self->_dbsql_parse($1)] if($struc =~ m/^\{([^{}]*)\}$/);
  my $struc2 = $struc;
  while($struc2 =~ s/(\G|[^\\]{1})"(?!.*\\).*?"/$1/g){};
  if($struc2 =~ m/^[^{\,}]*$/) {
    while($struc =~ s/(^|[^\\]{1})"/$1/g){};
    $struc =~ s/\\"/"/g;
    return $struc;
  }
  my @res;
  if($struc2 =~ m/^([^"{}]*\,[^"{}]*)$/) {
    $_ = $1;
    push @res, '' if($struc =~ m/^,$/);
    push @res, split(',',$_) if($_);
    push @res, '' if($struc =~ m/,$/);
    return @res;
  }
  my ($off,$i,$lbr,$rbr,$sub,$add,$quot) = (0,0,0,0,0,0,0);
  my $tmp;
  my $last = $_ = '';
  while($i<length($struc)) {
    $last = $_;
    $_ = substr($struc, $i, 1);
    last unless defined($_);
    $i ++;
    ++ $quot && $i<length($struc) ? next : 1 if($_ eq '"' and $last ne '\\');
    unless($quot % 2) {
      ++ $lbr && $i == $off+1 ? ($add = 1) : 1 && next if($_ eq '{');
      ++ $rbr && $i<length($struc) ? next : ($sub = 1) if($_ eq '}');
      if((($_ eq ',' && ($sub = 1)) || $i == length($struc)) and $lbr == $rbr) {
	($tmp) = $self->_dbsql_parse(substr($struc,$off+=$add,$i-$off-$sub));
	$add ? (push @res, [$tmp]) : (push @res, $tmp);
	$off=$i;
	$sub = $add = 0;
	next;
      }
    }
  }
  return @res;
}

sub _dbsql_chk_check_sum {
  my($self,$md5hash,$val) = @_;
  return 1 if($md5hash eq md5_hex(join($self->{dbsql_secret}, @{$val}) . $self->{dbsql_secret}));
  return 0;
}

sub _dbsql_parse_name {
  my($self,$name,$elem) = @_;
  if(ref($elem) eq 'ARRAY') {
    my $i = 0;
    my $res = [];
    foreach $_ (@{$elem}) {
      push @{$res}, $self->_dbsql_parse_name($name."[$i]",$_);
      $i ++;
    }
    return $res;
  }
  return $name;
}

sub _dbsql_sql_error {
  my($self, $sql) = @_;
  $self->{dbsql_sqlerr} = [$self->{dbsql}->errstr, $sql, $self->{dbsql}->err];
  my %errconf = (
		 ERRNUM => $self->{dbsql_sqlerr_show} & 1 ? $self->{dbsql}->err : gettext('can\'t be displayed'),
		 ERRMSG => $self->{dbsql_sqlerr_show} & 2 ? $self->{dbsql}->errstr : gettext('can\'t be displayed'),
		 SQLSTAT => $self->{dbsql_sqlerr_show} & 4 ? $sql : gettext('can\'t be displayed')
		);
  $self->_add_to_output($self->{dbsql_sqlerr_tmpl},\%errconf);
}

sub retarref {
  my $arr = shift;
  defined($arr) ? return [$arr] : return [] if(ref($arr) ne 'ARRAY');
  return $arr;
}

######################################################################

return 1;
__END__

=head1 EXTENDING FORMENGINE::DBSQL

=head2 Add Support For Another DBMS

Please have a look at PGSQL.pm and its POD.

=head2 Write A Handler For Another Datatype

First you have to decide wether this handler will be DBMS independent
or not. Then have a look at DtHandler.pm and PGSQL::DtHandler.pm
(which is a good example for DBMS dependent handlers).

=head2 Suiting the Layout

For this task, you should create a new skin. For general information about FormEngine skins, look at the POD of FormEngine.pm and its submodules. Then also look at DBSQL::Skin.pm, the templates which are defined there are necessary for DBSQL.pm and you should at least implement replacements for them in your new skin. At last you can make your new skin the default for DBSQL.pm by editing DBSQL::Config.pm.

=head1 MORE INFORMATION

Have a look at ...

=over

=item

the POD of DBSQL::DtHandler.pm for information about writing datatype handlers.

=item

the POD of DBSQL::PGSQL.pm for information about adding support for another DBMS.

=item

DBSQL::Skin.pm for information about the DBSQL.pm specific templates.

=back

=head1 BUGS

Send bug reports to: moritz@freesources.org

Thanks!

=head1 AUTHOR

(c) 2003, Moritz Sinn. This module is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (see http://www.gnu.org/licenses/gpl.txt) as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

I am always interested in knowing how my work helps others, so if you put this module to use in any of your own code then please send me the URL. Also, if you make modifications to the module because it doesn't work the way you need, please send me a copy so that I can roll desirable changes into the main release.

Address comments, suggestions, and bug reports to moritz@freesources.org. 

=head1 SEE ALSO

HTML::FormEngine by Moritz Sinn

HTML::FormTemplate by Darren Duncan
