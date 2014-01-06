<?
/*
 ESVA
 Copyright (C) 2007  Andrew MacLachlan (andy.mac@global-domination.org)

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

require("functions.php");
authenticate('A');
require "grey_opt_in_out_helpers.inc.php";
html_start("Greylist ".$title)
?>

<? require("grey_submenu.php"); ?>


<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
	<THEAD>
		<TH><? print $title; ?></TH>
	</THEAD>
</TABLE>


<?
# mysql> describe optout_domain;
# +--------+--------------+------+-----+---------+-------+
# | Field  | Type         | Null | Key | Default | Extra |
# +--------+--------------+------+-----+---------+-------+
# | domain | varchar(255) |      | PRI |         |       |
# +--------+--------------+------+-----+---------+-------+
# 1 row in set (0.00 sec)
?>

<TABLE>
<TR><TD><B><? print $heading; ?></B></TD><TD></TD></TR>
<?
	$query = "SELECT ".$field." FROM ".$table." ORDER BY ".$field;
	$result = do_query($query);
	while($line = fetch_row($result))
	{
		?><TR><TD><? print $line[$field]; ?></TD><TD><A HREF="grey_opt_in_out_delete.php?direction=<? print $_GET["direction"]; ?>&what=<? print $_GET["what"]; ?>&field=<? print $line[$field]; ?>">delete</A></TD></TR><?
	}
?>
</TABLE>
<FORM ACTION="grey_opt_in_out_add.php?direction=<? print $_GET["direction"]; ?>&what=<? print $_GET["what"]; ?>" METHOD="POST">
<INPUT TYPE="TEXT" NAME="<? print $field; ?>" SIZE=40 WIDTH=255>
<INPUT TYPE="SUBMIT" VALUE="Add">
</FORM>
<?
require "grey_copyright.inc.php";
html_end();
?>
