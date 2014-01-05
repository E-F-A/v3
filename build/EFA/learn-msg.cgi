#!/usr/bin/perl
# +--------------------------------------------------------------------+
# EFA learn spam message script version 20140105
# This script is an modification of the previous ESVA learn-msg.cgi
# +--------------------------------------------------------------------+
# Copyright (C) 2013  http://www.efa-project.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# +--------------------------------------------------------------------+

use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
print "Content-type: text/html \n\n";

$query = new CGI;
$salearn = "/usr/local/bin/sa-learn --spam";
$id = param("id");

if ($id =~ /^[A-F0-9]{10}.[A-F0-9]{5}$/){
  $msgtolearn = `find /var/spool/MailScanner/quarantine/ -name $id`;

  print "$msgtolearn";
  open(MAIL, "|$salearn $msgtolearn") or die "Cannot open $salearn: $!";
  close(MAIL);

  # redirect to success page
  print "<meta http-equiv=\"refresh\" content=\"0;URL=/learned.html\">";
}else{
  die "Error in id syntax";
}