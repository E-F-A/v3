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


	$err = 0;
	if ($_POST["year"] < 2000 || $_POST["year"] > 9999)
		$err = 1;
	else if ($_POST["month"] < 1 || $_POST["month"] > 12)
		$err = 1;
	else if ($_POST["day"] < 1 || $_POST["day"] > 31)
		$err = 1;
	else if ($_POST["hour"] < 0 || $_POST["hour"] > 23)
		$err = 1;
	else if ($_POST["minute"] < 0 || $_POST["minute"] > 59)
		$err = 1;
	else if ($_POST["seconds"] < 0 || $_POST["seconds"] > 60) # indeed, 60
		$err = 1;
?>
<HTML>
<HEAD>
<TITLE>Greylisted hosts/domains, delete old entries</TITLE>
<LINK REL="StyleSheet" TYPE="text/css" HREF="style.css">
<meta http-equiv="refresh" content="0;URL=grey_connect.php">
<BODY>
<TABLE WIDTH=100% HEIGHT=100%><TR VALIGN=CENTER><TD ALIGN=CENTER>

<H1>Greylisted hosts/domains, delete old entries</H1>

<?
	if ($err)
	{
		print "Aborted: invalid date.";
		exit;
	}

	$query = "DELETE FROM connect WHERE first_seen < ".$_POST["year"].substr("00".$_POST["month"], -2, 2).substr("00".$_POST["day"], -2, 2).substr("00".$_POST["hour"], -2, 2).substr("00".$_POST["minute"], -2, 2).substr("00".$_POST["seconds"], -2, 2);
	do_query($query);
?>
Entries deleted.
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
