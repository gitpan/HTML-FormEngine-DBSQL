=head1 NAME

HTML::FormEngine::DBSQL::PGSQL::DtHandler - PostgreSQL specific datatype handlers

=cut

######################################################################

package HTML::FormEngine::DBSQL::PGSQL::DtHandler;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information

######################################################################

=head1 DATATYPE HANDLERS

=head2 _dbsql_pgsql_dthandle_string

Sets C<templ> to I<text> and tries to determine the maximal length
which is then assigned to C<MAXLEN>. If then C<MAXLEN> should be lower
than the default size, C<SIZE> is set to C<MAXLEN>.

=cut

######################################################################

sub _dbsql_pgsql_dthandle_string {
  my ($self,$res,$info) = @_;
  $res->{templ} = 'text';
  if($info->{dtypmod} =~ m/^[0-9]+$/ && $info->{dtypmod} > 4) {
    $res->{MAXLEN} = $info->{dtypmod} -4;
    if(! defined($self->{default}->{text}->{SIZE}) || ($res->{MAXLEN} < $self->{default}->{text}->{SIZE})) {
      $res->{SIZE} = $res->{MAXLEN};
    }
  }
}

1;

__END__

######################################################################

=head1 SEE ALSO

  HTML::FormEngine::DBSQL::DtHandler

=cut

######################################################################
