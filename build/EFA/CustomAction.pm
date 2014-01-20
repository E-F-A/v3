#
# CustomAction.pm 
# # Version 20140119
# # +--------------------------------------------------------------------+
# # Copyright (C) 2012~2013  http://www.efa-project.org
# #
# # This program is free software: you can redistribute it and/or modify
# # it under the terms of the GNU General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.
# #
# # This program is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# # GNU General Public License for more details.
# #
# # You should have received a copy of the GNU General Public License
# # along with this program.  If not, see <http://www.gnu.org/licenses/>.
# # +--------------------------------------------------------------------+

package MailScanner::CustomConfig;

use strict 'vars';
use strict 'refs';
no  strict 'subs'; # Allow bare words for parameter %'s

use vars qw($VERSION);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.0 $, 10;

use DBI;

# Todo: trim back libraries
use DirHandle;
use Time::localtime qw/ctime/;
use Time::HiRes qw/time/;
use MIME::Parser;
use MIME::Decoder::UU;
use MIME::Decoder::BinHex;
use MIME::WordDecoder;
use POSIX qw(:signal_h setsid);
use HTML::TokeParser;
use HTML::Parser;
use Archive::Zip qw( :ERROR_CODES );
use Filesys::Df;
use Digest::MD5;
use OLE::Storage_Lite;
use Fcntl;
use File::Path;
use File::Temp;
use MailScanner::FileInto;

#
# CustomAction for EFA Token Generation
#
sub CustomAction {
  my($dbh, $sth, $sql);
  my($message) = @_;
  my($db_name) = 'efa';
  my($db_host) = 'localhost';
  my($db_user) = 'root';
  my($db_pass) = 'EfaPr0j3ct';
  
  # Connect to the database
  $dbh = DBI->connect("DBI:mysql:database=$db_name;host=$db_host",
                      $db_user, $db_pass,
                      {PrintError => 0}); 

  # Check if connection was successfull - if it isn't
  # then generate a warning and continue processing.
  if (!$dbh) {
   MailScanner::Log::WarnLog("Unable to initialise database connection: %s", $DBI::errstr);
   return;
  }

  # Generate a new token
  my($token) = randomtoken();

  # Get today's date
  my($datestamp) = `date +%Y-%m-%d`;

  $sql = "INSERT INTO tokens (token, datestamp) VALUES ('$token', '$datestamp')";
  $sth = $dbh->prepare($sql);
  $sth->execute;

  # Add Token to $message
  $message->{token} = $token;

  # Notify user 
  HandleSpamNotify($message);

  # Close connections  
  $sth->finish();
  $dbh->disconnect();

  return 0; 
}

# +---------------------------------------------------+
# # Function to create a random 32 char token
# # +---------------------------------------------------+
sub randomtoken {
   my($token) = `date | md5sum | tr -cd '[:alnum:]'`;
   return $token;
 }
# +---------------------------------------------------+

# Code borrowed from Messages.pm and modified for use with EFA
#
# We want to send a message to the recipient saying that their spam
# mail has not been delivered.
# Send a message to the recipients which has the local postmaster as
# the sender.
sub HandleSpamNotify {
  my($this) = @_; 
  my($from,$to,$subject,$date,$spamreport,$hostname,$day,$month,$year);
  my($emailmsg, $line, $messagefh, $filename, $localpostmaster, $id);
  my($postmastername);
  my($token);

  $from = $this->{from};

  # Don't ever send a message to "" or "<>"
  return if $from eq "" || $from eq "<>";

  # Do we want to send the sender a warning at all?
  # If nosenderprecedence is set to non-blank and contains this
  # message precedence header, then just return.
  my(@preclist, $prec, $precedence, $header);
  @preclist = split(" ",
                  lc(MailScanner::Config::Value('nosenderprecedence', $this)));
  $precedence = "";
  foreach $header (@{$this->{headers}}) {
    $precedence = lc($1) if $header =~ /^precedence:\s+(\S+)/i;
  }
  if (@preclist && $precedence ne "") {
    foreach $prec (@preclist) {
      if ($precedence eq $prec) {
        MailScanner::Log::InfoLog("Skipping sender of precedence %s",
                                  $precedence);
        return;
      }
    }
  }

  # Setup other variables they can use in the message template
  $id = $this->{id};
  $localpostmaster = MailScanner::Config::Value('localpostmaster', $this);
  $postmastername  = MailScanner::Config::LanguageValue($this, 'mailscanner');
  $hostname = MailScanner::Config::Value('hostname', $this);
  $subject = $this->{subject};
  $date = $this->{datestring}; # scalar localtime;
  $spamreport = $this->{spamreport};
  $token = $this->{token};
  # And let them put the date number in there too
  #($day, $month, $year) = (localtime)[3,4,5];
  #$month++;
  #$year += 1900;
  #my $datenumber = sprintf("%04d%02d%02d", $year, $month, $day);
  my $datenumber = $this->{datenumber};
  

  my($to, %tolist);
  foreach $to (@{$this->{to}}) {
    $tolist{$to} = 1;
  }
  $to = join(', ', sort keys %tolist);

  # Delete everything in brackets after the SA report, if it exists
  $spamreport =~ s/(spamassassin)[^(]*\([^)]*\)/$1/i;

  # Work out which of the 3 spam reports to send them.
  $filename = MailScanner::Config::Value('recipientspamreport', $this);
  MailScanner::Log::NoticeLog("Spam Actions: Notify %s", $to)
    if MailScanner::Config::Value('logspam');

  $messagefh = new FileHandle;
  $messagefh->open($filename)
    or MailScanner::Log::WarnLog("Cannot open message file %s, %s",
                                 $filename, $!);
  $emailmsg = "";
  while(<$messagefh>) {
    chomp;
    s#"#\\"#g;
    s#@#\\@#g;
    # Boring untainting again...
    /(.*)/;
    $line = eval "\"$1\"";
    $emailmsg .= MailScanner::Config::DoPercentVars($line) . "\n";
  }
  $messagefh->close();

  # Send the message to the spam sender, but ensure the envelope
  # sender address is "<>" so that it can't be bounced.
  $global::MS->{mta}->SendMessageString($this, $emailmsg, $localpostmaster)
    or MailScanner::Log::WarnLog("Could not send sender spam notify, %s", $!);
}

1;
