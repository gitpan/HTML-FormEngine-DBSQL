package HTML::FormEngine::DBSQL::Config;
require HTML::FormEngine::DBSQL::Skin;

# you shouldn't set this variable to a valid value!
# leave it as it is except you know what you're doing.
$secret = ''; 

$skin{DBSQL} = \%HTML::FormEngine::DBSQL::Skin::skin;

1;
