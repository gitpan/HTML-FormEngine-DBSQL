=head1 NAME

HTML::FormEngine::DBSQL::DtHandler - DBMS independent datatype handlers

=head1 GENERAL INFORMATION ABOUT DATATYPE HANDLERS

To every handler is given:

=over

=item

the object reference

=item

a reference to the fields form configuration hash

=item

a reference to an hash which contains information about the column (see FormEngine::DBSQL::PGSQL).

=over

The handler now modifies the fields configuration hash and can
therefore use information out of the column information hash (which he
mustn't modify!).

Which handler is called for which datatype is configured in Config.pm
of the used DBMS driver.

=cut

######################################################################

package HTML::FormEngine::DBSQL::DtHandler;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

######################################################################

use Locale::gettext;

######################################################################

=head1 DATATYPE HANDLERS

=head2 _dbsql_dthandle_bool

C<templ> is set to I<select>, I<Yes> or I<No> is given as options
which is internally represented as 1 and 0.

=cut

######################################################################

sub _dbsql_dthandle_bool {
  my ($self,$res) = @_;
  $res->{templ} = 'select';
  $res->{OPTION} = [gettext('Yes'),gettext('No')];
  $res->{OPT_VAL} = ['1','0'];
}

######################################################################

=head2 _dbsql_dthandle_date

C<templ> is set to I<text>, C<SIZE> and C<MAXLEN> to 10 because a
valid date value won't need more.

=cut

######################################################################

sub _dbsql_dthandle_date {
  my($self,$res) = @_;
  $res->{templ} = 'text';
  $res->{MAXLEN} = 10;
  $res->{SIZE} = 10;
}

1;

__END__

######################################################################

=head1 SEE ALSO

  HTML::FormEngine::DBSQL::PGSQL::DtHandler

=cut

######################################################################
