=head1 NAME

HTML::FormEngine::DBSQL::PGSQL - PostgreSQL driver for FormEngine::DBSQL

=head1 REQUIREMENTS

You need to execute the following command in your PostgreSQL database:

CREATE VIEW "column_info" AS SELECT relname, attname, atttypmod, attnotnull, typname, adsrc, description FROM ((((pg_class LEFT JOIN pg_attribute ON ((pg_class.relfilenode = pg_attribute.attrelid))) LEFT JOIN pg_type ON ((atttypid = pg_type.oid))) LEFT JOIN pg_attrdef ON (((attrelid = pg_attrdef.adrelid) AND (attnum = pg_attrdef.adnum)))) LEFT JOIN pg_description ON (((attrelid = pg_description.objoid) AND (attnum = pg_description.objsubid)))) WHERE (((((((attname <> 'tableoid'::name) AND (attname <> 'oid'::name)) AND (attname <> 'ctid'::name)) AND (attname <> 'xmax'::name)) AND (attname <> 'xmin'::name)) AND (attname <> 'cmax'::name)) AND (attname <> 'cmin'::name)) ORDER BY attnum;

This will create a view called I<column_info>, it is needed to extract information about the table columns.

=cut

######################################################################

package HTML::FormEngine::DBSQL::PGSQL;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

use strict;
use Clone qw(clone);
use Hash::Merge qw(merge);

use HTML::FormEngine::DBSQL;
use HTML::FormEngine::DBSQL::PGSQL::Config;

use vars qw(@ISA);

@ISA = qw(HTML::FormEngine::DBSQL);

######################################################################

=head1 _dbsql_initialize_child

This method is called for every child of FormEngine::DBSQL. A DBMS
driver has to load the datatype handler configuration from its
Config.pm here!

=cut

######################################################################

sub _dbsql_initialize_child {
  my $self = shift;
  $self->{dbsql_dthandler} = \%HTML::FormEngine::DBSQL::PGSQL::Config::dbsql_dthandler;
}

######################################################################

=head1 get_tbl_struct ( TABLENAME, ARRAYREF, HASHREF )

This method is called by the C<dbsql_conf> method of FormEngine::DBSQL
to get information about the columns of the specified database
table. Every DBMS driver has to implement it!

The ARRAYREF points to the list of fieldnames, the HASHREF points to a
hash which keys are fieldnames too, these fieldnames must be ignored.

This method must return a reference to an array which must contain an
hash reference for every column, except those in the committed
HASHREF.  These referenced hashes must support the following
information:

=over

=item

I<name> - the columns name

=item

I<notnull> - 1 if the column has the NOT NULL attribute, 0 if not

=item

I<dtyp> - the name of the columns datatype

=item

I<default> - the columns default value

=item

I<description> - the columns comment

=back

The hash might also support DBMS specific information which then is only used by the DBMS specific datatype handlers. For PostgreSQL this is:

=over

I<dtypmod> - datatype modification information, this is used by PostgreSQLs string handler.

=back

=cut

######################################################################

sub get_tbl_struct {
  my ($self, $tbl, $fields, $donotuse) = @_;
  my ($sth, $field, @struct);
  $sth = $self->{dbsql}->prepare('SELECT * FROM column_info WHERE relname=\'' . $tbl . '\' AND attname LIKE ?');
  foreach $field (@{$fields}) {
    if(defined($field) && ! $donotuse->{$field}) {
      $sth->execute($field);
      while($_ = $sth->fetchrow_hashref) {
	if(! $donotuse->{$_->{attname}}) {
	  push @struct, {
			 'name' => $_->{attname},
			 'notnull' => $_->{attnotnull},
			 'dtyp' => $_->{typname},
			 'default' => $_->{adsrc},
			 'description' => $_->{description},
			 'dtypmod' => $_->{atttypmod}
			};
	}
      }
    }
  }
  return \@struct;
}

1;
