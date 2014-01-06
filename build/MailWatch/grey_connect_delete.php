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
<TITLE>Greylisted hosts/domains, delete entry</TITLE>
<LINK REL="StyleSheet" TYPE="text/css" HREF="style.css">
<meta http-equiv="refresh" content="0;URL=grey_connect.php">
<BODY>
<TABLE WIDTH=100% HEIGHT=100%><TR VALIGN=CENTER><TD ALIGN=CENTER>

<H1>Greylisted hosts/domains, delete entry</H1>

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
?>

Entry <? print $_GET["sender_name"]; ?>@<? print $_GET["sender_domain"]; ?>[<? print $_GET["src"]; ?>] -&gt; <? print $_GET["rcpt"]; ?> deleted.<BR>

<?
$query = "DELETE FROM connect WHERE sender_name='".addslashes($_GET["sender_name"])."' AND sender_domain='".addslashes($_GET["sender_domain"])."' AND src='".addslashes($_GET["src"])."' AND rcpt='".addslashes($_GET["rcpt"])."'";
$result = do_query($query);
?>
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
