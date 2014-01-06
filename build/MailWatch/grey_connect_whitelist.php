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

?>
<HTML>
<HEAD>
<TITLE>Greylisted hosts/domains, move to whitelist</TITLE>
<LINK REL="StyleSheet" TYPE="text/css" HREF="style.css">
<meta http-equiv="refresh" content="0;URL=grey_connect.php">
<BODY>
<TABLE WIDTH=100% HEIGHT=100%><TR VALIGN=CENTER><TD ALIGN=CENTER>

<H1>Greylisted hosts/domains, move to whitelist</H1>

<?
# mysql> describe connect;
# +---------------+---------------+------+-----+---------+-------+
# | Field         | Type          | Null | Key | Default | Extra |
# +---------------+---------------+------+-----+---------+-------+
# | sender_name   | varchar(64)   |      |     |         |       |
# | sender_domain | varchar(255)  |      |     |         |       |
# | src           | varchar(39)   |      | MUL |         |       |
# | rcpt          | varchar(255)  |      |     |         |       |
# | first_seen    | timestamp(14) | YES  | MUL | NULL    |       |
# +---------------+---------------+------+-----+---------+-------+
# 5 rows in set (0.00 sec)

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
?>

<?
# fetch first_seen
$query = "SELECT first_seen FROM connect WHERE sender_name='".addslashes($_GET["sender_name"])."' AND sender_domain='".addslashes($_GET["sender_domain"])."' AND src='".addslashes($_GET["src"])."' AND rcpt='".addslashes($_GET["rcpt"])."'";
$result = do_query($query);
$line = fetch_row($result);

# add to 'from_awl'
$query = "INSERT INTO from_awl(sender_name, sender_domain, src, first_seen, last_seen) VALUES('".
		addslashes($_GET["sender_name"])."', '".
		addslashes($_GET["sender_domain"])."', '".
		addslashes($_GET["src"])."', '".
		$line["first_seen"]."', '".
		$line["first_seen"]."')";
$result = do_query($query);

# and remove from 'connect'
$query = "DELETE FROM connect WHERE sender_name='".addslashes($_GET["sender_name"])."' AND sender_domain='".addslashes($_GET["sender_domain"])."' AND src='".addslashes($_GET["src"])."' AND rcpt='".addslashes($_GET["rcpt"])."'";
$result = do_query($query);
?>

Entry <? print $_GET["sender_name"]; ?>@<? print $_GET["sender_domain"]; ?>[<? print $_GET["src"]; ?>] -&gt; <? print $_GET["rcpt"]; ?> moved to whitelist.<BR>
<BR>
<BR>

<A HREF="grey_connect.php">Greylisted hosts/domains menu</A><BR>
<A HREF="grey.php">Main menu</A><BR>

<BR>
<BR>

</TD></TR>

<? require "grey_copyright.inc.php" ?>

</TABLE>
</BODY>
</HTML>
