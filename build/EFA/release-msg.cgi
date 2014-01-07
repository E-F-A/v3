#!/usr/bin/perl
# +--------------------------------------------------------------------+
# EFA release spam message script version 20140105
# This script is an modification of the previous ESVA release-msg.cgi
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
$id = param("id");
$datenumber = param("datenumber");
$to = param("to");

# Check if the variables contain data if one of them is not we die and not even check the syntax..
if ($id eq "" ){
  die "Error variable is emtpy"
}
if ($datenumber eq "" ){
  die "Error variable is emtpy"
}
if ($to eq "" ){
  die "Error variable is emtpy"
}

# Note! this most likely fixes the security flaw, but it will also break releasing of messages with multiple 'to' addresses (this already was an issue because of the space between the mail adresses)
# all 3 variables should check out ok.

# First check the ID variable
if ($id =~ /^[A-F0-9]{11}\.[A-F0-9]{5}$/){
  # Then check the to variable
  if ($to =~ /^[\w-]+(?:\.[\w-]+)*@(?:[\w-]+\.)+[a-zA-Z]{2,7}$/){
    # Then check the datenumber variable
    if ($datenumber =~ /^([2-9]\d{3}((0[1-9]|1[012])(0[1-9]|1\d|2[0-8])|(0[13456789]|1[012])(29|30)|(0[13578]|1[02])31)|(([2-9]\d)(0[48]|[2468][048]|[13579][26])|(([2468][048]|[3579][26])00))0229)$/){
      # All are ok
      $sendmail = "/usr/sbin/sendmail.postfix";
      $msgtorelease = "/var/spool/MailScanner/quarantine/$datenumber/spam/$id";
      open(MAIL, "|$sendmail $to <$msgtorelease") or die "Cannot open $sendmail: $!";
      close(MAIL);

      # redirect to success page
      print "<meta http-equiv=\"refresh\" content=\"0;URL=/released.html\">";
    } else {
      die "Error in datanumber syntax";
    }
  } else {
    die "Error in to syntax";
  }
} else {
  die "Error in id syntax";
}
