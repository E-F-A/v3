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
html_start("Greylist Waiting");
require "grey_tools.inc.php";
?>

<? require("grey_submenu.php"); ?>

<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
 <THEAD>
  <TH>Greylist Waiting</TH>
 </THEAD>
</TABLE>

<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
<THEAD>
	<TH><A HREF="grey_connect.php?sort=sender_name&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Sender name</A></TH>
	<TH><A HREF="grey_connect.php?sort=sender_domain&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Sender domain</A></TH>
	<TH><A HREF="grey_connect.php?sort=src&csort=<? print $sort; ?>&order=<? print $ndir; ?>">IP address</A></TH>
	<TH><A HREF="grey_connect.php?sort=rcpt&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Recipient</A></TH>
	<TH><A HREF="grey_connect.php?sort=first_seen&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Seen at</A></TH>
</THEAD>

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

<?
	$csort = $_GET["csort"];
	$sort = $_GET["sort"];

	if ($sort==null || $sort=="")
	  $sort = "sender_name";

	$dir = "asc";
	$ndir = "desc";
	if ($sort == $csort && $_GET["order"] == "desc")
	{
		$dir = "desc";
		$ndir = "asc";
	}
?>

<?
	if ($sort == "sender_name")
	  $order = "sender_name ".$dir.", sender_domain ".$dir;
	else if ($sort == "sender_domain")
	  $order = "sender_domain ".$dir.", sender_name ".$dir;
	else
	  $order = $sort." ".$dir;
	$query = "SELECT sender_name, sender_domain, src, rcpt, first_seen FROM connect ORDER BY ".$order;
	$result = do_query($query);
	while($line = fetch_row($result))
	{
		?><TR><?
		?><TD><? print $line["sender_name"]; ?></TD><?
		?><TD><? print $line["sender_domain"]; ?></TD><?
		?><TD><? print $line["src"]; ?></TD><?
		?><TD><? print $line["rcpt"]; ?></TD><?
		?><TD><? print $line["first_seen"]; ?></TD><?
		?><TD><A HREF="grey_connect_delete.php?sender_name=<? print enchttp($line["sender_name"]); ?>&sender_domain=<? print enchttp($line["sender_domain"]); ?>&src=<? print enchttp($line["src"]); ?>&rcpt=<? print enchttp($line["rcpt"]); ?>">Forget</A></TD><?
		?><TD><A HREF="grey_connect_whitelist.php?sender_name=<? print enchttp($line["sender_name"]); ?>&sender_domain=<? print enchttp($line["sender_domain"]); ?>&src=<? print enchttp($line["src"]); ?>&rcpt=<? print enchttp($line["rcpt"]); ?>">Move to white list</A></TD><?
		?></TR><?
		print "\n";
	}
?>
</TABLE>
<BR>
<BR>

<H3>Delete entries older than...</H3>
<FORM ACTION="grey_connect_purge.php" METHOD="POST">
<TABLE>
<TR>
<TD WIDTH=4>YYYY</TD>
<TD WIDTH=4>MM</TD>
<TD WIDTH=4>DDD</TD>
<TD WIDTH=4>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
<TD WIDTH=4>hh</TD>
<TD WIDTH=4>mm</TD>
<TD WIDTH=4>ss</TD>
</TR>
<TR>
<TD><INPUT TYPE="VALUE" VALUE="2007" NAME="year" WIDTH=4 SIZE=4>-</TD>
<TD><INPUT TYPE="VALUE" VALUE="04" NAME="month" WIDTH=4 SIZE=4>-</TD>
<TD><INPUT TYPE="VALUE" VALUE="01" NAME="day" WIDTH=4 SIZE=4> </TD>
<TD WIDTH=4>&nbsp;&nbsp;&nbsp;&nbsp;</TD>
<TD><INPUT TYPE="VALUE" VALUE="00" NAME="hour" WIDTH=4 SIZE=4>:</TD>
<TD><INPUT TYPE="VALUE" VALUE="00" NAME="minute" WIDTH=4 SIZE=4>:</TD>
<TD><INPUT TYPE="VALUE" VALUE="00" NAME="seconds" WIDTH=4 SIZE=4></TD>
</TR>
</TABLE>
<INPUT TYPE="SUBMIT" VALUE="Delete">
</FORM>
</TD></TR>
</TABLE>
</BODY>
</HTML>

<?
require "grey_copyright.inc.php";
html_end();
?>
