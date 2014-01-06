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
html_start("Greylist");

$query = "SELECT COUNT(*) AS count FROM connect";
$result = do_query($query);
$line = fetch_row($result);
?>

<? require("grey_submenu.php"); ?>

<TABLE CLASS="MAIL" WIDTH=100% CELLPADDING=1 CELLSPACING=1>
<TR><TD><STRONG>Greylisted</STRONG></TD><TD> - Messages that are waiting to pass greylisting</TD></TR>
<TR><TD><STRONG>AWL</STRONG></TD><TD> - Auto White List. These addresses or domains have passed greylisting tests and are now trusted, so won't be affected by greylisting again.</TD></TR>
<TR><TD><STRONG>White</STRONG></TD><TD> - Manually Whitelisted. These addresses or domains will never be affected by greylist tests.</TD></TR>
<TR><TD><STRONG>Grey</STRONG></TD><TD> - Manually Greylisted. These addresses or domains will always be subjected to greylist tests.</TD></TR>
</TABLE>

<?
require "grey_copyright.inc.php";
html_end();
?>
