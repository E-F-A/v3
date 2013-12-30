#!/bin/bash
# +--------------------------------------------------------------------+
# EFA 3.0.0.0 build script version 20131224
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
# +--------------------------------------------------------------------

# +---------------------------------------------------+
# Variables
# +---------------------------------------------------+
version="3.0.0.0 beta"
logdir="/var/log/EFA"
gitdlurl="https://raw.github.com/E-F-A/v3/master/build"
password="EfaPr0j3ct"
mailwatchver="1.2.0-beta-4"
# +---------------------------------------------------+

# +---------------------------------------------------+
# Update system before we start
# +---------------------------------------------------+
func_upgradeOS () {
    yum -y upgrade
    #rpm -e wireless-tools # (gives dependency error's when removed, so keep..)
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# add rpmforge/repoforge repositories
# +---------------------------------------------------+
func_repoforge () {
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm -ivh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
    yum install -y tnef perl-BerkeleyDB perl-Convert-TNEF perl-Filesys-Df Perl-File-Tail perl-IO-Multiplex perl-IP-Country perl-Mail-SPF-Query perl-Net-CIDR perl-Net-Ident perl-Net-Server perl-Net-LDAP
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MySQL
# +---------------------------------------------------+
func_mysql () {
    echo "Mysql configuration"
    service mysqld start

    # BDB support is removed from MYSQL 5.1, so those variables are gone
    # (does anything depend on perl-BerkleyDB or BDB in general?)
    
    # remove default security flaws from MySQL.
    /usr/bin/mysqladmin -u root password "$password"
    /usr/bin/mysqladmin -u root -p"$password" -h localhost.localdomain password "$password"
    echo y | /usr/bin/mysqladmin -u root -p"$password" drop 'test'
    /usr/bin/mysql -u root -p"$password" -e "DELETE FROM mysql.user WHERE User='';"
    /usr/bin/mysql -u root -p"$password" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    
    # Create the databases 
    /usr/bin/mysql -u root -p"$password" -e "CREATE DATABASE FuzzyOcr"
    /usr/bin/mysql -u root -p"$password" -e "CREATE DATABASE sa_bayes"
    /usr/bin/mysql -u root -p"$password" -e "CREATE DATABASE sqlgrey"
   
    # Create and populate the mailscanner db
    # Source:  https://raw.github.com/endelwar/mailwatch/master/create.sql
    cd /tmp
    /usr/bin/wget -q $gitdlurl/MYSQL/create.sql
    /usr/bin/mysql -u root -p"$password" < create.sql
 
    # Create the users
    /usr/bin/mysql -u root -p"$password" -e "GRANT SELECT,INSERT,UPDATE,DELETE on sa_bayes.* to 'sa_user'@'localhost' identified by '$password'"
    # mailwatch user
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL ON mailscanner.* TO mailwatch@localhost IDENTIFIED BY '$password';"
    /usr/bin/mysql -u root -p"$password" -e "GRANT FILE ON *.* to mailwatch@localhost IDENTIFIED BY '$password';" 
    /usr/bin/mysql -u root -p"$password" mailscanner -e "INSERT INTO users SET username = 'admin', password = md5('$password'), fullname = 'Administrator', type ='A'" 
    # todo: sqlgrey user
    # todo: fuzzyocr user
    /usr/bin/mysql -u root -p"$password" -e "FLUSH PRIVILEGES;"
 
    # populate the sa_bayes DB
    # source: https://svn.apache.org/repos/asf/spamassassin/trunk/sql/bayes_mysql.sql
    cd /tmp
    /usr/bin/wget -q $gitdlurl/MYSQL/bayes_mysql.sql
    /usr/bin/mysql -u root -p"$password" sa_bayes < /tmp/bayes_mysql.sql
    
    # add the AWL table to sa_bayes
    # source: https://svn.apache.org/repos/asf/spamassassin/trunk/sql/awl_mysql.sql
    cd /tmp
    /usr/bin/wget -q $gitdlurl/MYSQL/awl_mysql.sql
    /usr/bin/mysql -u root -p"$password" sa_bayes < /tmp/awl_mysql.sql
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure postfix
# +---------------------------------------------------+
func_postfix () {
    mkdir /etc/postfix/ssl
    echo /^Received:/ HOLD>>/etc/postfix/header_checks
    postconf -e "inet_interfaces = all"
    postconf -e "mynetworks_style = subnet"
    postconf -e "header_checks = regexp:/etc/postfix/header_checks"
    postconf -e "myorigin = \$mydomain"
    postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
    postconf -e "relay_domains = hash:/etc/postfix/transport"
    postconf -e "transport_maps = hash:/etc/postfix/transport"
    postconf -e "local_recipient_maps = "
    postconf -e "smtpd_helo_required = yes"
    postconf -e "smtpd_delay_reject = yes"
    postconf -e "disable_vrfy_command = yes"
    postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual"
    postconf -e "alias_maps = hash:/etc/aliases"
    postconf -e "alias_database = hash:/etc/aliases"
    postconf -e "default_destination_recipient_limit = 1"
    # SASL config
    postconf -e "broken_sasl_auth_clients = yes"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "smtpd_sasl_local_domain = "
    postconf -e "smtpd_sasl_path = smtpd"
    postconf -e "smtpd_sasl_local_domain = $myhostname"
    postconf -e "smtpd_sasl_security_options = noanonymous"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_sasl_type = cyrus"
    # tls config
    postconf -e "smtp_use_tls = yes"
    postconf -e "smtpd_use_tls = yes"
    postconf -e "smtp_tls_CAfile = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtp_tls_session_cache_database = btree:/var/spool/postfix/smtp_tls_session_cache"
    postconf -e "smtp_tls_note_starttls_offer = yes"
    postconf -e "smtpd_tls_key_file = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_cert_file = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_CAfile = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_loglevel = 1"
    postconf -e "smtpd_tls_received_header = yes"
    postconf -e "smtpd_tls_session_cache_timeout = 3600s"
    postconf -e "tls_random_source = dev:/dev/urandom"
    postconf -e "smtpd_tls_session_cache_database = btree:/var/spool/postfix/smtpd_tls_session_cache"
    postconf -e "smtpd_tls_security_level = may"
    # restrictions
    postconf -e "smtpd_helo_restrictions =  check_helo_access hash:/etc/postfix/helo_access, reject_invalid_hostname"
    postconf -e "smtpd_sender_restrictions = permit_sasl_authenticated, check_sender_access hash:/etc/postfix/sender_access, reject_non_fqdn_sender, reject_unknown_sender_domain"
    postconf -e "smtpd_data_restrictions =  reject_unauth_pipelining"
    postconf -e "smtpd_client_restrictions = permit_sasl_authenticated, reject_rbl_client zen.spamhaus.org"
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, reject_non_fqdn_recipient, reject_unknown_recipient_domain, check_recipient_access hash:/etc/postfix/recipient_access, check_policy_service inet:127.0.0.1:2501"
    postconf -e "masquerade_domains = \$mydomain"
    #other configuration files
    newaliases
    touch /etc/postfix/transport
    touch /etc/postfix/virtual
    touch /etc/postfix/helo_access
    touch /etc/postfix/sender_access
    touch /etc/postfix/recipient_access
    touch /etc/postfix/sasl_passwd
    postmap /etc/postfix/transport
    postmap /etc/postfix/virtual
    postmap /etc/postfix/helo_access
    postmap /etc/postfix/sender_access
    postmap /etc/postfix/recipient_access
    postmap /etc/postfix/sasl_passwd
    echo "pwcheck_method: auxprop">/usr/lib64/sasl2/smtpd.conf
    echo "auxprop_plugin: sasldb">>/usr/lib64/sasl2/smtpd.conf
    echo "mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5">>/usr/lib64/sasl2/smtpd.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# install and configure MailScanner
# +---------------------------------------------------+
func_mailscanner () {
    cd /tmp
    wget http://mailscanner.info/files/4/rpm/MailScanner-4.84.6-1.rpm.tar.gz
    tar -xvzf MailScanner-4.84.6-1.rpm.tar.gz
    cd MailScanner-4.84.6-1
    ./install.sh
    rm -f /root/.rpmmacros
    chown postfix:postfix /var/spool/MailScanner/quarantine
    mkdir /var/spool/MailScanner/spamassassin
    chown postfix:postfix /var/spool/MailScanner/spamassassin
    mkdir /var/spool/mqueue
    chown postfix:postfix /var/spool/mqueue
    touch /var/lock/subsys/MailScanner.off
    touch /etc/MailScanner/rules/spam.blacklist.rules

    # Configure MailScanner
    sed -i '/^Max Children =/ c\Max Children = 2' /etc/MailScanner/MailScanner.conf
    sed -i '/^Run As User =/ c\Run As User = postfix' /etc/MailScanner/MailScanner.conf
    sed -i '/^Run As Group =/ c\Run As Group = postfix' /etc/MailScanner/MailScanner.conf
    sed -i '/^Incoming Queue Dir =/ c\%Incoming Queue Dir = \/var\/spool\/postfix\/hold' /etc/MailScanner/MailScanner.conf
    sed -i '/^Outgoing Queue Dir =/ c\Outgoing Queue Dir = \/var\/spool\/postfix\/incoming' /etc/MailScanner/MailScanner.conf
    sed -i '/^MTA =/ c\MTA = postfix' /etc/MailScanner/MailScanner.conf
    sed -i '/^Incoming Work Group =/ c\Incoming Work Group = clamav' /etc/MailScanner/MailScanner.conf
    sed -i '/^Incoming Work Permissions =/ c\Incoming Work Permissions = 0644' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine User =/ c\Quarantine User = postfix' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine Group =/ c\Quarantine Group = apache' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine Permissions =/ c\Quarantine Permissions = 0660' /etc/MailScanner/MailScanner.conf
    sed -i '/^Deliver Unparsable TNEF =/ c\Deliver Unparsable TNEF = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Maximum Archive Depth =/ c\Maximum Archive Depth = 0' /etc/MailScanner/MailScanner.conf
    sed -i '/^Virus Scanners =/ c\Virus Scanners = clamd' /etc/MailScanner/MailScanner.conf
    sed -i '/^Non-Forging Viruses =/ c\Non-Forging Viruses = Joke\/ OF97\/ WM97\/ W97M\/ eicar Zip-Password' /etc/MailScanner/MailScanner.conf
    sed -i '/^Web Bug Replacement =/ c\Web Bug Replacement = http:\/\/dl.efa-project.org\/static\/1x1spacer.gif' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine Whole Message =/ c\Quarantine Whole Message = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine Infections =/ c\Quarantine Infections = no' /etc/MailScanner/MailScanner.conf
    sed -i '/^Keep Spam And MCP Archive Clean =/ c\Keep Spam And MCP Archive Clean = yes' /etc/MailScanner/MailScanner.conf
    sed -i 's/X-%org-name%-MailScanner/X-%org-name%-MailScanner-EFA/g' /etc/MailScanner/MailScanner.conf
    sed -i '/^Remove These Headers =/ c\Remove These Headers = X-Mozilla-Status: X-Mozilla-Status2: Disposition-Notification-To: Return-Receipt-To:' /etc/MailScanner/MailScanner.conf
    sed -i '/^Disarmed Modify Subject =/ c\Disarmed Modify Subject = no' /etc/MailScanner/MailScanner.conf
    sed -i '/^Send Notices =/ c\Send Notices = no' /etc/MailScanner/MailScanner.conf
    sed -i '/^Notice Signature =/ c\Notice Signature = -- \\nEFA\\nEmail Filter Appliance\\nwww.efa-project.org' /etc/MailScanner/MailScanner.conf
    sed -i '/^Notices From =/ c\Notices From = EFA' /etc/MailScanner/MailScanner.conf
    sed -i '/^Inline HTML Signature =/ c\Inline HTML Signature = %rules-dir%\/sig.html.rules' /etc/MailScanner/MailScanner.conf
    sed -i '/^Inline Text Signature =/ c\Inline Text Signature = %rules-dir%\/sig.text.rules' /etc/MailScanner/MailScanner.conf
    sed -i '/^Is Definitely Not Spam =/ c\Is Definitely Not Spam = &SQLWhitelist' /etc/MailScanner/MailScanner.conf
    sed -i '/^Is Definitely Spam =/ c\Is Definitely Spam = &SQLBlacklist' /etc/MailScanner/MailScanner.conf
    sed -i '/^Definite Spam Is High Scoring =/ c\Definite Spam Is High Scoring = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Treat Invalid Watermarks With No Sender as Spam =/ c\Treat Invalid Watermarks With No Sender as Spam = high-scoring spam' /etc/MailScanner/MailScanner.conf
    sed -i '/^Max SpamAssassin Size =/ c\Max SpamAssassin Size = 100k continue 150k' /etc/MailScanner/MailScanner.conf
    sed -i '/^Required SpamAssassin Score =/ c\Required SpamAssassin Score = 4' /etc/MailScanner/MailScanner.conf
    sed -i '/^Spam Actions =/ c\Spam Actions = store notify' /etc/MailScanner/MailScanner.conf
    sed -i '/^High Scoring Spam Actions =/ c\High Scoring Spam Actions = store' /etc/MailScanner/MailScanner.conf
    sed -i '/^Non Spam Actions =/ c\Non Spam Actions = store deliver header "X-Spam-Status: No"' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Spam =/ c\Log Spam = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Silent Viruses =/ c\Log Silent Viruses = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Dangerous HTML Tags =/ c\Log Dangerous HTML Tags = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^SpamAssassin Local State Dir =/ c\SpamAssassin Local State Dir = /var/lib/spamassassin' /etc/MailScanner/MailScanner.conf
    sed -i '/^SpamAssassin User State Dir =/ c\SpamAssassin User State Dir = /var/spool/MailScanner/spamassassin' /etc/MailScanner/MailScanner.conf
    sed -i '/^Detailed Spam Report =/ c\Detailed Spam Report = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Include Scores In SpamAssassin Report =/ c\Include Scores In SpamAssassin Report = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Always Looked Up Last =/ c\Always Looked Up Last = &MailWatchLogging' /etc/MailScanner/MailScanner.conf
    sed -i '/^Clamd Socket =/ c\Clamd Socket = /tmp/clamd.socket' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log SpamAssassin Rule Actions =/ c\Log SpamAssassin Rule Actions = no' /etc/MailScanner/MailScanner.conf

    touch /etc/MailScanner/rules/sig.html.rules
    touch /etc/MailScanner/rules/sig.text.rules
    rm -rf /var/spool/MailScanner/incoming
    mkdir /var/spool/MailScanner/incoming
    echo "none /var/spool/MailScanner/incoming tmpfs defaults 0 0">>/etc/fstab
    mount -a
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install and configure spamassassin & clamav
# +---------------------------------------------------+
func_spam_clamav () {

    yum -y install clamav clamd

    #Use the MailScanner packaged version. Answer no to install clam.
    cd /tmp
    wget http://www.mailscanner.info/files/4/install-Clam-SA-latest.tar.gz
    tar -xvzf install-Clam-SA-latest.tar.gz
    cd install-Clam*
    echo 'n'>answers.txt
    echo ''>>answers.txt
    cat answers.txt|./install.sh
    cd /tmp
    rm -rf install-Clam*
        
    #Force an update of ClamAV definitions...
    # service clamd restart
    # freshclam # todo this should probably be moved to EFA-Init
        
    # fix socket file in mailscanner.conf
    sed -i '/^Clamd Socket/ c\Clamd Socket = \/var\/run\/clamav\/clamd.sock' /etc/MailScanner/MailScanner.conf
    
    # todo: botnet.tar
    # ESVA uses botnet.tar, this old package is in my opinion not needed as spamhaus relay blocklist already 
    # adds botnet's by default.. also the botnet.tar is not maintained anymore...
    
    # todo: PDFinfo.pm
    # official website is nowhere to be found, is this tool still usefull?
    # should research this of still usefull we can probably use the .pm and .cf file from an esva system.
    
    # todo: ImageInfo
    # well not really a todo, ImageInfo is already packaged and enabled by default in spamassassin.
    # nothing to do here, just adding the remark so we don't spend any extra time on it :-).
    
    # todo: sare
    # sare channels are dead: http://wiki.apache.org/spamassassin/SareChannels
    # openprotect seems to have an alternative ^^ see link, need to check if that works.
    
    # Download an initial KAM.cf file updates are handled by EFA-SA-Update.
    /usr/bin/wget -q -O /etc/mail/spamassassin/KAM.cf $gitdlurl/EFA/KAM.cf
    
    # Configure spamassassin bayes and awl DB settings
    echo "#Begin E.F.A. mods for MySQL">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "bayes_store_module              Mail::SpamAssassin::BayesStore::SQL">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "bayes_sql_dsn                   DBI:mysql:sa_bayes:localhost">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "bayes_sql_username              sa_user">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "bayes_sql_password              $password">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "auto_whitelist_factory          Mail::SpamAssassin::SQLBasedAddrList">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "user_awl_dsn                    DBI:mysql:sa_bayes:localhost">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "user_awl_sql_username           sa_user">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "user_awl_sql_password           $password">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "bayes_sql_override_username     mailwatch">>/etc/MailScanner/spam.assassin.prefs.conf
    echo "#End E.F.A. mods for MySQL">>/etc/MailScanner/spam.assassin.prefs.conf
    
    # Add example spam to db
    # source: http://spamassassin.apache.org/gtube/gtube.txt
    cd /tmp
    /usr/bin/wget -q $gitdlurl/EFA/gtube.txt
    sa-learn --spam /tmp/gtube.txt
    
    # and in the end we run sa-update just for the fun of it..
    sa-update
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure apache
# +---------------------------------------------------+
func_apache () {
    echo "apache configuration"

   # Added mod_ssl package to ks.cfg 
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure SQLgrey
# +---------------------------------------------------+
func_sqlgrey () {
    echo "SQLgrey configuration"
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MailWatch
# +---------------------------------------------------+
func_mailwatch () {
    
    echo "MailWatch configuration"

    # Fetch MailWatch
    cd /tmp
    wget http://sourceforge.net/projects/mailwatch/files/mailwatch/$mailwatchver/mailwatch-$mailwatchver.tar.gz
    tar -xzvf mailwatch-$mailwatchver.tar.gz

    # Set php parameters needed
    sed -i '/^magic_quotes_gpc =/ c\magic_quotes_gpc = On' /etc/php.ini
    sed -i '/^short_open_tag =/ c\short_open_tag = On' /etc/php.ini

    # Set up connection for MailWatch    
    cd ./MailScanner_perl_scripts
    sed -i '/^my($db_user) =/ c\my($db_user) = \'mailwatch\';' MailWatch.pm
    sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" MailWatch.pm
    mv MailWatch.pm /usr/lib/MailScanner/MailScanner/CustomFunctions/
    
    # Set up SQLBlackWhiteList
    sed -i '/^ my($db_user) =/ c\ my($db_user) = \'mailwatch\';' SQLBlackWhiteList.pm
    sed -i "/^ my(\$db_pass) =/ c\ my(\$db_pass) = '$password';" SQLBlackWhiteList.pm
    mv SQLBlackWhiteList.pm /usr/lib/MailScanner/MailScanner/CustomFunctions

    # Set up SQLSpamSettings
    sed -i '/^my($db_user) =/ c\my($db_user) = \'mailwatch\';' SQLSpamSettings.pm
    sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" SQLSpamSettings.pm
    mv SQLSpamSettings.pm /usr/lib/MailScanner/MailScanner/CustomFunctions

    # Set up MailWatch tools
    cd ..
    mkdir /usr/local/bin/mailwatch
    mv tools /usr/local/bin/mailwatch
    chmod 755 /usr/loca/bin/mailwatch/tools/Cron_jobs/*
    touch /etc/cron.daily/mailwatch.sh
    echo "#!/bin/bash" > /etc/cron.daily/mailwatch.sh
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/db_clean.php" >> /etc/cron.daily/mailwatch.sh
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_maint.php --clean" >> /etc/cron.daily/mailwatch.sh
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_report.php" >> /etc/cron.daily/mailwatch.sh
    chmod 755 /etc/cron.daily/mailwatch.sh

    # Move MailWatch into web root and configure
    # ESVA MailWatch is directly in /var/www/html
    # Going to move into its own directory and maybe set up a redirect
    # to keep the web root clean and match up with conf.php defaults
    
    cd ..
    mv ./mailscanner /var/www/html
    cd /var/www/html/mailscanner
    chown root:apache images
    chmod ug+rwx images
    chown root:apache images/cache
    chmod ug+rwx images/cache

    cp conf.php.example conf.php
    sed -i '/^define(\'DB_USER\',/ c\define(\'DB_USER\', \'mailwatch\');' conf.php
    sed -i "/^define('DB_PASS',/ c\define('DB_PASS', '$password');" conf.php
    sed -i '/^define(\'TIME_ZONE\'),/ c\define(\'TIME_ZONE\', \'Etc/UTC\');' conf.php
    sed -i '/^define(\'QUARANTINE_USE_FLAG\',/ c\define(\'QUARANTINE_USE_FLAG\', true);' conf.php
    # Note...Set QUARANTINE_FROM_ADDR in EFA_Init for conf.php
    sed -i '/^define(\'QUARANTINE_REPORT_FROM_NAME\',/ c\define(\'QUARANTINE_REPORT_FROM_NAME\', \'EFA - Email Filter Appliance\');' conf.php
    sed -i '/^define(\'QUARANTINE_USE_SENDMAIL\',/ c\define(\'QUARANTINE_USE_SENDMAIL\', true);' conf.php
    sed -i '/^define(\'AUDIT\',/ c\define(\'AUDIT\', true);' conf.php


    # Set up a redirect in web root to MailWatch for now
    touch /var/www/html/index.html
    echo "<!DOCTYPE html>" > index.html
    echo "<html>" >> index.html
    echo " <head>" >> index.html
    echo "  <title>MailWatch</title>" >> index.html
    echo "  <meta http-equiv=\"refresh\" content=\"0; url=/mailscanner/\" />" >> index.html
    echo " </head>" >> index.html
    echo " <body>" >> index.html
    echo "   <a href=\"/mailscanner/\">Click Here for MailWatch</a>"
    echo " </body>" >> index.html
    echo "</html>" >> index.html

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Disable unneeded kernel modules
# +---------------------------------------------------+
func_kernmodules () {
    echo "# Begin Disable modules not required for E.F.A">>/etc/modprobe.conf
    echo "alias ipv6 off">>/etc/modprobe.conf
    echo "alias net-pf-10 off">>/etc/modprobe.conf
    echo "alias pcspkr off">>/etc/modprobe.conf
    echo "# End Disable modules not required for E.F.A.">>/etc/modprobe.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# enable and disable services
# +---------------------------------------------------+
func_services () {
    # These services we really don't need.
    chkconfig ip6tables off
    chkconfig cpuspeed off
    chkconfig lvm2-monitor off
    chkconfig mdmonitor off
    chkconfig netfs off
    chkconfig smartd off
    
    # These services we disable for now and enable them after EFA-Init.
    # Most of these are not enabled by default but add them here just to
    # make sure we don't forget them at EFA-Init.
    chkconfig postfix off 
    chkconfig MailScanner off
    chkconfig httpd off
    chkconfig mysqld off
    chkconfig named off
    chkconfig saslauthd off
    chkconfig crond off
    # todo clamd?
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# EFA specific customization 
# +---------------------------------------------------+
func_efarequirements () {
    # Write version file
    echo "EFA-$version" > /etc/EFA-Version

    # create EFA config file
    touch /etc/EFA-Config
    
    # pre-create the EFA update directory
    mkdir -p /var/EFA/update
    
    # write issue file
    echo "" > /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "--- Welcome to EFA $version ---" >> /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "  http://www.efa-project.org  " >> /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "" >> /etc/issue
    echo "First time login: root/EfaPr0j3ct" >> /etc/issue
    
    # Grab EFA specific scripts/programs
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Init $gitdlurl/EFA/EFA-Init
    chmod 700 /usr/local/sbin/EFA-Init
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Configure $gitdlurl/EFA/EFA-Configure
    chmod 700 /usr/local/sbin/EFA-Configure
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Update $gitdlurl/EFA/EFA-Update
    chmod 700 /usr/local/sbin/EFA-Update
    /usr/bin/wget -q -O /usr/local/sbin/EFA-SA-Update $gitdlurl/EFA/EFA-SA-Update
    chmod 700 /usr/local/sbin/EFA-SA-Update
    
    # Write SSH banner
    sed -i "/^#Banner / c\#Banner" /etc/ssh/sshd_config
    cat > /etc/banner << 'EOF'
       Welcome to E.F.A. (http://www.efa-project.org)

 Warning!

 THIS IS A PRIVATE COMPUTER SYSTEM. It is for authorized use only.
 Users (authorized or unauthorized) have no explicit or implicit
 expectation of privacy.

 Any or all uses of this system and all files on this system may
 be intercepted, monitored, recorded, copied, audited, inspected,
 and disclosed to authorized site and law enforcement personnel,
 as well as authorized officials of other agencies, both domestic
 and foreign.  By using this system, the user consents to such
 interception, monitoring, recording, copying, auditing, inspection,
 and disclosure at the discretion of authorized site personnel.

 Unauthorized or improper use of this system may result in
 administrative disciplinary action and civil and criminal penalties.
 By continuing to use this system you indicate your awareness of and
 consent to these terms and conditions of use.   LOG OFF IMMEDIATELY
 if you do not agree to the conditions stated in this warning.  
EOF


    # Compress logs from logrotate
    sed -i "s/#compress/compress/g" /etc/logrotate.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Cron settings
# +---------------------------------------------------+
func_cron () {
    /usr/bin/wget -q -O /etc/cron.daily/EFA-Daily-cron $gitdlurl/EFA/EFA-Daily-cron
    chmod 700 /etc/cron.daily/EFA-Daily-cron
    /usr/bin/wget -q -O /etc/cron.monthly/EFA-Monthly-cron  $gitdlurl/EFA/EFA-Monthly-cron
    chmod 700 /etc/cron.monthly/EFA-Monthly-cron
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Clean-up
# +---------------------------------------------------+
func_cleanup () {
    
    echo "DISABLED FOR NOW UNTIL TESTING IS OVER..."
    # Clean SSH keys (generate at first boot)
    #/bin/rm /etc/ssh/ssh_host_*
    
    # Secure SSH
    #sed -i '/^#PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
    
    # todo:
    # clear/set dns
    # clear logfiles
    # clear bash history
}

# +---------------------------------------------------+
# Main logic (this is where we start calling out functions)
# +---------------------------------------------------+
func_upgradeOS
func_repoforge
func_mysql
func_postfix
func_mailscanner
func_spam_clamav
func_apache
func_sqlgrey
func_mailwatch
func_kernmodules
func_services
func_efarequirements
func_cron
func_cleanup
# +---------------------------------------------------+