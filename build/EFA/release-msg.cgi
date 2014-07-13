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
use DBI;
print "Content-type: text/html \n\n";

$query = new CGI;
$id = param("id");
$datenumber = param("datenumber");
$token = param("token");

$db_name = "efa";
$db_host = "localhost";
$db_user = "efa";
open(FILE, '/etc/EFA-Config');
#Do not read in entire file at once for better security
while ($line = <FILE>) {
  if ($line =~ /^EFASQLPWD/) {
    $db_pass = $line;
    $db_pass =~ s/^EFASQLPWD://;
	$db_pass =~ s/\n//;
	break;
  }
}
close (FILE);

# Check if the variables contain data if one of them is not we die and not even check the syntax..
if ($id eq "" ){
  die "Error variable is empty"
}
if ($datenumber eq "" ){
  die "Error variable is empty"
}
if ($token eq "" ){
  die "Error variable is empty"
}

# First check the ID variable
if ($id =~ /^[A-F0-9]{10}\.[A-F0-9]{5}|[A-F0-9]{11}\.[A-F0-9]{5}$/){
  if ($datenumber =~ /^([2-9]\d{3}((0[1-9]|1[012])(0[1-9]|1\d|2[0-8])|(0[13456789]|1[012])(29|30)|(0[13578]|1[02])31)|(([2-9]\d)(0[48]|[2468][048]|[13579][26])|(([2468][048]|[3579][26])00))0229)$/){
    if ($token =~ /^[0-9a-zA-Z]{32}$/){
      # All are ok
      
      # Verify if token is present in db
      $dbh = DBI->connect("DBI:mysql:database=$db_name;host=$db_host",
         $db_user, $db_pass,
         {PrintError => 0});
      
      if (!$dbh) { die "Error connecting to database" }
      
      $sql = "SELECT token from tokens WHERE token=\"$token\"";
      $sth = $dbh->prepare($sql);
      $sth->execute;
      @results = $sth->fetchrow;
      if (!$results[0]) { 
        $sth->finish();
        $dbh->disconnect();  
 
        # redirect to failure page
        print "<meta http-equiv=\"refresh\" content=\"0;URL=/notreleased.html\">";
      } else {

        $sendmail = "/usr/sbin/sendmail.postfix";
        $msgtorelease = "/var/spool/MailScanner/quarantine/$datenumber/spam/$id";
        open(MAIL, "|$sendmail -t <$msgtorelease") or die "Cannot open $sendmail: $!";
        close(MAIL);

        # Remove token from db after release
        $sql = "DELETE from tokens WHERE token=\"$token\"";
        $sth = $dbh->prepare($sql);
        $sth->execute;
     
        $sth->finish();
        $dbh->disconnect();  
 
        # redirect to success page
        print "<meta http-equiv=\"refresh\" content=\"0;URL=/released.html\">";
      }
    } else {
      die "Error in token syntax";
    }
  } else {
    die "Error in datanumber syntax";
  }
} else {
  die "Error in id syntax";
}
