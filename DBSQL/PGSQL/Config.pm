package HTML::FormEngine::DBSQL::PGSQL::Config;

use HTML::FormEngine::DBSQL::DtHandler;
use HTML::FormEngine::DBSQL::PGSQL::DtHandler;

$dbsql_dthandler{default} = \&HTML::FormEngine::DBSQL::PGSQL::DtHandler::_dbsql_pgsql_dthandle_string;
$dbsql_dthandler{bool} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_bool;
$dbsql_dthandler{date} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_date;
$dbsql_dthandler{text} = \&HTML::FormEngine::DBSQL::DtHandler::_dbsql_dthandle_text;

1;
