package HTML::FormEngine::DBSQL::Skin;

# inherits from default skin
%skin = %HTML::FormEngine::Skin::skin;

$skin{body} = '
<td colspan=3>
<table border=0 summary=""><~
<tr><&TEMPL&></tr>~TEMPL~>
</table>
</td>
';
$skin{row} = '
<td valign="top"><&ROWNUM&>. </td><~
<td>
<table border=0 cellspacing=0 cellpadding=0>
<tr><&TEMPL&></tr>
</table>
</td>~TEMPL~>';

$skin{title} = '
  <td valign="top"></td><~
  <td align="center"><&TITLE&></td>~TITLE~>';

$skin{errmsg} = '
   <td colspan=3 style="color:#FF0000">
     <&gettext Error&>:<br>
     <&ERRMSG&>
   </td>
';

$skin{sqlerr} = '
   <td colspan=3 style="color:#FF0000">
     <&gettext SQL failure&>:<br>
     <i><&ERRMSG&></i><br>
     <&gettext Error_number&>: <i><&ERRNUM&></i><br>
     <&gettext Statement_was&>:<br>
     <i><&SQLSTAT&></i>
   </td>
';

$skin{empty} = '
   <td colspan=3>&nbsp;</td>
';
1;
