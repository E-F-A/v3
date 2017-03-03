#!/bin/bash
action=$1
# +--------------------------------------------------------------------+
# EFA 3.0.1.9 build script version 20170303
# +--------------------------------------------------------------------+
# Copyright (C) 2013~2017 https://efa-project.org
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

# TODO: Use update v2 method for packaging in build.bash
#   update entire script

# +---------------------------------------------------+
# Variables
# +---------------------------------------------------+
version="3.0.1.8"
logdir="/var/log/EFA"
gitdlurl="https://raw.githubusercontent.com/E-F-A/v3/$version/build"
password="EfaPr0j3ct"
mirror="http://dl.efa-project.org"
smirror="https://dl.efa-project.org"
mirrorpath="/build/$version"
yumexclude="kernel* mysql* postfix* mailscanner* MailScanner* clamav* clamd* open-vm-tools*"
MAILWATCHVERSION="161844b"
MAILWATCHRELEASE="1.2.0 - RC4"
MAILWATCHBRANCH="develop"
IMAGECEBERUSVERSION="1.1"
SPAMASSASSINVERSION="3.4.1"
WEBMINVERSION="1.770-1"
PYZORVERSION="0.7.0"
# +---------------------------------------------------+

# +---------------------------------------------------+
# Pre-build
# +---------------------------------------------------+
func_prebuild () {
    # mounting /tmp without nosuid and noexec while building as it breaks building some components.
    mount -o remount rw /tmp
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Update system before we start
# +---------------------------------------------------+
func_upgradeOS () {
    yum -y upgrade
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# add EFA Repo
# +---------------------------------------------------+
func_efarepo () {
   rpm --import $smirror/rpm/RPM-GPG-KEY-E.F.A.Project
   cd /etc/yum.repos.d/
   /usr/bin/wget $smirror/rpm/EFA.repo
   yum install -y unrar perl-IP-Country perl-Mail-SPF-Query perl-Net-Ident perl-Mail-ClamAV webmin perl-NetAddr-IP \
   re2c postfix perl-Digest-SHA perl-Mail-SPF perl-Digest-HMAC perl-Net-DNS perl-Net-DNS-Resolver-Programmable \
   perl-Digest perl-Digest-MD5 perl-DB_File perl-ExtUtils-Constant perl-Geo-IP perl-IO-Socket-INET6 perl-Socket \
   perl-IO-Socket-IP perl-libnet bzip2-devel perl-File-ShareDir-Install perl-LDAP perl-IO-Compress-Bzip2 \
   perl-Net-DNS-Nameserver spamassassin MailScanner clamav-unofficial-sigs perl-Mail-IMAPClient \
   perl-OLE-Storage_Lite perl-Inline perl-Text-Balanced perl-Net-CIDR-Lite perl-Sys-Hostname-Long tnef perl-Net-Patricia \
   perl-IO-Multiplex perl-File-Tail perl-Data-Dump perl-Sys-SigAction perl-Net-Netmask perl-Filesys-Df perl-Net-CIDR \
   perl-BerkeleyDB perl-Net-Server perl-Convert-TNEF perl-IP-Country

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# add epel repository
# +---------------------------------------------------+
func_epelrepo () {
   rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6
   yum install epel-release -y
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MySQL
# +---------------------------------------------------+
func_mysql () {
    echo "Mysql configuration"
    service mysqld start

    # remove default security flaws from MySQL.
    /usr/bin/mysqladmin -u root password "$password"
    /usr/bin/mysqladmin -u root -p"$password" -h localhost.localdomain password "$password"
    echo y | /usr/bin/mysqladmin -u root -p"$password" drop 'test'
    /usr/bin/mysql -u root -p"$password" -e "DELETE FROM mysql.user WHERE User='';"
    /usr/bin/mysql -u root -p"$password" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

    # Create the databases
    /usr/bin/mysql -u root -p"$password" -e "CREATE DATABASE sa_bayes"
    /usr/bin/mysql -u root -p"$password" -e "CREATE DATABASE sqlgrey"

    # Create and populate the mailscanner db
    # Source:  https://raw.githubusercontent.com/endelwar/mailwatch/master/create.sql
    # https://raw.githubusercontent.com/endelwar/mailwatch/master/tools/create_relay_postfix.sql
    cd /usr/src/EFA
    /usr/bin/wget --no-check-certificate $gitdlurl/MYSQL/create.sql
    /usr/bin/mysql -u root -p"$password" < /usr/src/EFA/create.sql

    # Create autorelease table
    /usr/bin/mysql -u root -p"$password" mailscanner -e 'CREATE TABLE `autorelease` ( `id` bigint(20) NOT NULL AUTO_INCREMENT, `msg_id` varchar(255) NOT NULL, `uid` varchar(255) NOT NULL, PRIMARY KEY (`id`) );'

    # Create and populate efa db
    /usr/bin/wget --no-check-certificate $gitdlurl/MYSQL/efatokens.sql
    /usr/bin/mysql -u root -p"$password" < /usr/src/EFA/efatokens.sql

    # Create the users
    /usr/bin/mysql -u root -p"$password" -e "GRANT SELECT,INSERT,UPDATE,DELETE on sa_bayes.* to 'sa_user'@'localhost' identified by '$password'"

    # mailwatch mysql user and login user
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL ON mailscanner.* TO mailwatch@localhost IDENTIFIED BY '$password';"
    /usr/bin/mysql -u root -p"$password" -e "GRANT FILE ON *.* to mailwatch@localhost IDENTIFIED BY '$password';"

    # sqlgrey user
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL on sqlgrey.* to 'sqlgrey'@'localhost' identified by '$password'"

    # efa user for token handling
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL on efa.* to 'efa'@'localhost' identified by '$password'"

    # flush
    /usr/bin/mysql -u root -p"$password" -e "FLUSH PRIVILEGES;"

    # populate the sa_bayes DB
    # source: https://svn.apache.org/repos/asf/spamassassin/trunk/sql/bayes_mysql.sql
    cd /usr/src/EFA
    /usr/bin/wget --no-check-certificate $gitdlurl/MYSQL/bayes_mysql.sql
    /usr/bin/mysql -u root -p"$password" sa_bayes < /usr/src/EFA/bayes_mysql.sql

    # add the AWL table to sa_bayes
    # source: https://svn.apache.org/repos/asf/spamassassin/trunk/sql/awl_mysql.sql
    cd /usr/src/EFA
    /usr/bin/wget --no-check-certificate $gitdlurl/MYSQL/awl_mysql.sql
    /usr/bin/mysql -u root -p"$password" sa_bayes < /usr/src/EFA/awl_mysql.sql
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure postfix
# +---------------------------------------------------+
func_postfix () {
    mkdir /etc/postfix/ssl
    echo /^Received:/ HOLD>>/etc/postfix/header_checks
    postconf -e "inet_protocols = ipv4"
    postconf -e "inet_interfaces = all"
    postconf -e "mynetworks = 127.0.0.0/8"
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
    postconf -e "smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache"
    postconf -e "smtp_tls_note_starttls_offer = yes"
    postconf -e "smtpd_tls_key_file = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_cert_file = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_CAfile = /etc/postfix/ssl/smtpd.pem"
    postconf -e "smtpd_tls_loglevel = 1"
    postconf -e "smtpd_tls_received_header = yes"
    postconf -e "smtpd_tls_session_cache_timeout = 3600s"
    postconf -e "tls_random_source = dev:/dev/urandom"
    postconf -e "smtpd_tls_session_cache_database = btree:/var/lib/postfix/smtpd_tls_session_cache"
    postconf -e "smtpd_tls_security_level = may"
    # Issue #149 Disable SSL in Postfix
    postconf -e "smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3"
    postconf -e "smtp_tls_mandatory_protocols = !SSLv2,!SSLv3"
    postconf -e "smtpd_tls_protocols = !SSLv2,!SSLv3"
    postconf -e "smtp_tls_protocols = !SSLv2,!SSLv3"
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

    # Issue #167 Change perms on /etc/postfix/sasl_passwd to 600
    chmod 0600 /etc/postfix/sasl_passwd

    # Logjam Vulnerability #188
    openssl dhparam -out /etc/postfix/ssl/dhparam.pem 2048
    postconf -e "smtpd_tls_dh1024_param_file = /etc/postfix/ssl/dhparam.pem"
    postconf -e "smtpd_tls_ciphers = low"

    echo "pwcheck_method: auxprop">/usr/lib64/sasl2/smtpd.conf
    echo "auxprop_plugin: sasldb">>/usr/lib64/sasl2/smtpd.conf
    echo "mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5">>/usr/lib64/sasl2/smtpd.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Configure MailScanner
# http://mailscanner.info
# +---------------------------------------------------+
func_mailscanner () {

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
    sed -i '/^Incoming Queue Dir =/ c\Incoming Queue Dir = \/var\/spool\/postfix\/hold' /etc/MailScanner/MailScanner.conf
    sed -i '/^Outgoing Queue Dir =/ c\Outgoing Queue Dir = \/var\/spool\/postfix\/incoming' /etc/MailScanner/MailScanner.conf
    sed -i '/^MTA =/ c\MTA = postfix' /etc/MailScanner/MailScanner.conf
    # Issue #177 Correct EFA to new clamav paths using EPEL
    # Issue #308 ClamAV Status Page blank
    sed -i '/^Incoming Work Group =/ c\Incoming Work Group = mtagroup' /etc/MailScanner/MailScanner.conf
    sed -i '/^Incoming Work Permissions =/ c\Incoming Work Permissions = 0660' /etc/MailScanner/MailScanner.conf
    sed -i '/^Quarantine User =/ c\Quarantine User = postfix' /etc/MailScanner/MailScanner.conf
    # Issue #311 Quarantine Permissions issue
    sed -i '/^Quarantine Group =/ c\Quarantine Group = mtagroup' /etc/MailScanner/MailScanner.conf
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
    sed -i '/^Treat Invalid Watermarks With No Sender as Spam =/ c\Treat Invalid Watermarks With No Sender as Spam = 2' /etc/MailScanner/MailScanner.conf
    sed -i '/^Max SpamAssassin Size =/ c\Max SpamAssassin Size = 100k continue 150k' /etc/MailScanner/MailScanner.conf
    sed -i '/^Required SpamAssassin Score =/ c\Required SpamAssassin Score = 4' /etc/MailScanner/MailScanner.conf
    sed -i '/^Spam Actions =/ c\Spam Actions = store' /etc/MailScanner/MailScanner.conf
    sed -i '/^High Scoring Spam Actions =/ c\High Scoring Spam Actions = store' /etc/MailScanner/MailScanner.conf
    sed -i '/^Non Spam Actions =/ c\Non Spam Actions = store deliver header "X-Spam-Status:No" custom(nonspam)' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Spam =/ c\Log Spam = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Silent Viruses =/ c\Log Silent Viruses = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log Dangerous HTML Tags =/ c\Log Dangerous HTML Tags = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^SpamAssassin Local State Dir =/ c\SpamAssassin Local State Dir = /var/lib/spamassassin' /etc/MailScanner/MailScanner.conf
    sed -i '/^SpamAssassin User State Dir =/ c\SpamAssassin User State Dir = /var/spool/MailScanner/spamassassin' /etc/MailScanner/MailScanner.conf
    sed -i '/^Detailed Spam Report =/ c\Detailed Spam Report = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Include Scores In SpamAssassin Report =/ c\Include Scores In SpamAssassin Report = yes' /etc/MailScanner/MailScanner.conf
    sed -i '/^Always Looked Up Last =/ c\Always Looked Up Last = &MailWatchLogging' /etc/MailScanner/MailScanner.conf
    # Issue #177 Correct EFA to new clamav paths using EPEL
    sed -i '/^Clamd Socket =/ c\Clamd Socket = /var/run/clamav/clamd.sock' /etc/MailScanner/MailScanner.conf
    sed -i '/^Log SpamAssassin Rule Actions =/ c\Log SpamAssassin Rule Actions = no' /etc/MailScanner/MailScanner.conf
    sed -i "/^Sign Clean Messages =/ c\# EFA Note: CustomAction.pm will Sign Clean Messages instead using the custom(nonspam) action.\nSign Clean Messages = No" /etc/MailScanner/MailScanner.conf
    sed -i "/^Deliver Cleaned Messages =/ c\Deliver Cleaned Messages = No" /etc/MailScanner/MailScanner.conf
    sed -i "/^Maximum Processing Attempts =/ c\Maximum Processing Attempts = 2" /etc/MailScanner/MailScanner.conf
    sed -i "/^High SpamAssassin Score =/ c\High SpamAssassin Score = 7" /etc/MailScanner/MailScanner.conf
    # Issue #219 Trailing spaces in subjects in MailScanner trigger duplicate subjects in header
    sed -i "/^Place New Headers At Top Of Message =/ c\Place New Headers At Top Of Message = yes" /etc/MailScanner/MailScanner.conf
    # Issue #206 Default Max Arvhive Depth to Non Zero
    sed -i "/^Maximum Archive Depth =/ c\Maximum Archive Depth = 3" /etc/MailScanner/MailScanner.conf

    # Issue #132 Increase sa-learn and spamassassin max message size limits
    sed -i "/^Max Spam Check Size =/ c\Max Spam Check Size = 2048k" /etc/MailScanner/MailScanner.conf

    # Issue #153 Reply signature behavior not functional
    sed -i "/^Dont Sign HTML If Headers Exist =/ c\Dont Sign HTML If Headers Exist = In-Reply-To: References:" /etc/MailScanner/MailScanner.conf

    # Issue #136 Disable Notify Senders by default in MailScanner
    # Issue #203 fix the notify Senders
    sed -i "/^Notify Senders =/ c\Notify Senders = no" /etc/MailScanner/MailScanner.conf

    # Match up envelope header (changed at efa-init but useful for testing)
    sed -i '/^envelope_sender_header / c\envelope_sender_header X-yoursite-MailScanner-EFA-From' /etc/MailScanner/spamassassin.conf

    touch /etc/MailScanner/rules/sig.html.rules
    touch /etc/MailScanner/rules/sig.text.rules
    touch /etc/MailScanner/phishing.safe.sites.conf
    rm -rf /var/spool/MailScanner/incoming
    mkdir /var/spool/MailScanner/incoming
    echo "none /var/spool/MailScanner/incoming tmpfs noatime 0 0">>/etc/fstab
    mount -a

    # Remove all reports except en and modify all texts
    cd /usr/src/EFA/
    wget $gitdlurl/MailScanner/reports/en/en-reports-filelist.txt
    # rm -rf /etc/MailScanner/reports
    # mkdir -p /etc/MailScanner/reports/en
    rm -f /usr/share/MailScanner/reports/en/*
    cd /usr/share/MailScanner/reports/en
    for report in `cat /usr/src/EFA/en-reports-filelist.txt`
      do
        wget $gitdlurl/MailScanner/reports/en/$report
    done

    # Add CustomAction.pm for token handling
    cd /usr/share/MailScanner/perl/custom
    # Remove as a copy will throw a mailscanner --lint error
    rm -f CustomAction.pm
    wget $gitdlurl/EFA/CustomAction.pm

    # Add EFA-Tokens-Cron
    cd /etc/cron.daily
    wget $gitdlurl/EFA/EFA-Tokens-Cron
    chmod 700 EFA-Tokens-Cron

    # Force mailscanner init to return a code on all failures
    sed -i 's/failure/failure \&\& RETVAL=1/g' /etc/init.d/mailscanner

    # Symbolic links for backward compatibility
    ln -s /usr/share/MailScanner /usr/lib/MailScanner
    ln -s /usr/share/MailScanner/reports /etc/MailScanner/reports
    ln -s /usr/share/MailScanner/perl/MailScanner /usr/share/MailScanner/MailScanner
    ln -s /usr/share/MailScanner/perl/custom /usr/share/MailScanner/perl/MailScanner/CustomFunctions
    ln -s /etc/init.d/mailscanner /etc/init.d/MailScanner
    ln -s /etc/MailScanner/mcp/mcp.spamassassin.conf /etc/MailScanner/mcp/mcp.spamassassin.conf
    ln -s /etc/MailScanner/spamassassin.conf /etc/MailScanner/spam.assassin.prefs.conf

    sed -i "/^run_mailscanner/ c\run_mailscanner=1" /etc/MailScanner/defaults
    sed -i "/^ramdisk_sync/ c\ramdisk_sync=1" /etc/MailScanner/defaults

    # Issue #294 Attachment Release Issues in MailWatch
    sed -i "/^Filename Rules =/ c\Filename Rules = %etc-dir%/filename.rules" /etc/MailScanner/MailScanner.conf
    sed -i "/^Filetype Rules =/ c\Filetype Rules = %etc-dir%/filetype.rules" /etc/MailScanner/MailScanner.conf
    sed -i "/^Dangerous Content Scanning =/ c\Dangerous Content Scanning = %rules-dir%/content.scanning.rules" /etc/MailScanner/MailScanner.conf

    echo -e "From:\t127.0.0.1\t/etc/MailScanner/filename.rules.allowall.conf" > /etc/MailScanner/filename.rules
    echo -e "FromOrTo:\tdefault\t/etc/MailScanner/filename.rules.conf" >> /etc/MailScanner/filename.rules

    echo -e "From:\t127.0.0.1\t/etc/MailScanner/filetype.rules.allowall.conf" > /etc/MailScanner/filetype.rules
    echo -e "FromOrTo:\tdefault\t/etc/MailScanner/filetype.rules.conf" >> /etc/MailScanner/filetype.rules

    echo -e "From:\t127.0.0.1\tno" > /etc/MailScanner/rules/content.scanning.rules
    echo -e "FromOrTo:\tdefault\tyes" >> /etc/MailScanner/rules/content.scanning.rules

    echo -e "allow\t.*\t-\t-" > /etc/MailScanner/filename.rules.allowall.conf
    echo -e "allow\t.*\t-\t-" >> /etc/MailScanner/filetype.rules.allowall.conf

    # Issue #309 Anacron daily notifications from mailscanner
    sed -i '/^\/usr\/sbin\/ms-cron DAILY/ c\/usr/sbin/ms-cron DAILY >/dev/null 2>&1' /etc/cron.daily/mailscanner
    sed -i '/^\/usr\/sbin\/ms-cron MAINT/ c\/usr/sbin/ms-cron MAINT >/dev/null 2>&1' /etc/cron.daily/mailscanner

    # Issue #328 ClamAV not updating
    sed -i '/^ms_cron_av=/ c\ms_cron_av=1' /etc/MailScanner/defaults

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install and configure spamassassin & clamav
# +---------------------------------------------------+
func_spam_clamav () {
    # install clamav and clamd.
    yum -y install clamav clamd

    # Issue #171 Update clamav -- fix any clamav discrepancies

    # Set freshclam to correct paths
    sed -i "/^DatabaseDirectory/ c\DatabaseDirectory /var/lib/clamav" /etc/freshclam.conf
    sed -i "/^DatabaseOwner/ c\DatabaseOwner clam" /etc/freshclam.conf

    userdel clamav >/dev/null 2&>1
    rm -f /etc/freshclam.conf.rpmnew

    # remove freshclam from /etc/cron.daily (redundant to /etc/cron.hourly/update_virus_scanners)
    rm -f /etc/cron.daily/freshclam

    # Symlink spamassassin.conf (previously handled by tarball)
    ln -s -f /etc/MailScanner/spamassassin.conf /etc/mail/spamassassin/mailscanner.cf

    # Configure *.pre files (previously handled by tarball)
    sed -i "/^# loadplugin Mail::Spamassassin::Plugin::RelayCountry$/ c\loadplugin Mail::Spamassassin::Plugin::RelayCountry" /etc/mail/spamassassin/init.pre

    # Symlink for Geo::IP
    # Issue #247 Move GeoIP symlink to new location
    rm -f /usr/share/GeoIP/GeoLiteCountry.dat
    ln -s /var/www/html/mailscanner/temp/GeoIP.dat /usr/share/GeoIP/GeoLiteCountry.dat

    # PDFInfo (now included in SA 3.4.1)
    /usr/bin/wget -O /etc/mail/spamassassin/pdfinfo.cf $gitdlurl/PDFInfo/pdfinfo.cf
    sed -i "/^# loadplugin Mail::SpamAssassin::Plugin::PDFInfo$/ c\loadplugin Mail::SpamAssassin::Plugin::PDFInfo" /etc/mail/spamassassin/v341.pre

    # Download an initial KAM.cf file updates are handled by EFA-SA-Update.
    /usr/bin/wget -O /etc/mail/spamassassin/KAM.cf $gitdlurl/EFA/KAM.cf

    # Configure spamassassin bayes and awl DB settings
    echo "#Begin E.F.A. mods for MySQL">>/etc/MailScanner/spamassassin.conf
    echo "bayes_store_module              Mail::SpamAssassin::BayesStore::SQL">>/etc/MailScanner/spamassassin.conf
    echo "bayes_sql_dsn                   DBI:mysql:sa_bayes:localhost">>/etc/MailScanner/spamassassin.conf
    echo "bayes_sql_username              sa_user">>/etc/MailScanner/spamassassin.conf
    echo "bayes_sql_password              $password">>/etc/MailScanner/spamassassin.conf
    echo "auto_whitelist_factory          Mail::SpamAssassin::SQLBasedAddrList">>/etc/MailScanner/spamassassin.conf
    echo "user_awl_dsn                    DBI:mysql:sa_bayes:localhost">>/etc/MailScanner/spamassassin.conf
    echo "user_awl_sql_username           sa_user">>/etc/MailScanner/spamassassin.conf
    echo "user_awl_sql_password           $password">>/etc/MailScanner/spamassassin.conf
    echo "bayes_sql_override_username     mailwatch">>/etc/MailScanner/spamassassin.conf
    echo "txrep_factory                   Mail::SpamAssassin::SQLBasedAddrList" >> /etc/MailScanner/spamassassin.conf
    echo "txrep_track_messages            0" >> /etc/MailScanner/spamassassin.conf
    echo "user_awl_sql_override_username  TxRep" >> /etc/MailScanner/spamassassin.conf
    echo "user_awl_sql_table              txrep" >> /etc/MailScanner/spamassassin.conf
    echo "use_txrep                       0" >> /etc/MailScanner/spamassassin.conf
    echo "#End E.F.A. mods for MySQL" >> /etc/MailScanner/spamassassin.conf

    # Enable Auto White Listing
    sed -i '/^#loadplugin Mail::SpamAssassin::Plugin::AWL/ c\loadplugin Mail::SpamAssassin::Plugin::AWL' /etc/mail/spamassassin/v310.pre

    # Enable TxRep Plugin
    sed -i "/^# loadplugin Mail::SpamAssassin::Plugin::TxRep/ c\loadplugin Mail::SpamAssassin::Plugin::TxRep" /etc/mail/spamassassin/v341.pre

    # Add example spam to db
    # source: http://spamassassin.apache.org/gtube/gtube.txt \
    cd /usr/src/EFA
    /usr/bin/wget $gitdlurl/EFA/gtube.txt
    /usr/bin/sa-learn --spam /usr/src/EFA/gtube.txt

    # AWL cleanup tools (just a bit different then esva)
    # http://notes.sagredo.eu/node/86
    echo '#!/bin/sh'>/usr/sbin/trim-awl
    echo "/usr/bin/mysql -usa_user -p$password < /etc/trim-awl.sql">>/usr/sbin/trim-awl
    echo 'exit 0 '>>/usr/sbin/trim-awl
    chmod +x /usr/sbin/trim-awl

    echo "USE sa_bayes;">/etc/trim-awl.sql
    echo "DELETE FROM awl WHERE ts < (NOW() - INTERVAL 28 DAY);">>/etc/trim-awl.sql

    cd /etc/cron.weekly
    echo '#!/bin/sh'>trim-sql-awl-weekly
    echo '#'>>trim-sql-awl-weekly
    echo '#  Weekly maintenance of auto-whitelist for'>>trim-sql-awl-weekly
    echo '#  SpamAssassin using MySQL'>>trim-sql-awl-weekly
    echo '/usr/sbin/trim-awl'>>trim-sql-awl-weekly
    echo 'exit 0'>>trim-sql-awl-weekly
    chmod +x trim-sql-awl-weekly

    # Create .spamassassin directory (error reported in lint test)
    mkdir /var/www/.spamassassin
    chown postfix:postfix /var/www/.spamassassin

    # Issue #82 re2c spamassassin rule complilation
    sed -i "/^# loadplugin Mail::SpamAssassin::Plugin::Rule2XSBody/ c\loadplugin Mail::SpamAssassin::Plugin::Rule2XSBody" /etc/mail/spamassassin/v320.pre

  # Issue #326 MCP not functional
  ln -s /etc/mail/spamassassin/init.pre /etc/MailScanner/mcp/init.pre
  ln -s /etc/mail/spamassassin/v310.pre /etc/MailScanner/mcp/v310.pre
  ln -s /etc/mail/spamassassin/v312.pre /etc/MailScanner/mcp/v312.pre
  ln -s /etc/mail/spamassassin/v320.pre /etc/MailScanner/mcp/v320.pre
  ln -s /etc/mail/spamassassin/v330.pre /etc/MailScanner/mcp/v330.pre
  ln -s /etc/mail/spamassassin/v340.pre /etc/MailScanner/mcp/v340.pre
  ln -s /etc/mail/spamassassin/v341.pre /etc/MailScanner/mcp/v341.pre
  mkdir -p /var/spool/postfix/.spamassassin
  chown postfix:postfix /var/spool/postfix/.spamassassin

    # and in the end we run sa-update just for the fun of it..
    /usr/bin/sa-update --channel updates.spamassassin.org
    /usr/bin/sa-compile

    echo "SPAMASSASSINVERSION:$SPAMASSASSINVERSION" >> /etc/EFA-Config
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure apache
# +---------------------------------------------------+
func_apache () {
    rm -f /etc/httpd/conf.d/welcome.conf
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original

    # Remove unwanted modules
    sed -i '/LoadModule ldap_module modules\/mod_ldap.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule authnz_ldap_module modules\/mod_authnz_ldap.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule dav_module modules\/mod_dav.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule autoindex_module modules\/mod_autoindex.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule info_module modules\/mod_info.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule dav_fs_module modules\/mod_dav_fs.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule userdir_module modules\/mod_userdir.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_module modules\/mod_proxy.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_balancer_module modules\/mod_proxy_balancer.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_ftp_module modules\/mod_proxy_ftp.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_http_module modules\/mod_proxy_http.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_ajp_module modules\/mod_proxy_ajp.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule proxy_connect_module modules\/mod_proxy_connect.so/d' /etc/httpd/conf/httpd.conf
    sed -i '/LoadModule version_module modules\/mod_version.so/d' /etc/httpd/conf/httpd.conf

    # Remove config for disabled modules
    sed -i '/IndexOptions /d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIconByEncoding /d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIconByType /d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIcon /d' /etc/httpd/conf/httpd.conf
    sed -i '/DefaultIcon /d' /etc/httpd/conf/httpd.conf
    sed -i '/ReadmeName /d' /etc/httpd/conf/httpd.conf
    sed -i '/HeaderName /d' /etc/httpd/conf/httpd.conf
    sed -i '/IndexIgnore /d' /etc/httpd/conf/httpd.conf

    # Issue #139 SSLv3 POODLE Vulnerability
    sed -i "/^SSLProtocol/ c\SSLProtocol all -SSLv2 -SSLv3" /etc/httpd/conf.d/ssl.conf

    # Issue #179 default https
    sed -i '/^#Listen 443/ c\Listen 443' /etc/httpd/conf.d/ssl.conf
    echo -e "RewriteEngine On" > /etc/httpd/conf.d/redirectssl.conf
    echo -e "RewriteCond %{HTTPS} !=on" >> /etc/httpd/conf.d/redirectssl.conf
    echo -e "RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R,L]" >> /etc/httpd/conf.d/redirectssl.conf

    # Secure PHP (this might break some stuff so need to test carefully)
    sed -i '/disable_functions =/ c\disable_functions = apache_child_terminate,apache_setenv,define_syslog_variables,escapeshellcmd,eval,fp,fput,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw,ftp_rawlist,highlight_file,ini_alter,ini_get_all,ini_restore,inject_code,openlog,phpAds_remoteInfo,phpAds_XmlRpc,phpAds_xmlrpcDecode,phpAds_xmlrpcEncode,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_setuid,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,syslog,system,xmlrpc_entity_decode,curl_multi_exec' /etc/php.ini

    # Add mod_security
    yum -y install mod_security mod_security_crs mod_security_crs-extras

    # Allow access on IP for users that don't use FQDN's
    sed -i 's.</IfModule>.\n    SecRuleRemoveById 960017\n\n&.' /etc/httpd/conf.d/mod_security.conf

    # set X-XSS-Protection header
    sed -i 's.</VirtualHost>.Header set X-XSS-Protection "1; mode=block"\n\n&.' /etc/httpd/conf.d/ssl.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure SQLgrey
# http://sqlgrey.sourceforge.net/
# +---------------------------------------------------+
func_sqlgrey () {
    cd /usr/src/EFA
    useradd sqlgrey -m -d /home/sqlgrey -s /sbin/nologin
    wget $mirror/$mirrorpath/sqlgrey-1.8.0.tar.gz
    tar -xvzf sqlgrey-1.8.0.tar.gz
    cd sqlgrey-1.8.0
    make rh-install

    # pre-create the local files so users won't be confused if the file is not there.
    touch /etc/sqlgrey/clients_ip_whitelist.local
    touch /etc/sqlgrey/clients_fqdn_whitelist.local

    # Make the changes to the config file...
    sed -i '/conf_dir =/ c\conf_dir = /etc/sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i '/user =/ c\user = sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i '/group =/ c\group = sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i '/confdir =/ c\confdir = /etc/sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i '/connect_src_throttle =/ c\connect_src_throttle = 5' /etc/sqlgrey/sqlgrey.conf
    sed -i "/awl_age = 32/d" /etc/sqlgrey/sqlgrey.conf
    sed -i "/group_domain_level = 10/d" /etc/sqlgrey/sqlgrey.conf
    sed -i '/awl_age =/ c\awl_age = 60' /etc/sqlgrey/sqlgrey.conf
    sed -i '/group_domain_level =/ c\group_domain_level = 2' /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_type =/ c\db_type = mysql' /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_name =/ c\db_name = sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_host =/ c\db_host = localhost' /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_port =/ c\db_port = default' /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_user =/ c\db_user = sqlgrey' /etc/sqlgrey/sqlgrey.conf
    sed -i "/db_pass =/ c\db_pass = $password" /etc/sqlgrey/sqlgrey.conf
    sed -i '/db_cleandelay =/ c\db_cleandelay = 1800' /etc/sqlgrey/sqlgrey.conf
    sed -i '/clean_method =/ c\clean_method = sync' /etc/sqlgrey/sqlgrey.conf
    sed -i '/prepend =/ c\prepend = 1' /etc/sqlgrey/sqlgrey.conf
    sed -i "/reject_first_attempt\/reject_early_reconnect/d" /etc/sqlgrey/sqlgrey.conf
    sed -i '/reject_first_attempt =/ c\reject_first_attempt = immed' /etc/sqlgrey/sqlgrey.conf
    sed -i '/reject_early_reconnect =/ c\reject_early_reconnect = immed' /etc/sqlgrey/sqlgrey.conf
    sed -i "/reject_code = dunno/d" /etc/sqlgrey/sqlgrey.conf
    sed -i '/reject_code =/ c\reject_code = 451' /etc/sqlgrey/sqlgrey.conf
    sed -i '/whitelists_host =/ c\whitelists_host = sqlgrey.bouton.name' /etc/sqlgrey/sqlgrey.conf
    sed -i '/optmethod =/ c\optmethod = optout' /etc/sqlgrey/sqlgrey.conf

    # start and stop sqlgrey (first launch will create all database tables)
    # We give it 15 seconds to populate the database and then stop it again.
    service sqlgrey start
    sleep 15
    service sqlgrey stop
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MailWatch
# https://github.com/mailwatch/1.2.0
# +---------------------------------------------------+
func_mailwatch () {

    # Fetch MailWatch
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/MailWatch-1.2.0-$MAILWATCHBRANCH-GIT-$MAILWATCHVERSION.zip
    unzip -d . MailWatch-1.2.0-$MAILWATCHBRANCH-GIT-$MAILWATCHVERSION.zip
    cd 1.2.0-$MAILWATCHBRANCH

    # Set php parameters needed
    sed -i '/^short_open_tag =/ c\short_open_tag = On' /etc/php.ini

    # Set up connection for MailWatch
    cd MailScanner_perl_scripts
    sed -i "/^my (\$db_user) =/ c\my (\$db_user) = 'mailwatch';" MailWatch.pm
    # Issue #66 grab all passwords from EFA-Config
    #sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" MailWatch.pm
    sed -i "/^my (\$db_pass) =/ c\my (\$fh);\nmy (\$pw_config) = '/etc/EFA-Config';\nopen(\$fh, \"<\", \$pw_config);\nif(\!\$fh) {\n  MailScanner::Log::WarnLog(\"Unable to open %s to retrieve password\", \$pw_config);\n  return;\n}\nmy (\$db_pass) = grep(/^MAILWATCHSQLPWD/,<\$fh>);\n\$db_pass =~ s/MAILWATCHSQLPWD://;\n\$db_pass =~ s/\\\n//;\nclose(\$fh);" MailWatch.pm
    mv MailWatch.pm /usr/share/MailScanner/perl/custom/

    # Set up SQLBlackWhiteList
    sed -i "/^    my (\$db_user) =/ c\    my (\$db_user) = 'mailwatch';" SQLBlackWhiteList.pm
    #sed -i "/^  my(\$db_pass) =/ c\  my(\$db_pass) = '$password';" SQLBlackWhiteList.pm
    sed -i "/^    my (\$db_pass) =/ c\    my (\$fh);\nmy (\$pw_config) = '/etc/EFA-Config';\n    open(\$fh, \"<\", \$pw_config);\n    if(\!\$fh) {\n      MailScanner::Log::WarnLog(\"Unable to open %s to retrieve password\", \$pw_config);\n      return;\n    }\n    my (\$db_pass) = grep(/^MAILWATCHSQLPWD/,<\$fh>);\n    \$db_pass =~ s/MAILWATCHSQLPWD://;\n    \$db_pass =~ s/\\\n//;\n    close(\$fh);" SQLBlackWhiteList.pm
    mv SQLBlackWhiteList.pm /usr/share/MailScanner/perl/custom/

    # Set up SQLSpamSettings
    sed -i "/^my (\$db_user) =/ c\my (\$db_user) = 'mailwatch';" SQLSpamSettings.pm
    #sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" SQLSpamSettings.pm
    sed -i "/^my (\$db_pass) =/ c\my (\$fh);\nmy (\$pw_config) = '/etc/EFA-Config';\nopen(\$fh, \"<\", \$pw_config);\nif(\!\$fh) {\n  MailScanner::Log::WarnLog(\"Unable to open %s to retrieve password\", \$pw_config);\n  return;\n}\nmy (\$db_pass) = grep(/^MAILWATCHSQLPWD/,<\$fh>);\n\$db_pass =~ s/MAILWATCHSQLPWD://;\n\$db_pass =~ s/\\\n//;\nclose(\$fh);" SQLSpamSettings.pm
    mv SQLSpamSettings.pm /usr/share/MailScanner/perl/custom/


    # Set up MailWatch tools
    cd ..
    mkdir /usr/local/bin/mailwatch
    mv tools /usr/local/bin/mailwatch
    rm -f /usr/local/bin/mailwatch/tools/Cron_jobs/INSTALL
    chmod +x /usr/local/bin/mailwatch/tools/Cron_jobs/*
    touch /etc/cron.daily/mailwatch
    # Issue #166 MailWatch cron job not executing contents
    echo "#!/bin/bash" > /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/db_clean.php >> /dev/null 2>&1" >> /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_maint.php --clean >> /dev/null 2>&1" >> /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_report.php >> /dev/null 2>&1" >> /etc/cron.daily/mailwatch
    chmod +x /etc/cron.daily/mailwatch
    # Issue #30 filter non-spam from quarantine reports (regression fix)
    # sed -i "/^ ((to_address=%s) OR (to_domain=%s))$/ a\AND\n a.isspam>0" /usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_report.php

    # Move MailWatch into web root and configure
    mv mailscanner /var/www/html
    cd /var/www/html/mailscanner
    chown root:apache images
    chmod ug+rwx images
    chown root:apache images/cache
    chmod ug+rwx images/cache
    chown root:apache temp
    chmod ug+rwx temp

    # Remove the docs directory as it is not needed.
    rm -rf docs

    cp conf.php.example conf.php
    # Issue #66 grab all passwords from EFA-Config
    sed -i "/^define('DB_PASS',/ c\$efa_config = preg_grep('/^MAILWATCHSQLPWD/', file('/etc/EFA-Config'));\nforeach(\$efa_config as \$num => \$line) {\n  if (\$line) {\n    \$db_pass_tmp = chop(preg_replace('/^MAILWATCHSQLPWD:(.*)/','\$1', \$line));\n  }\n}\ndefine('DB_PASS', \$db_pass_tmp);" conf.php
    sed -i "/^define('DB_USER',/ c\define('DB_USER', 'mailwatch');" conf.php
    #sed -i "/^define('DB_PASS',/ c\define('DB_PASS', '$password');" conf.php
    sed -i "/^define('TIME_ZONE',/ c\define('TIME_ZONE', 'Etc/UTC');" conf.php
    sed -i "/^define('QUARANTINE_USE_FLAG',/ c\define('QUARANTINE_USE_FLAG', true);" conf.php
    sed -i "/^define('QUARANTINE_REPORT_FROM_NAME',/ c\define('QUARANTINE_REPORT_FROM_NAME', 'EFA - Email Filter Appliance');" conf.php
    sed -i "/^define('QUARANTINE_USE_SENDMAIL',/ c\define('QUARANTINE_USE_SENDMAIL', true);" conf.php
    sed -i "/^define('AUDIT',/ c\define('AUDIT', true);" conf.php
    sed -i "/^define('MS_LOG',/ c\define('MS_LOG', '/var/log/maillog');" conf.php
    sed -i "/^define('MAIL_LOG',/ c\define('MAIL_LOG', '/var/log/maillog');" conf.php
    sed -i "/^define('SA_DIR',/ c\define('SA_DIR', '/usr/bin/');" conf.php
    sed -i "/^define('SA_RULES_DIR',/ c\define('SA_RULES_DIR', '/etc/mail/spamassassin');" conf.php
    sed -i "/^define('SHOW_SFVERSION',/ c\define('SHOW_SFVERSION', false);" conf.php
    # Issue #109 Documentation tab present after MailWatch update testing
    sed -i "/^define('SHOW_DOC',/ c\define('SHOW_DOC', false);" conf.php
    # Issue #291 HIDE_UNKNOWN option for MailWatch
    sed -i "/^define('HIDE_UNKNOWN',/ c\define('HIDE_UNKNOWN', true);" conf.php
    # Issue #320 /root/.spamassassin inaccessible
    sed -i "/^define('SA_PREFS', MS_CONFIG_DIR . 'spam.assassin.prefs.conf');/ c\define('SA_PREFS', MS_CONFIG_DIR . 'spamassassin.conf');" conf.php

    # Set up a redirect in web root to MailWatch
    touch /var/www/html/index.html
    echo "<!DOCTYPE html>" > /var/www/html/index.html
    echo "<html>" >> /var/www/html/index.html
    echo " <head>" >> /var/www/html/index.html
    echo "  <title>MailWatch</title>" >> /var/www/html/index.html
    echo "  <meta http-equiv=\"refresh\" content=\"0; url=/mailscanner/\" />" >> /var/www/html/index.html
    echo " </head>" >> /var/www/html/index.html
    echo " <body>" >> /var/www/html/index.html
    echo "   <a href=\"/mailscanner/\">Click Here for MailWatch</a>" >> /var/www/html/index.html
    echo " </body>" >> /var/www/html/index.html
    echo "</html>" >> /var/www/html/index.html

    # Grabbing an favicon to complete the look
    cd /var/www/html/
    wget $mirror/static/favicon.ico
    # override cp -i alias
    /bin/cp -f favicon.ico /var/www/html/mailscanner/
    /bin/cp -f favicon.ico /var/www/html/mailscanner/images
    /bin/cp -f favicon.ico /var/www/html/mailscanner/images/favicon.png

    # EFA Branding
    cd /var/www/html/mailscanner/images
    wget --no-check-certificate $gitdlurl/EFA/EFAlogo-47px.gif
    wget --no-check-certificate $gitdlurl/EFA/EFAlogo-79px.png
    #mv mailwatch-logo.gif mailwatch-logo.gif.orig
    mv mailwatch-logo.png mailwatch-logo.png.orig
    mv mailscannerlogo.gif mailscannerlogo.gif.orig
    # png image looks much better -- linking to png instead
    ln -s EFAlogo-79px.png mailwatch-logo.png
    ln -s EFAlogo-47px.gif mailscannerlogo.gif
    ln -s EFAlogo-79px.png mailwatch-logo.gif

    # Issue #107 MailWatch login page shows Mailwatch logo and theme after update testing
    # mv mailwatch-logo-trans-307x84.png mailwatch-logo-trans-307x84.png.orig > /dev/null 2>&1
    # ln -s EFAlogo-79px.png mailwatch-logo-trans-307x84.png
    sed -i 's/#f7ce4a/#719b94/g' /var/www/html/mailscanner/login.php

    # Change the yellow to match website colors..
    sed -i 's/#F7CE4A/#719b94/g' /var/www/html/mailscanner/style.css

    # Add Mailgraph link and remove dnsreport link
    # Issue #39 Add link for Webmin in MailWatch
    cd /var/www/html/mailscanner
    cp other.php other.php.orig

    # Add munin to mailwatch
    sed -i "/^    echo '<li><a href=\"geoip_update.php\">/a\    /*Begin EFA*/\n    echo '<li><a href=\"mailgraph.php\">View Mailgraph Statistics</a>';\n    \$hostname = gethostname\(\);\n    echo '<li><a href=\"https://' \. \$hostname \. ':10000\">Webmin</a>';\n    \$efa_config = preg_grep('/^MUNINPWD/', file('/etc/EFA-Config'));\n    foreach(\$efa_config as \$num => \$line) {\n      if (\$line) {\n        \$munin_pass = chop(preg_replace('/^MUNINPWD:(.*)/','\$1', \$line));\n      }\n    }\n    echo '<li><a href=\"https://munin:' . \$munin_pass . '@'  . \$hostname . '/munin\">View Munin Statistics</a>';\n    /*End EFA*/" other.php

    # Issue #210 Add EFA Version to GUI
    #sed -i '/^        <\/form>/{n;s/$/\n        \$filever = fopen("\/etc\/EFA-Version", "r");\n        echo "<h5 #style=\\\"width:300px;text-align:center\\\">Version " . fgets(\$filever) . "<\/h5>";\n        fclose($filever);/}' #/var/www/html/mailscanner/login.php
    # Issue #331 Move Version into Mailwatch
    # Issue #346
    cat >> /var/www/html/mailscanner/functions.php << EOF
/**
 * EFA Version
 */
function efa_version()
{
  return file_get_contents( '/etc/EFA-Version', NULL, NULL, 0, 15 );
}
EOF
      sed -i "/^    echo mailwatch_version/a \    echo ' running on ' . efa_version();" /var/www/html/mailscanner/functions.php

    # Issue #308 ClamAV Status Page blank
    usermod apache -G mtagroup

    # Postfix Relay Info
########################################################################
  cat > /etc/cron.hourly/mailwatch_relay.sh << 'EOF'
#!/bin/bash

/usr/bin/php /var/www/html/mailscanner/postfix_relay.php --refresh
/usr/bin/php /var/www/html/mailscanner/mailscanner_relay.php --refresh
EOF
########################################################################
    chmod 755 /etc/cron.hourly/mailwatch_relay.sh

    # Place the learn and release scripts
    cd /var/www/cgi-bin
    wget --no-check-certificate $gitdlurl/EFA/learn-msg.cgi
    wget --no-check-certificate $gitdlurl/EFA/release-msg.cgi
    chmod 755 learn-msg.cgi
    chmod 755 release-msg.cgi
    cd /var/www/html
    wget --no-check-certificate $gitdlurl/EFA/released.html
    wget --no-check-certificate $gitdlurl/EFA/notreleased.html
    wget --no-check-certificate $gitdlurl/EFA/learned.html
    wget --no-check-certificate $gitdlurl/EFA/notlearned.html
    wget --no-check-certificate $gitdlurl/EFA/denylearned.html

    # MailWatch requires access to /var/spool/postfix/hold & incoming dir's
    chown -R postfix:apache /var/spool/postfix/hold
    chown -R postfix:apache /var/spool/postfix/incoming
    chmod -R 750 /var/spool/postfix/hold
    chmod -R 750 /var/spool/postfix/incoming

    # Allow apache to sudo and run the MailScanner lint test
    sed -i '/Defaults    requiretty/ c\#Defaults    requiretty' /etc/sudoers
    echo "apache ALL=NOPASSWD: /usr/sbin/MailScanner --lint" > /etc/sudoers.d/EFA-Services

    # Issue #72 EFA MSRE Support
    sed -i "/^define('MSRE'/ c\define('MSRE', true);" /var/www/html/mailscanner/conf.php
    chgrp -R apache /etc/MailScanner/rules
    chmod g+rwxs /etc/MailScanner/rules
    chmod g+rw /etc/MailScanner/rules/*.rules
    ln -s /usr/local/bin/mailwatch/tools/Cron_jobs/msre_reload.crond /etc/cron.d/msre_reload.crond
    ln -s /usr/local/bin/mailwatch/tools/MailScanner_rule_editor/msre_reload.sh /usr/local/bin/msre_reload.sh
    chmod ugo+x /usr/local/bin/mailwatch/tools/MailScanner_rule_editor/msre_reload.sh

    # Install Encoding:FixLatin perl module for mailwatch UTF8 support
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/Encoding-FixLatin-1.04.tar.gz
    tar xzvf /usr/src/EFA/Encoding-FixLatin-1.04.tar.gz
    cd /usr/src/EFA/Encoding*
    perl Makefile.PL
    make
    make install

    # Issue #322 Geoip update during EFA-Init
    wget -O /usr/local/sbin/geoip_update_cmd.php $gitdlurl/EFA/geoip_update_cmd.php

    # Add mailwatch version to EFA-Config
    echo "MAILWATCHVERSION:$MAILWATCHVERSION" >> /etc/EFA-Config

    # Fix menu width
    # sed -i '/^#menu {$/ a\    min-width:1000px;' /var/www/html/mailscanner/style.css
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# SQLGrey Web Interface
# http://www.vanheusden.com/sgwi
# +---------------------------------------------------+
func_sgwi () {
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/sqlgreywebinterface-1.1.6.tgz
    tar -xzvf sqlgreywebinterface-1.1.6.tgz
    cd sqlgreywebinterface-1.1.6
    # Place next to mailwatch
    mkdir /var/www/html/sgwi
    mv * /var/www/html/sgwi

    # add db credential
    # Issue #66 Grab all passwords from EFA-Config
    sed -i "/^\$db_pass/ c\$efa_array = preg_grep('/^SQLGREYSQLPWD/', file('/etc/EFA-Config'));\nforeach(\$efa_array as \$num => \$line) {\n  if (\$line) {\n    \$db_pass = chop(preg_replace('/^SQLGREYSQLPWD:(.*)/','\$1',\$line));\n  }\n}" /var/www/html/sgwi/includes/config.inc.php

    # Add greylist to mailwatch menu
    # hide from non-admins
    sed -i "/^        \$nav\['docs.php'\] =/{N;s/$/\n        \/\/Begin EFA\n        if \(\$_SESSION\['user_type'\] == 'A' \&\& SHOW_GREYLIST == true\) \{\n            \$nav\['grey.php'\] = \"greylist\";\n        \}\n        \/\/End EFA/}" /var/www/html/mailscanner/functions.php

    # add SHOW_GREYLIST to conf.php
    echo "" >> /var/www/html/mailscanner/conf.php
    echo "// Greylisting menu item" >> /var/www/html/mailscanner/conf.php
    echo "define('SHOW_GREYLIST', true);" >> /var/www/html/mailscanner/conf.php

    # Create wrapper
    touch /var/www/html/mailscanner/grey.php
    echo "<?php" > /var/www/html/mailscanner/grey.php
    echo "" >> /var/www/html/mailscanner/grey.php
    echo "require_once(\"./functions.php\");" >> /var/www/html/mailscanner/grey.php
    echo "session_start();" >> /var/www/html/mailscanner/grey.php
    echo "require('login.function.php');" >> /var/www/html/mailscanner/grey.php
    echo "\$refresh = html_start(\"greylist\",0,false,false);" >> /var/www/html/mailscanner/grey.php
    echo "?>" >> /var/www/html/mailscanner/grey.php
    echo "<iframe src=\"../sgwi/index.php\" width=\"960px\" height=\"1024px\">" >> /var/www/html/mailscanner/grey.php
    echo " <a href=\"..\sgwi/index.php\">Click here for SQLGrey Web Interface</a>" >> /var/www/html/mailscanner/grey.php
    echo "</iframe>" >> /var/www/html/mailscanner/grey.php
    echo "<?php" >> /var/www/html/mailscanner/grey.php
    echo "html_end();" >> /var/www/html/mailscanner/grey.php
    echo "dbclose();" >> /var/www/html/mailscanner/grey.php

    # Secure sgwi from direct access
    cd /var/www/html/sgwi
    ln -s ../mailscanner/login.function.php login.function.php
    ln -s ../mailscanner/login.php login.php
    ln -s ../mailscanner/functions.php functions.php
    ln -s ../mailscanner/checklogin.php checklogin.php
    ln -s ../mailscanner/conf.php conf.php
    mkdir images
    ln -s ../../mailscanner/images/EFAlogo-79px.png ./images/mailwatch-logo.png
    cp ../mailscanner/images/favicon.png ./images/favicon.png
    sed -i "/^<?php/ a\//Begin EFA\nsession_start();\nrequire('login.function.php');\n\nif (\$_SESSION['user_type'] != 'A') die('Access Denied');\n//End EFA" /var/www/html/sgwi/index.php
    sed -i "/^<?php/ a\//Begin EFA\nsession_start();\nrequire('login.function.php');\n\nif (\$_SESSION['user_type'] != 'A') die('Access Denied');\n//End EFA" /var/www/html/sgwi/awl.php
    sed -i "/^<?php/ a\//Begin EFA\nsession_start();\nrequire('login.function.php');\n\nif (\$_SESSION['user_type'] != 'A') die('Access Denied');\n//End EFA" /var/www/html/sgwi/connect.php
    sed -i "/^<?php/ a\//Begin EFA\nsession_start();\nrequire('login.function.php');\n\nif (\$_SESSION['user_type'] != 'A') die('Access Denied');\n//End EFA" /var/www/html/sgwi/opt_in_out.php

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Mailgraph
# http://mailgraph.schweikert.ch
# +---------------------------------------------------+
func_mailgraph () {
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/mailgraph-1.14.tar.gz
    tar xvzf mailgraph-1.14.tar.gz
    cd mailgraph-1.14

    mv mailgraph.cgi /var/www/cgi-bin/
    mv mailgraph.pl /usr/local/bin/
    mv mailgraph-init /etc/init.d/
    mv mailgraph.css /var/www/html
    chmod 0755 /etc/init.d/mailgraph-init
    chmod 0755 /var/www/cgi-bin/mailgraph.cgi

    #change css path
    sed -i '/^<link rel="stylesheet" href="mailgraph.css"/ c\<link rel="stylesheet" href="../mailgraph.css" type="text/css" />' /var/www/cgi-bin/mailgraph.cgi

    sed -i '/^MAIL_LOG=/ c\MAIL_LOG=\/var\/log\/maillog' /etc/init.d/mailgraph-init
    sed -i "/^my \$rrd =/ c\my \$rrd = \'\/var\/lib\/mailgraph.rrd\'\;" /var/www/cgi-bin/mailgraph.cgi
    sed -i "/^my \$rrd_virus =/ c\my \$rrd_virus = \'\/var\/lib\/mailgraph_virus.rrd\'\;" /var/www/cgi-bin/mailgraph.cgi

    # Mailgraph security modifications
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/PHP-Session-0.27.tar.gz
    wget $mirror/$mirrorpath/UNIVERSAL-require-0.15.tar.gz
    wget $mirror/$mirrorpath/CGI-Lite-2.02.tar.gz
    tar -xzvf UNIVERSAL-require-0.15.tar.gz
    cd UNIVERSAL-require-0.15
    perl Makefile.PL
    make
    make test
    make install
    cd ..
    tar -xzvf PHP-Session-0.27.tar.gz
    cd PHP-Session-0.27
    perl Makefile.PL
    make
    make test
    make install
    cd ..
    tar -xzvf CGI-Lite-2.02.tar.gz
    cd CGI-Lite-2.02
    perl Makefile.PL
    make
    make install

    sed -i "/^my \$VERSION = \"1.14\";/ a\# Begin EFA\nuse PHP::Session;\nuse CGI::Lite;\n\neval {\n  my \$session_name='PHPSESSID';\n  my \$cgi=new CGI::Lite;\n  my \$cookies = \$cgi->parse_cookies;\n  if (\$cookies->{\$session_name}) {\n    my \$session = PHP::Session->new(\$cookies->{\$session_name},{save_path => '/var/lib/php/session/'});\n    if (\$session->get('user_type') ne 'A') {\n      print \"Access Denied\";\n      exit;\n    }\n  } else {\n    print\"Access Denied\";\n    exit;\n  }\n};\nif (\$@) {\n  die(\"Access Denied\");\n}\n# End EFA" /var/www/cgi-bin/mailgraph.cgi

    # Create wrapper
    touch /var/www/html/mailscanner/mailgraph.php
    echo "<?php" > /var/www/html/mailscanner/mailgraph.php
    echo "" >> /var/www/html/mailscanner/mailgraph.php
    echo "require_once(\"./functions.php\");" >> /var/www/html/mailscanner/mailgraph.php
    echo "session_start();" >> /var/www/html/mailscanner/mailgraph.php
    echo "require('login.function.php');" >> /var/www/html/mailscanner/mailgraph.php
    echo "\$refresh = html_start(\"Tools/Links\",0,false,false);" >> /var/www/html/mailscanner/mailgraph.php
    echo "?>" >> /var/www/html/mailscanner/mailgraph.php
    echo "<iframe src=\"../cgi-bin/mailgraph.cgi\" width=\"960px\" height=\"1024px\">" >> /var/www/html/mailscanner/mailgraph.php
    echo " <a href=\"../cgi-bin/mailgraph.php\">Click here for Mailgraph Statistics</a>" >> /var/www/html/mailscanner/mailgraph.php
    echo "</iframe>" >> /var/www/html/mailscanner/mailgraph.php
    echo "<?php" >> /var/www/html/mailscanner/mailgraph.php
    echo "html_end();" >> /var/www/html/mailscanner/mailgraph.php
    echo "dbclose();" >> /var/www/html/mailscanner/mailgraph.php

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install Pyzor
# http://downloads.sourceforge.net/project/pyzor/pyzor/0.5.0/pyzor-0.5.0.tar.gz
# +---------------------------------------------------+
func_pyzor () {

    cd /usr/src/EFA
    wget $mirror/$mirrorpath/pyzor-$PYZORVERSION.tar.gz
    tar xvzf pyzor-$PYZORVERSION.tar.gz
    cd pyzor-$PYZORVERSION
    python setup.py build
    python setup.py install

    # Fix deprecation warning message
    sed -i '/^#!\/usr\/bin\/python/ c\#!\/usr\/bin\/python -Wignore::DeprecationWarning' /usr/bin/pyzor

    mkdir /var/spool/postfix/.pyzor
    ln -s /var/spool/postfix/.pyzor /var/www/.pyzor
    chown -R postfix:apache /var/spool/postfix/.pyzor
    chmod -R ug+rwx /var/spool/postfix/.pyzor

    # and finally initialize the servers file with an discover.
    su postfix -s /bin/bash -c 'pyzor discover'

    # Add version to EFA-Config
    echo "PYZORVERSION:$PYZORVERSION" >> /etc/EFA-Config
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install Razor (http://razor.sourceforge.net/)
# +---------------------------------------------------+
func_razor () {
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/razor-agents-2.84.tar.bz2
    tar xvjf razor-agents-2.84.tar.bz2
    cd razor-agents-2.84

    perl Makefile.PL
    make
    make test
    make install

    mkdir /var/spool/postfix/.razor
    ln -s /var/spool/postfix/.razor /var/www/.razor
    chown postfix:apache /var/spool/postfix/.razor
    chmod -R ug+rwx /var/spool/postfix/.razor

    # Issue #157 Razor failing after registration of service
    # Use setgid bit
    chmod ug+s /var/spool/postfix/.razor
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install DCC http://www.rhyolite.com/dcc/
# (current version = version 1.3.154, December 03, 2013)
# +---------------------------------------------------+
func_dcc () {
    cd /usr/src/EFA

    wget $mirror/$mirrorpath/dcc-1.3.154.tar.Z
    tar xvzf dcc-1.3.154.tar.Z
    cd dcc-*

    ./configure --disable-dccm
    make install

    ln -s /var/dcc/libexec/cron-dccd /usr/bin/cron-dccd
    ln -s /var/dcc/libexec/cron-dccd /etc/cron.monthly/cron-dccd
    echo "dcc_home /var/dcc" >> /etc/MailScanner/spamassassin.conf
    sed -i '/^dcc_path / c\dcc_path /usr/local/bin/dccproc' /etc/MailScanner/spamassassin.conf
    sed -i '/^DCCIFD_ENABLE=/ c\DCCIFD_ENABLE=on' /var/dcc/dcc_conf
    sed -i '/^DBCLEAN_LOGDAYS=/ c\DBCLEAN_LOGDAYS=1' /var/dcc/dcc_conf
    sed -i '/^DCCIFD_LOGDIR=/ c\DCCIFD_LOGDIR="/var/dcc/log"' /var/dcc/dcc_conf
    chown postfix:postfix /var/dcc

    cp /var/dcc/libexec/rcDCC /etc/init.d/adcc
    sed -i "s/#loadplugin Mail::SpamAssassin::Plugin::DCC/loadplugin Mail::SpamAssassin::Plugin::DCC/g" /etc/mail/spamassassin/v310.pre
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# imageCerberus to replace fuzzyocr
# http://sourceforge.net/projects/imagecerberus/
# +---------------------------------------------------+
func_imagecerberus () {
    cd /usr/src/EFA
    wget $mirror/$mirrorpath/imageCerberus-v$IMAGECEBERUSVERSION.zip
    unzip imageCerberus-v$IMAGECEBERUSVERSION.zip
    cd imageCerberus-v$IMAGECEBERUSVERSION
    mkdir /etc/spamassassin
    mv spamassassin/imageCerberus /etc/spamassassin/
    rm -f /etc/spamassassin/imageCerberus/imageCerberusEXE
    mv /etc/spamassassin/imageCerberus/x86_64/imageCerberusEXE /etc/spamassassin/imageCerberus/
    rm -rf /etc/spamassassin/imageCerberus/x86_64
    rm -rf /etc/spamassassin/imageCerberus/i386

    # Issue #245 Move ImageCerberus to correct (new) location
    mv spamassassin/ImageCerberusPLG.pm /usr/share/perl5/vendor_perl/Mail/SpamAssassin/Plugin/
    mv spamassassin/ImageCerberusPLG.cf /etc/mail/spamassassin/
    sed -i '/^loadplugin ImageCerberusPLG / c\loadplugin ImageCerberusPLG /usr/share/perl5/vendor_perl/Mail/SpamAssassin/Plugin/ImageCerberusPLG.pm' /etc/mail/spamassassin/ImageCerberusPLG.cf

    # fix a few library locations
    ln -s /usr/lib64/libcv.so.2.0 /usr/lib64/libcv.so.1
    ln -s /usr/lib64/libhighgui.so.2.0 /usr/lib64/libhighgui.so.1
    ln -s /usr/lib64/libcxcore.so.2.0 /usr/lib64/libcxcore.so.1
    ln -s /usr/lib64/libcvaux.so.2.0 /usr/lib64/libcvaux.so.1

    # Issue 67 default ImageCeberus score
    sed -i "/^score     ImageCerberusPLG0/ c\score     ImageCerberusPLG0     0.0  0.0  0.0  0.0" /etc/mail/spamassassin/ImageCerberusPLG.cf
    # Issue #284 Lower ImageCerberus Scores by default
    sed -i "/^score     ImageCerberusPLG1/ c\score     ImageCerberusPLG1     0.1  0.1  0.1  0.1" /etc/mail/spamassassin/ImageCerberusPLG.cf
    sed -i "/^score     ImageCerberusPLG2/ c\score     ImageCerberusPLG2     0.2  0.2  0.2  0.2" /etc/mail/spamassassin/ImageCerberusPLG.cf
    sed -i "/^score     ImageCerberusPLG3/ c\score     ImageCerberusPLG3     0.3  0.3  0.3  0.3" /etc/mail/spamassassin/ImageCerberusPLG.cf
    sed -i "/^score     ImageCerberusPLG4/ c\score     ImageCerberusPLG4     0.4  0.4  0.4  0.4" /etc/mail/spamassassin/ImageCerberusPLG.cf
    sed -i "/^score     ImageCerberusPLG5/ c\score     ImageCerberusPLG5     0.5  0.5  0.5  0.5" /etc/mail/spamassassin/ImageCerberusPLG.cf

    # Add the version to EFA-Config
    echo "IMAGECEBERUSVERSION:$IMAGECEBERUSVERSION" >> /etc/EFA-Config
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Webmin (http://www.webmin.com/)
# +---------------------------------------------------+
func_webmin () {
    # Pulled from EFA Repo instead ;)
    #cd /usr/src/EFA
    #wget $mirror/$mirrorpath/webmin-$WEBMINVERSION.noarch.rpm
    #rpm -i webmin-$WEBMINVERSION.noarch.rpm

    # shoot a hole in webmin so we can change settings
    echo "localauth=/usr/sbin/lsof" >> /etc/webmin/miniserv.conf
    echo "referer=1" >> /etc/webmin/config
    echo "referers=" >> /etc/webmin.config
    sed -i '/^referers_none=1/ c\referers_none=0' /etc/webmin/config
    service webmin restart

    # Remove modules we don't need.
    curl -k  --tlsv1.2 "https://localhost:10000/webmin/delete_mod.cgi?mod=adsl-client&mod=bacula-backup&mod=burner&mod=pserver&mod=cluster-copy&mod=exim&mod=shorewall6&mod=sendmail&confirm=Delete&acls=1&nodeps="
    curl -k  --tlsv1.2 "https://localhost:10000/webmin/delete_mod.cgi?mod=cluster-webmin&mod=bandwidth&mod=cluster-passwd&mod=cluster-cron&mod=cluster-shell&mod=cluster-usermin&mod=cluster-useradmin&confirm=Delete&acls=1&nodeps="
    curl -k  --tlsv1.2 "https://localhost:10000/webmin/delete_mod.cgi?mod=cfengine&mod=dhcpd&mod=dovecot&mod=fetchmail&mod=filter&mod=frox&mod=tunnel&mod=heartbeat&mod=ipsec&mod=jabber&mod=krb5&confirm=Delete&acls=1&nodeps="
    curl -k  --tlsv1.2 "https://localhost:10000/webmin/delete_mod.cgi?mod=ldap-client&mod=ldap-server&mod=ldap-useradmin&mod=firewall&mod=mon&mod=majordomo&mod=exports&mod=openslp&mod=pap&mod=ppp-client&mod=pptp-client&mod=pptp-server&mod=postgresql&confirm=Delete&acls=1&nodeps="
    curl -k  --tlsv1.2 "https://localhost:10000/webmin/delete_mod.cgi?mod=lpadmin&mod=proftpd&mod=procmail&mod=qmailadmin&mod=smart-status&mod=samba&mod=shorewall&mod=sarg&mod=squid&mod=usermin&mod=vgetty&mod=wuftpd&mod=webalizer&confirm=Delete&acls=1&nodeps="

    # fix the holes again
    sed -i '/^referers_none=0/ c\referers_none=1' /etc/webmin/config
    sed -i '/referer=1/d' /etc/webmin/config
    sed -i '/referers=/d' /etc/webmin/config
    sed -i '/localauth=\/usr\/sbin\/lsof/d' /etc/webmin/miniserv.conf
    service webmin restart

    # Add version to EFA-Config
    echo "WEBMINVERSION:$WEBMINVERSION" >> /etc/EFA-Config
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Unbound (replaces dnsmasq)
# +---------------------------------------------------+
func_unbound () {
    yum -y install unbound
    # disable ipv6 support in unbound
    sed -i "/^\t# do-ip6: yes/ c\\\tdo-ip6: no" /etc/unbound/unbound.conf

    # disable validator
    sed -i "/^\t# module-config:/ c\\\tmodule-config: \"iterator\"" /etc/unbound/unbound.conf

    echo "forward-zone:" > /etc/unbound/conf.d/forwarders.conf
    echo '  name: "."' >> /etc/unbound/conf.d/forwarders.conf
    echo "  forward-addr: 8.8.8.8" >> /etc/unbound/conf.d/forwarders.conf
    echo "  forward-addr: 8.8.4.4" >> /etc/unbound/conf.d/forwarders.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Munin
# +---------------------------------------------------+
func_munin () {
    yum -y install munin
    sed -i '/^my $graph_width = / c\my $graph_width = $ENV{'"'graph_width'"'} ? $ENV{'"'graph_width'"'} : 800;' /usr/share/munin/plugins/diskstats
    sed -i 's/.*#max_size_y 4000/&\ngraph_width 800/' /etc/munin/munin.conf

    cat > /etc/httpd/conf.d/munin.conf << 'EOF'
  <directory /var/www/html/munin/localhost/localhost>
      Order allow,deny
      Allow from all
      Satisfy any
  </directory>

  <directory /var/www/html/munin>
      AuthUserFile /etc/munin/munin-htpasswd
      AuthName "Munin"
      AuthType Basic
      require valid-user
  </directory>
EOF
    # End writing apache config file

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# kernel settings
# +---------------------------------------------------+
func_kernsettings () {
    sed -i '/net.bridge.bridge-nf-call-/d' /etc/sysctl.conf
    echo -e "# IPv6 \nnet.ipv6.conf.all.disable_ipv6 = 1 \nnet.ipv6.conf.default.disable_ipv6 = 1 \nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -q -p
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
    chkconfig abrtd off
    chkconfig portreserve off
    # auditd is something for an future release..
    chkconfig auditd off

    # These services we disable for now and enable them after EFA-Init.
    # Most of these are not enabled by default but add them here just to
    # make sure we don't forget them at EFA-Init.
    chkconfig mailscanner off
    chkconfig postfix off
    chkconfig httpd off
    chkconfig mysqld off
    chkconfig saslauthd off
    chkconfig crond off
    chkconfig clamd off
    chkconfig sqlgrey off
    chkconfig mailgraph-init off
    chkconfig adcc off
    chkconfig webmin off
    chkconfig unbound off
    chkconfig munin-node off
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# EFA specific customization
# +---------------------------------------------------+
func_efarequirements () {
    # Write version file
    echo "EFA-$version" > /etc/EFA-Version

    # pre-create the EFA update directory
    mkdir -p /var/EFA/update

    # pre-create the EFA backup directory
    mkdir -p /var/EFA/backup
    mkdir -p /var/EFA/backup/KAM

    # pre-create the EFA lib directory
    mkdir -p /var/EFA/lib
    mkdir -p /var/EFA/lib/EFA-Configure

    # pre-create the EFA Trusted Networks Config
    touch /etc/sysconfig/EFA_trusted_networks

    # write issue file
    echo "" > /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "--- Welcome to EFA-$version ---" >> /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "  http://www.efa-project.org  " >> /etc/issue
    echo "------------------------------" >> /etc/issue
    echo "" >> /etc/issue
    echo "First time login: root/EfaPr0j3ct" >> /etc/issue

    # Grab EFA specific scripts/programs
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-Init $gitdlurl/EFA/EFA-Init
    chmod 700 /usr/local/sbin/EFA-Init
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-Configure $gitdlurl/EFA/EFA-Configure
    chmod 700 /usr/local/sbin/EFA-Configure
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-Update $gitdlurl/EFA/EFA-Update
    chmod 700 /usr/local/sbin/EFA-Update
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-SA-Update $gitdlurl/EFA/EFA-SA-Update
    chmod 700 /usr/local/sbin/EFA-SA-Update
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-MS-Update $gitdlurl/EFA/EFA-MS-Update
    chmod 700 /usr/local/sbin/EFA-MS-Update
    /usr/bin/wget --no-check-certificate -O /usr/local/sbin/EFA-Backup $gitdlurl/EFA/EFA-Backup
    chmod 700 /usr/local/sbin/EFA-Backup

    # Grab the EFA-Configure libraries
    cd /usr/src/EFA/
    wget --no-check-certificate $gitdlurl/EFA/lib-EFA-Configure/libraries-filelist.txt
    for lib in `cat /usr/src/EFA/libraries-filelist.txt`
      do
        /usr/bin/wget --no-check-certificate -O /var/EFA/lib/EFA-Configure/$lib $gitdlurl/EFA/lib-EFA-Configure/$lib
    done
    chmod 600 /var/EFA/lib/EFA-Configure/*

    # Write SSH banner
    sed -i "/^#Banner / c\Banner /etc/banner"  /etc/ssh/sshd_config
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

  # Set the system as unconfigured
    sed -i '1i\CONFIGURED:NO' /etc/EFA-Config

    # Set EFA-Init to run at first root login:
    sed -i '1i\\/usr\/local\/sbin\/EFA-Init' /root/.bashrc
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Cron settings
# +---------------------------------------------------+
func_cron () {
    /usr/bin/wget --no-check-certificate -O /etc/cron.daily/EFA-Daily-cron $gitdlurl/EFA/EFA-Daily-cron
    chmod 700 /etc/cron.daily/EFA-Daily-cron
    /usr/bin/wget --no-check-certificate -O /etc/cron.monthly/EFA-Monthly-cron  $gitdlurl/EFA/EFA-Monthly-cron
    chmod 700 /etc/cron.monthly/EFA-Monthly-cron
    /usr/bin/wget --no-check-certificate -O /etc/cron.daily/EFA-Backup-cron  $gitdlurl/EFA/EFA-Backup-cron
    chmod 700 /etc/cron.daily/EFA-Backup-cron
    # Remove the raid-check util (Issue #102)
    rm -f /etc/cron.d/raid-check
    # Issue #187 EFA service Monitoring
    /usr/bin/wget --no-check-certificate -O /usr/sbin/EFA-Monitor-cron $gitdlurl/EFA/EFA-Monitor-cron
    chmod 700 /usr/sbin/EFA-Monitor-cron
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Clean-up
# +---------------------------------------------------+
func_cleanup () {
    # Clean SSH keys (generate at first boot)
    /bin/rm -f /etc/ssh/ssh_host_*

    # Secure SSH
    sed -i '/^#PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config

    # clear dns entries
    echo "" > /etc/resolv.conf

    # Stop running services to allow kickstart to reboot
    service mysqld stop
    service webmin stop

    # clear source files
    rm -rf /usr/src/EFA/*

    # clean yum cache
    yum clean all

    # Issue #96 Reconfigure to permit yum update
    echo "exclude=$yumexclude" >> /etc/yum.conf

    # clear logfiles
    rm -f /var/log/clamav/freshclam.log
    rm -f /var/log/messages
    touch /var/log/messages
    chmod 600 /var/log/messages
    rm -f /var/log/clamav-unofficial-sigs.log
    rm -f /var/log/cron
    touch /var/log/cron
    chmod 600 /var/log/cron
    rm -f /var/log/dmesg.old
    rm -f /var/log/dracut.log
    rm -f /var/log/httpd/*
    rm -f /var/log/maillog
    touch /var/log/maillog
    chmod 600 /var/log/maillog
    rm -f /var/log/mysqld.log
    touch /var/log/mysqld.log
    chown mysql:mysql /var/log/mysqld.log
    chmod 640 /var/log/mysqld.log
    rm -f /var/log/yum.log
    touch /var/log/yum.log
    chmod 600 /var/log/yum.log
    touch /var/log/clamav/freshclam.log
    chmod 600 /var/log/clamav/freshclam.log
    chown clam:clam /var/log/clamav/freshclam.log
    touch /var/log/clamav/clamd.log
    chmod 600 /var/log/clamav/clamd.log
    chown clam:clam /var/log/clamav/clamd.log

    # Clean root
    rm -f /root/anaconda-ks.cfg
    rm -f /root/install.log
    rm -f /root/install.log.syslog

    # Clean tmp
    rm -rf /tmp/*

    # Clean networking in preparation for creating VM Images
    # TODO don't clean if we run from a VPS install where a static IP is needed.
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    echo -e "DEVICE=eth0" > /etc/sysconfig/network-scripts/ifcfg-eth0
    echo -e "BOOTPROTO=dhcp" >> /etc/sysconfig/network-scripts/ifcfg-eth0

    # SELinux is giving me headaches disabling until everything works correctly
    # When everything works we should enable SELinux and try to fix all permissions..
    sed -i '/SELINUX=enforcing/ c\SELINUX=disabled' /etc/selinux/config
    # Fix SE-Linux security issues
    #restorecon -r /var/www
    #chcon -v --type=httpd_sys_content_t /var/lib/mailgraph*
    # todo: figure out which se-linux items needs to be changed to allow clamd access to /var/spool/MailScanner/incoming/*..
    #       Currently se-linux blocks clamd.
    #       (denied  { read } for  pid=4083 comm="clamd" name="3899" dev=tmpfs ino=23882 scontext=unconfined_u:system_r:antivirus_t:s0 tcontext=unconfined_u:object_r:var_spool_t:s0 tclass=dir

    # Remove boot splash so we can see whats going on while booting and set console reso to 800x600
    sed -i 's/\<rhgb quiet\>/ vga=771/g' /boot/grub/grub.conf

    # zero disks for better compression (when creating VM images)
    # this can take a while so disabled for now until we start creating images.
    # TODO make this not happen if we run the script from a VPS install
    dd if=/dev/zero of=/filler bs=1000
    rm -f /filler
    dd if=/dev/zero of=/tmp/filler bs=1000
    rm -f /tmp/filler
    dd if=/dev/zero of=/boot/filler bs=1000
    rm -f /boot/filler
    dd if=/dev/zero of=/var/filler bs=1000
    rm -f /var/filler

}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Main logic (this is where we start calling out functions)
# +---------------------------------------------------+

# +---------------------------------------------------+
#-----------------------------------------------------------------------------#
# Main function
#-----------------------------------------------------------------------------#
function main() {
  # If $action is empty we run the normal setup
  if [[ -z "$action" ]]; then
    func_prebuild
    func_upgradeOS
    func_epelrepo
    func_efarepo
    func_mysql
    func_postfix
    func_mailscanner
    func_spam_clamav
    func_apache
    func_sqlgrey
    func_mailwatch
    func_sgwi
    func_mailgraph
    func_pyzor
    func_razor
    func_dcc
    func_imagecerberus
    func_webmin
    func_unbound
    func_munin
    func_kernsettings
    func_services
    func_efarequirements
    func_cron
    func_cleanup
  elif [[ "$action" == "--frontend" ]]; then
    # If $action is --frontend, we do a frontend only install.
    func_prebuild
    func_upgradeOS
    func_efarepo
    func_epelrepo
    func_postfix
    func_mailscanner
    func_spam_clamav
    func_pyzor
    func_razor
    func_dcc
    func_imagecerberus
    func_unbound
    func_kernsettings
    func_services
    func_efarequirements
    func_cron
    func_cleanup
  fi
}
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Run the main script
#-----------------------------------------------------------------------------#
main
#-----------------------------------------------------------------------------#
