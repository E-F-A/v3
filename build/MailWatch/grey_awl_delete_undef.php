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
require "grey_tools.inc.php";

	if ($_GET["mode"] == "email")
		$mode = 1;
	else
		$mode = 0;
?>
<HTML>
<HEAD>
<TITLE>Whitelisted <? if ($mode) print "e-mail addresses"; else print "domains"; ?>, delete '-undef-' entries</TITLE>
<LINK REL="StyleSheet" TYPE="text/css" HREF="style.css">
<meta http-equiv="refresh" content="0;URL=grey_awl.php?mode=<? print $_GET["mode"]; ?>">
<BODY>
<TABLE WIDTH=100% HEIGHT=100%><TR VALIGN=CENTER><TD ALIGN=CENTER>

<H1>Whitelisted <? if ($mode) print "e-mail addresses"; else print "domains"; ?>, delete '-undef-' entries</H1>

<?
# mysql> describe from_awl;
# +---------------+---------------+------+-----+----------------+-------+
# | Field         | Type          | Null | Key | Default        | Extra |
# +---------------+---------------+------+-----+----------------+-------+
# | sender_name   | varchar(64)   |      | PRI |                |       |
# | sender_domain | varchar(255)  |      | PRI |                |       |
# | src           | varchar(39)   |      | PRI |                |       |
# | first_seen    | timestamp(14) | YES  |     | NULL           |       |
# | last_seen     | timestamp(14) | YES  | MUL | 00000000000000 |       |
# +---------------+---------------+------+-----+----------------+-------+
# 5 rows in set (0.00 sec)

# mysql> describe domain_awl;
# +---------------+---------------+------+-----+----------------+-------+
# | Field         | Type          | Null | Key | Default        | Extra |
# +---------------+---------------+------+-----+----------------+-------+
# | sender_domain | varchar(255)  |      | PRI |                |       |
# | src           | varchar(39)   |      | PRI |                |       |
# | first_seen    | timestamp(14) | YES  |     | NULL           |       |
# | last_seen     | timestamp(14) | YES  | MUL | 00000000000000 |       |
# +---------------+---------------+------+-----+----------------+-------+
# 4 rows in set (0.00 sec)
?>

<?
	if ($mode)
		$query = "DELETE FROM from_awl WHERE sender_name='-undef-' AND sender_domain='-undef-'";
	else
		$query = "DELETE FROM domain_awl WHERE sender_domain='-undef-'";
	$result = do_query($query);
?>
'-undef-' entries deleted.
<BR>
<BR>

<A HREF="grey_awl.php?mode=<? print $_GET["mode"]; ?>">Whitelisted <? if ($mode) print "e-mail addresses"; else print "domains"; ?> menu</A><BR>
<A HREF="grey.php">Main menu</A><BR>

<BR>
<BR>

</TD></TR>

<? require "grey_copyright.inc.php" ?>

</TABLE>
</BODY>
</HTML>
