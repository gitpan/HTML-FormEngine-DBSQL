package HTML::FormEngine::DBSQL::Config;
require HTML::FormEngine::DBSQL::Skin;
require HTML::FormEngine::DBSQL::Checks;

# you shouldn't set this variable to a valid value!
# leave it as it is except you know what you're doing.
$secret = ''; 

$skin{DBSQL} = \%HTML::FormEngine::DBSQL::Skin::skin;

$checks{dbsql_unique} = \&HTML::FormEngine::DBSQL::Checks::_dbsql_check_unique;

$confirm_skin{sqlerr} = 'sqlerr';
$confirm_skin{errmsg} = 'errmsg';
$confirm_skin{title} = 'title';
$confirm_skin{empty} = 'empty';
$confirm_skin{row} = 'row';
$confirm_skin{body} = 'body';

1;
