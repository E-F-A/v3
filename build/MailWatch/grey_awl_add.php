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
<TITLE>Whitelisted <? if ($mode) print "e-mail addresses"; else print "domains"; ?>, add</TITLE>
<LINK REL="StyleSheet" TYPE="text/css" HREF="style.css">
<meta http-equiv="refresh" content="0;URL=awl.php?mode=<? print $_GET["mode"]; ?>">
<BODY>
<TABLE WIDTH=100% HEIGHT=100%><TR VALIGN=CENTER><TD ALIGN=CENTER>

<H1>Whitelisted <? if ($mode) print "e-mail addresses"; else print "domains"; ?>, add</H1>

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
	{
		$query = "INSERT INTO from_awl(sender_name, sender_domain, src, first_seen, last_seen) VALUES('".addslashes($_POST["sender_name"])."', '".addslashes($_POST["sender_domain"])."', '".addslashes($_POST["src"])."', now(), now())";
		print "e-Mail address ".$_POST["sender_name"]."@".$_POST["sender_domain"]." (".$_POST["src"].") added.<BR>\n";
	}
	else
	{
		$query = "INSERT INTO domain_awl(sender_domain, src, first_seen, last_seen) VALUES('".addslashes($_POST["sender_domain"])."', '".addslashes($_POST["src"])."', now(), now())";
		print "Domain ".$_POST["sender_domain"]." (".$_POST["src"].") added.<BR>\n";
	}
#	echo $query;
	do_query($query);
?>


<BR>
<BR>

<A HREF="awl.php?mode=<? print $_GET["mode"]; ?>">Whitelist menu</A><BR>
<A HREF="index.php">Main menu</A><BR>

<BR>
<BR>

</TD></TR>

<? require "copyright.inc.php" ?>

</TABLE>
</BODY>
</HTML>
