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
	$mode = $_GET["mode"];
	$csort = $_GET["csort"];
	$sort = $_GET["sort"];

	if ($sort==null || $sort=="") {
	  if ($mode == "email")
	    $sort = "sender_name";
	  else
	    $sort = "sender_domain";
	}
	$dir = "asc";
	$ndir = "desc";
	if ($sort == $csort && $_GET["order"] == "desc")
	{
		$dir = "desc";
		$ndir = "asc";
	}
if ($mode=="email") html_start("Greylist AWL - Addresses"); else html_start("Greylist AWL - Domains");

?>

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

<? require("grey_submenu.php"); ?>

<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
 <THEAD>
  <TH>Auto Whitelist <? if ($mode=="email") print "Addresses"; else print "Domains"; ?>  </TH>
 </THEAD>
</TABLE>

<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
<THEAD>
	<? if ($mode=="email") print "<TH><A HREF=\"grey_awl.php?mode=".$mode."&sort=sender_name&csort=".$sort."&order=".$ndir."\">Sender name</TH>"; ?>
	<TH><A HREF="grey_awl.php?mode=<? print $mode; ?>&sort=sender_domain&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Sender domain</A></TH>
	<TH><A HREF="grey_awl.php?mode=<? print $mode; ?>&sort=src&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Source</A></TH>
	<TH><A HREF="grey_awl.php?mode=<? print $mode; ?>&sort=first_seen&csort=<? print $sort; ?>&order=<? print $ndir; ?>">First seen</A></TH>
	<TH><A HREF="grey_awl.php?mode=<? print $mode; ?>&sort=last_seen&csort=<? print $sort; ?>&order=<? print $ndir; ?>">Last seen</A></TH>
</THEAD>

<?
	if ($mode=="email")
	{
		if ($sort == "sender_name")
		  $order = "sender_name ".$dir.", sender_domain ".$dir;
		else if ($sort == "sender_domain")
		  $order = "sender_domain ".$dir.", sender_name ".$dir;
		else
		  $order = $sort." ".$dir;
		$query = "SELECT sender_name, sender_domain, src, first_seen, last_seen FROM from_awl ORDER BY ".$order;
	}
	else
	{
		$order = $sort." ".$dir;
		$query = "SELECT sender_domain, src, first_seen, last_seen FROM domain_awl ORDER BY ".$order;
	}


	$result = do_query($query);
	while($line = fetch_row($result))
	{
		?><TR><?
		if ($mode=="email") print "<TD>".$line["sender_name"]."</TD>";
		?><TD><? print $line["sender_domain"]; ?></TD><?
		?><TD><? print $line["src"]; ?></TD><?
		?><TD><? print $line["first_seen"]; ?></TD><?
		?><TD><? print $line["last_seen"]; ?></TD><?
		?><TD><A HREF="grey_awl_delete.php?mode=<?
			if ($mode=="email")
				print "email&sender_name=".enchttp($line["sender_name"]);
			else
				print "domains";
			?>&sender_domain=<? print enchttp($line["sender_domain"]);
			?>&src=<? print $line["src"]; ?>">Delete</A></TD><?
		?></TR><?
		print "\n";
	}
?>
</TABLE>
<BR>
<A HREF="grey_awl_delete_undef.php?mode=<? print $_GET["mode"]; ?>">Delete '-undef-' entries</A><BR>
<BR>
<H3>Add to whitelist</H3>
<FORM ACTION="grey_awl_add.php?mode=<? print $_GET["mode"]; ?>" METHOD="POST">
<TABLE>
<? if ($mode == "email") { ?>
<TR><TD>Sender name:</TD><TD><INPUT TYPE="TEXT" NAME="sender_name" SIZE=64 WIDTH=64></TD></TR>
<? } ?>
<TR><TD>Sender domain:</TD><TD><INPUT TYPE="TEXT" NAME="sender_domain" SIZE=64 WIDTH=255></TD></TR>
<TR><TD>Source (class c or d):</TD><TD><INPUT TYPE="TEXT" NAME="src" SIZE=15 WIDTH=15></TD></TR>
<TR><TD></TD><TD><INPUT TYPE="SUBMIT" VALUE="Add"></TD></TR>
</TABLE>
</FORM>

<?
require "grey_copyright.inc.php";
html_end();
?>


