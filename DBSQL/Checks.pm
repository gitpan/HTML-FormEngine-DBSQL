package HTML::FormEngine::DBSQL::Checks;

use Locale::gettext;

######################################################################

=head1 NAME

HTML::FormEngine::DBSQL - collection of FormEngine::DBSQL check routines

=head1 METHODS

=head2 dbsql_unique

This method proves wether the committed field value is unique in the
tables records for that field.

When primary key values are provided, the method checks all records
except the record which belongs to the corresponding pkey. So it'll
also work when executing updates.

=cut

######################################################################

sub _dbsql_check_unique {
  my ($value,$field,$self) = @_;
  my ($table,$where, $i);
  if($field =~ m/^(.+)\..+$/) {
    $table = $1;
  }
  else {
    $table = $self->{dbsql_tables}->[0];
  }
  $i = $self->_get_var('ROWNUM',1);
  foreach $_ (keys(%{$self->{dbsql_pkey}->{$table}})) {
    $val = $self->get_input_value($_);
    $val = $val->[$i-1] if($i);
    if(!$val) {
      undef($where);
      last;
    }
    $where .= ' AND ' . $_ . ' != ' . $self->{dbsql}->quote($val);
  }
  $where = '' unless(defined($where));
  if($self->{dbsql}->selectrow_array("SELECT 1 FROM $table WHERE $field='$value'" . $where)) {
    return gettext('already exists') . '!';
  }
}

1;

__END__
