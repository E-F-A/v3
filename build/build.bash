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

# Todo:
# grabb all installation files and place them on dl.efa-project.org
#   some servers are very slow (dcc for example) causing installations
#   to fail, having it all on dl.efa-project.org will be faster and
#   will save us the trouble if files become unavailable from the official
#   website (version change for example, which might cause problems)
#       This is something we can do as an final stage.

# fuzzyocr project seems to be dead (since 2009)
# Don't know if it is wise to add it as it has lots of dependancy's.
# http://wiki.apache.org/spamassassin/FuzzyOcrPlugin
# 
# Would Bayes OCR and Image Cerberus Plugin be a good substitute?
# http://pralab.diee.unica.it/en/BayesOCR
# http://pralab.diee.unica.it/imageCerberus


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
    yum install -y tnef perl-BerkeleyDB perl-Convert-TNEF perl-Filesys-Df Perl-File-Tail perl-IO-Multiplex perl-IP-Country perl-Mail-SPF-Query perl-Net-CIDR perl-Net-Ident perl-Net-Server perl-Net-LDAP perl-File-Tail
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MySQL
# +---------------------------------------------------+
func_mysql () {
    echo "Mysql configuration"
    service mysqld start

    # BDB support is removed from MYSQL 5.1, so those variables are gone
    # (does anything depend on perl-BerkeleyDB or BDB in general?)
    # Guess you are right, don't see any reason for BDB to be there
    # AWL used BDB in a previous version but that is moved to MySQL.
    
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
    # https://raw.github.com/endelwar/mailwatch/master/tools/create_relay_postfix.sql
    cd /tmp
    /usr/bin/wget -q $gitdlurl/MYSQL/create.sql
    /usr/bin/mysql -u root -p"$password" < /tmp/create.sql
    /usr/bin/wget -q $gitdlurl/MYSQL/create_relay_postfix.sql
    /usr/bin/mysql -u root -p"$password" mailscanner < /tmp/create_relay_postfix.sql

    # Create the users
    /usr/bin/mysql -u root -p"$password" -e "GRANT SELECT,INSERT,UPDATE,DELETE on sa_bayes.* to 'sa_user'@'localhost' identified by '$password'"
    
    # mailwatch mysql user and login user
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL ON mailscanner.* TO mailwatch@localhost IDENTIFIED BY '$password';"
    /usr/bin/mysql -u root -p"$password" -e "GRANT FILE ON *.* to mailwatch@localhost IDENTIFIED BY '$password';" 
    /usr/bin/mysql -u root -p"$password" mailscanner -e "INSERT INTO users SET username = 'admin', password = md5('$password'), fullname = 'Administrator', type ='A'" 
    
    # sqlgrey user
    /usr/bin/mysql -u root -p"$password" -e "GRANT ALL on sqlgrey.* to 'sqlgrey'@'localhost' identified by '$password'"

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
    sed -i '/^Incoming Queue Dir =/ c\Incoming Queue Dir = \/var\/spool\/postfix\/hold' /etc/MailScanner/MailScanner.conf
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
    # install clamav and clamd.
    yum -y install clamav clamd

    # todo:
    # http://sanesecurity.co.uk/usage/linux-scripts/
    
    # don't know if we need it so GPG key import is disabled (I remember GPG key was needed in ESVA for something
    # just don't know for what anymore)
    #cd /tmp
    #wget -q http://spamassassin.apache.org/released/GPG-SIGNING-KEY
    #su postfix -c 'gpg --import /tmp/GPG-SIGNING-KEY'

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
        
    # fix socket file in mailscanner.conf
    sed -i '/^Clamd Socket/ c\Clamd Socket = \/var\/run\/clamav\/clamd.sock' /etc/MailScanner/MailScanner.conf
    
    # not todo: botnet.tar
    # ESVA uses botnet.tar, this old package is in my opinion not needed as spamhaus relay blocklist already 
    # adds botnet's by default.. also the botnet.tar is not maintained anymore...
    
    # PDFInfo (todo: add option to efa-configure to disable this, if users find its to cpu intensive)
    cd /tmp
    /usr/bin/wget -q -O /usr/local/share/perl5/Mail/SpamAssassin/Plugin/PDFInfo.pm $gitdlurl/PDFInfo/PDFInfo.pm
    /usr/bin/wget -q -O /etc/mail/spamassassin/pdfinfo.cf $gitdlurl/PDFInfo/pdfinfo.cf
    echo "loadplugin Mail::SpamAssassin::Plugin::PDFInfo">>/etc/mail/spamassassin/v310.pre

    # todo: ImageInfo
    # well not really a todo, ImageInfo is already packaged and enabled by default in spamassassin.
    # nothing to do here, just adding the remark so we don't spend any extra time on it :-).
    
    # not todo: sare
    # sare channels are dead: http://wiki.apache.org/spamassassin/SareChannels
    # openprotect seems to have an alternative ^^ see link, need to check if that works.
    #
    # Nope, no good.
    # http://saupdates.openprotect.com
    # "OpenProtect SpamAssassin sa-update channel is obsolete since SARE
    # "stopped updating their rulesets. Please stop using this channel."

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
    
    # Enable Auto White Listing
    sed -i '/^#loadplugin Mail::SpamAssassin::Plugin::AWL/ c\loadplugin Mail::SpamAssassin::Plugin::AWL' /etc/mail/spamassassin/v310.pre
    
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
    
    # and in the end we run sa-update just for the fun of it..
    sa-update
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
    sed -i '/IndexOptions FancyIndexing VersionSort NameWidth=* HTMLTable Charset=UTF-8/d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIconByEncoding /d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIconByType /d' /etc/httpd/conf/httpd.conf
    sed -i '/AddIcon /d' /etc/httpd/conf/httpd.conf
    sed -i '/DefaultIcon /d' /etc/httpd/conf/httpd.conf
    sed -i '/ReadmeName /d' /etc/httpd/conf/httpd.conf
    sed -i '/HeaderName /d' /etc/httpd/conf/httpd.conf
    sed -i '/IndexIgnore /d' /etc/httpd/conf/httpd.conf

    # Secure PHP (this might break some stuff so need to test carefully)
    sed -i '/disable_functions =/ c\disable_functions = apache_child_terminate,apache_setenv,define_syslog_variables,escapeshellarg,escapeshellcmd,eval,exec,fp,fput,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw,ftp_rawlist,highlight_file,ini_alter,ini_get_all,ini_restore,inject_code,openlog,passthru,php_uname,phpAds_remoteInfo,phpAds_XmlRpc,phpAds_xmlrpcDecode,phpAds_xmlrpcEncode,popen,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_setuid,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,syslog,system,xmlrpc_entity_decode,curl_exec,curl_multi_exec' /etc/php.ini
    
    # Todo: Mod_security
    #       This requires EPEL sources (which have given me lots of dependency issues before
    #       Not sure if that is something we would like to have :-) )
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure SQLgrey
# +---------------------------------------------------+
func_sqlgrey () {
    useradd sqlgrey -m -d /home/sqlgrey -s /sbin/nologin
    wget http://downloads.sourceforge.net/project/sqlgrey/sqlgrey-1.8%20%28stable%29/sqlgrey-1.8.0.tar.gz
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
    
    # start and stop sqlgrey (first launch will create all database tables)
    # We give it 15 seconds to populate the database and then stop it again.
    service sqlgrey start
    sleep 15
    service sqlgrey stop
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure MailWatch
# +---------------------------------------------------+
func_mailwatch () {
    # Fetch MailWatch
    cd /tmp
    wget http://sourceforge.net/projects/mailwatch/files/mailwatch/$mailwatchver/mailwatch-$mailwatchver.tar.gz
    tar -xzvf mailwatch-$mailwatchver.tar.gz
    cd mailwatch-$mailwatchver

    # Set php parameters needed
    sed -i '/^magic_quotes_gpc =/ c\magic_quotes_gpc = On' /etc/php.ini
    sed -i '/^short_open_tag =/ c\short_open_tag = On' /etc/php.ini

    # Set up connection for MailWatch    
    cd MailScanner_perl_scripts
    sed -i "/^my(\$db_user) =/ c\my(\$db_user) = 'mailwatch';" MailWatch.pm
    sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" MailWatch.pm
    mv MailWatch.pm /usr/lib/MailScanner/MailScanner/CustomFunctions/
    
    # Set up SQLBlackWhiteList
    sed -i "/^  my(\$db_user) =/ c\  my(\$db_user) = 'mailwatch';" SQLBlackWhiteList.pm
    sed -i "/^  my(\$db_pass) =/ c\  my(\$db_pass) = '$password';" SQLBlackWhiteList.pm
    mv SQLBlackWhiteList.pm /usr/lib/MailScanner/MailScanner/CustomFunctions

    # Set up SQLSpamSettings
    sed -i "/^my(\$db_user) =/ c\my(\$db_user) = 'mailwatch';" SQLSpamSettings.pm
    sed -i "/^my(\$db_pass) =/ c\my(\$db_pass) = '$password';" SQLSpamSettings.pm
    mv SQLSpamSettings.pm /usr/lib/MailScanner/MailScanner/CustomFunctions

    # Set up MailWatch tools
    cd ..
    mkdir /usr/local/bin/mailwatch
    mv tools /usr/local/bin/mailwatch
    rm -f /usr/local/bin/mailwatch/tools/Cron_jobs/INSTALL
    chmod 755 /usr/local/bin/mailwatch/tools/Cron_jobs/*
    touch /etc/cron.daily/mailwatch
    echo "#!/bin/bash" > /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/db_clean.php" >> /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_maint.php --clean" >> /etc/cron.daily/mailwatch
    echo "/usr/local/bin/mailwatch/tools/Cron_jobs/quarantine_report.php" >> /etc/cron.daily/mailwatch
    chmod 755 /etc/cron.daily/mailwatch

    # Move MailWatch into web root and configure
    # ESVA MailWatch is directly in /var/www/html
    # Going to move into its own directory and maybe set up a redirect
    # to keep the web root clean and match up with conf.php defaults
    
    mv mailscanner /var/www/html
    cd /var/www/html/mailscanner
    chown root:apache images
    chmod ug+rwx images
    chown root:apache images/cache
    chmod ug+rwx images/cache

    cp conf.php.example conf.php
    sed -i "/^define('DB_USER',/ c\define('DB_USER', 'mailwatch');" conf.php
    sed -i "/^define('DB_PASS',/ c\define('DB_PASS', '$password');" conf.php
    sed -i "/^define('TIME_ZONE',/ c\define('TIME_ZONE', 'Etc/UTC');" conf.php
    sed -i "/^define('QUARANTINE_USE_FLAG',/ c\define('QUARANTINE_USE_FLAG', true);" conf.php
    # Note...Set QUARANTINE_FROM_ADDR in EFA_Init for conf.php
    sed -i "/^define('QUARANTINE_REPORT_FROM_NAME',/ c\define('QUARANTINE_REPORT_FROM_NAME', 'EFA - Email Filter Appliance');" conf.php
    sed -i "/^define('QUARANTINE_USE_SENDMAIL',/ c\define('QUARANTINE_USE_SENDMAIL', true);" conf.php
    sed -i "/^define('AUDIT',/ c\define('AUDIT', true);" conf.php

    # Set up a redirect in web root to MailWatch for now
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
    cd /var/www/html
    wget http://www.efa-project.org/favicon.ico

    # EFA Branding
    cd /var/www/html/mailscanner/images
    wget $gitdlurl/EFA/EFAlogo-47px.gif
    #wget $gitdlurl/EFA/EFAlogo-79px.gif
    wget $gitdlurl/EFA/EFAlogo-79px.png
    mv mailwatch-logo.gif mailwatch-logo.gif.orig
    mv mailwatch-logo.png mailwatch-logo.png.orig
    mv mailscannerlogo.gif mailscannerlogo.gif.orig
    # png image looks much better -- linking to png instead
    ln -s EFAlogo-79px.png mailwatch-logo.gif
    ln -s EFAlogo-79px.png mailwatch-logo.png
    ln -s EFAlogo-47px.gif mailscannerlogo.gif   
 
    # mailscanner bayes configuration should be ok
    # nothing to do

    # Add Mailgraph link
    cd /var/www/html/mailscanner
    cp other.php other.php.orig
    sed -i '/^ MailWatch for MailScanner/a\ Modified for Use With EFA -- Email Filter Appliance -- 1/1/2014'
    sed -i "/^    echo '<li><a href=\"geoip_update.php\">/a\    /*Begin EFA Mailgraph Link*/\n    echo '<li><a href=\"../cgi-bin/mailgraph.cgi\">View Mailgraph Statistics</a>';\n    /*End EFA Mailgraph Link*/" other.php
 
    # Postfix Relay Info
    rm -f /usr/local/bin/mailwatch/tools/Postfix_relay/INSTALL
    chmod +x /usr/local/bin/mailwatch/tools/Postfix_relay/mailwatch_relay.sh
    touch /etc/cron.hourly/mailwatch_update_relay
    echo "#!/bin/sh" > /etc/cron.hourly/mailwatch_update_relay
    echo "/usr/local/bin/mailwatch/tools/Postfix_relay/mailwatch_relay.sh" >> /etc/cron.hourly/mailwatch_update_relay
    chmod +x /etc/cron.hourly/mailwatch_update_relay
 
    # Todo: greylisting tools for MailWatch
    #       Andy wrote the greylist interface for Mailwatch in a series of 
    #       php files
    #       Should we reuse and adapt?  It is marked GNU GPLv2. 
    #
    #   I would say we reuse them, the code seems pretty simple so bugs we can probably
    #   Fix ourself (even tough I got limited php knowledge :P)

    # Todo: spam submission and release cgi scripts
    #       I am guessing Andy also wrote these
    #       No license or owner is mentioned
    #       learn-msg.cgi is vulnerable to command injection...
    #       http://www.exploit-db.com/exploits/20712
    #       if we reuse or recreate, we need to harden it
    #       you can pass anything to the learn-msg.cgi and 
    #       no validation checks are performed
    #
    #   See this topic: http://www.esvacommunity.com/forum/viewtopic.php?f=5&t=232
    #   I already wrote an simple fix for the security issue and user "endreottem"
    #   added some extra checks.
    
    # Todo:  esva also has an mailwatch local system user.
    #        don't see why that user exists or what it's used for
    #        we should also check that out.
    
    # MailWatch requires access to /var/spool/postfix/hold & incoming dir's
    chown -R postfix:apache /var/spool/postfix/hold
    chown -R postfix:apache /var/spool/postfix/incoming
    chmod -R 750 /var/spool/postfix/hold
    chmod -R 750 /var/spool/postfix/incoming
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Mailgraph
# +---------------------------------------------------+
func_mailgraph () {
    cd /tmp 
    wget -q http://mailgraph.schweikert.ch/pub/mailgraph-1.14.tar.gz
    tar xvzf mailgraph-1.14.tar.gz
    cd mailgraph-1.14
    
    mv mailgraph.cgi /var/www/cgi-bin/
    mv mailgraph.pl /usr/local/bin/
    mv mailgraph-init /etc/init.d/
    chmod 0755 /etc/init.d/mailgraph-init
    chmod 0755 /var/www/cgi-bin/mailgraph.cgi
    
    sed -i '/^MAIL_LOG=/ c\MAIL_LOG=\/var\/log\/maillog' /etc/init.d/mailgraph-init
    sed -i "/^my \$rrd =/ c\my \$rrd = \'\/var\/lib\/mailgraph.rrd\'\;" /var/www/cgi-bin/mailgraph.cgi
    sed -i "/^my \$rrd_virus =/ c\my \$rrd_virus = \'\/var\/lib\/mailgraph_virus.rrd\'\;" /var/www/cgi-bin/mailgraph.cgi

    # todo:
    # figure out how this was incorporated in mailwatch..
    # it appears that it wasn't.  ESVA used to have an index.html
    # that linked to it, but it is renamed index.html.old
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install Pyzor
# +---------------------------------------------------+
func_pyzor () {
    cd /tmp
    wget http://downloads.sourceforge.net/project/pyzor/pyzor/0.5.0/pyzor-0.5.0.tar.gz
    tar xvzf pyzor-0.5.0.tar.gz
    cd pyzor-0.5.0
    python setup.py build
    python setup.py install

    # Fix deprecation warning message
    sed -i '/^#!\/usr\/bin\/python/ c\#!\/usr\/bin\/python -Wignore::DeprecationWarning' /usr/bin/pyzor

    mkdir /var/spool/postfix/.pyzor
    chown postfix:postfix /var/spool/postfix/.pyzor
    # Note: ESVA also has an .pyzor directory in /var/www don't know why..
  
    # and finally initialize the servers file with an discover.
    su postfix -s /bin/bash -c 'pyzor discover'
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install Razor (http://razor.sourceforge.net/)
# +---------------------------------------------------+
func_razor () {
    cd /tmp
    wget http://downloads.sourceforge.net/project/razor/razor-agents/2.84/razor-agents-2.84.tar.bz2
    tar xvjf razor-agents-2.84.tar.bz2
    cd razor-agents-2.84
    
    perl Makefile.PL
    make
    make test
    make install
    
    mkdir /var/spool/postfix/.razor
    chown postfix:postfix /var/spool/postfix/.razor

    # todo: this should probably go to EFA-Init.
    su postfix -s /bin/bash -c 'razor-admin -create'
    su postfix -s /bin/bash -c 'razor-admin -register'
    sed -i '/^debuglevel/ c\debuglevel             = 0' /var/spool/postfix/.razor/razor-agent.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install DCC http://www.rhyolite.com/dcc/ 
# (current version = version 1.3.154, December 03, 2013)
# +---------------------------------------------------+
func_dcc () {
    cd /tmp
    wget http://www.rhyolite.com/dcc/source/dcc.tar.Z
    tar xvzf dcc.tar.Z
    cd dcc-*
    
    ./configure --disable-dccm
    make install
    
    ln -s /var/dcc/libexec/cron-dccd /usr/bin/cron-dccd
    ln -s /var/dcc/libexec/cron-dccd /etc/cron.monthly/cron-dccd
    echo "dcc_home /var/dcc" >> /etc/MailScanner/spam.assassin.prefs.conf
    sed -i '/^dcc_path / c\dcc_path /usr/local/bin/dccproc' /etc/MailScanner/spam.assassin.prefs.conf
    sed -i '/^DCCIFD_ENABLE=/ c\DCCIFD_ENABLE=on' /var/dcc/dcc_conf
    sed -i '/^DBCLEAN_LOGDAYS=/ c\DBCLEAN_LOGDAYS=1' /var/dcc/dcc_conf
    sed -i '/^DCCIFD_LOGDIR=/ c\DCCIFD_LOGDIR="/var/dcc/log"' /var/dcc/dcc_conf
    chown postfix:postfix /var/dcc
    
    cp /var/dcc/libexec/rcDCC /etc/init.d/adcc
    sed -i "s/#loadplugin Mail::SpamAssassin::Plugin::DCC/loadplugin Mail::SpamAssassin::Plugin::DCC/g" /etc/mail/spamassassin/v310.pre
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Webmin
# +---------------------------------------------------+
func_webmin () {
    cd /tmp
    wget http://downloads.sourceforge.net/project/webadmin/webmin/1.660/webmin-1.660-1.noarch.rpm
    rpm -i webmin-1.660-1.noarch.rpm
    
    # shoot a hole in webmin so we can change settings
    echo "localauth=/usr/sbin/lsof" >> /etc/webmin/miniserv.conf
    echo "referer=1" >> /etc/webmin/config
    echo "referers=" >> /etc/webmin.config
    sed -i '/^referers_none=1/ c\referers_none=0' /etc/webmin/config
    service webmin restart

    # Remove modules we don't need.
    curl -k "https://localhost:10000/webmin/delete_mod.cgi?mod=adsl-client&mod=bacula-backup&mod=burner&mod=pserver&mod=cluster-copy&mod=exim&mod=shorewall6&mod=sendmail&confirm=Delete&acls=1&nodeps="
    curl -k "https://localhost:10000/webmin/delete_mod.cgi?mod=cluster-webmin&mod=bandwidth&mod=cluster-passwd&mod=cluster-cron&mod=cluster-shell&mod=cluster-usermin&mod=cluster-useradmin&confirm=Delete&acls=1&nodeps="
    curl -k "https://localhost:10000/webmin/delete_mod.cgi?mod=cfengine&mod=dhcpd&mod=dovecot&mod=fetchmail&mod=filter&mod=frox&mod=tunnel&mod=heartbeat&mod=ipsec&mod=jabber&mod=krb5&confirm=Delete&acls=1&nodeps="
    curl -k "https://localhost:10000/webmin/delete_mod.cgi?mod=ldap-client&mod=ldap-server&mod=ldap-useradmin&mod=firewall&mod=mon&mod=majordomo&mod=exports&mod=openslp&mod=pap&mod=ppp-client&mod=pptp-client&mod=pptp-server&mod=postgresql&confirm=Delete&acls=1&nodeps="
    curl -k "https://localhost:10000/webmin/delete_mod.cgi?mod=lpadmin&mod=proftpd&mod=procmail&mod=qmailadmin&mod=smart-status&mod=samba&mod=shorewall&mod=sarg&mod=squid&mod=usermin&mod=vgetty&mod=wuftpd&mod=webalizer&confirm=Delete&acls=1&nodeps="

    # fix the holes again
    sed -i '/^referers_none=0/ c\referers_none=1' /etc/webmin/config
    sed -i '/referer=1/d' /etc/webmin/config
    sed -i '/referers=/d' /etc/webmin/config
    sed -i '/localauth=\/usr\/sbin\/lsof/d' /etc/webmin/miniserv.conf
    service webmin restart
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
    chkconfig abrtd off
    chkconfig portreserve off
    # Postfix is launched by MailScanner
    chkconfig postfix off 
    # auditd is something for an future release..
    chkconfig auditd off 
    
    # These services we disable for now and enable them after EFA-Init.
    # Most of these are not enabled by default but add them here just to
    # make sure we don't forget them at EFA-Init.
    chkconfig MailScanner off
    chkconfig httpd off
    chkconfig mysqld off
    chkconfig named off
    chkconfig saslauthd off
    chkconfig crond off
    chkconfig clamd off
    chkconfig sqlgrey off
    chkconfig mailgraph-init off
    chkconfig adcc off
    chkconfig webmin off
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
    # rm -f /var/log/clamav/freshclam.log
    # cd /tmp
    # rm -rf *

    # Stop running services to allow kickstart to reboot
    service mysqld stop
    service webmin stop
    
    # clean yum cache
    yum clean all
    
    # Fix SE-Linux security issues
    restorecon -r /var/www
    chcon -v --type=httpd_sys_content_t /var/lib/mailgraph*
    # todo: figure out which se-linux items needs to be changed to allow clamd access to /var/spool/MailScanner/incoming/*..
    #       Currently se-linux blocks clamd. 
    #       (denied  { read } for  pid=4083 comm="clamd" name="3899" dev=tmpfs ino=23882 scontext=unconfined_u:system_r:antivirus_t:s0 tcontext=unconfined_u:object_r:var_spool_t:s0 tclass=dir

    # Remove boot splash so we can see whats going on while booting
    sed -i 's/\<rhgb quiet\>//g' /boot/grub/grub.conf
    
    # zero disks for better compression (when creating VM images)
    # this can take a while so disabled for now until we start creating images.
    #dd if=/dev/zero of=/filler bs=1000
    #rm -f /filler
    #dd if=/dev/zero of=/tmp/filler bs=1000
    #rm -f /tmp/filler
    #dd if=/dev/zero of=/boot/filler bs=1000
    #rm -f /boot/filler
    #dd if=/dev/zero of=/var/filler bs=1000
    #rm -f /var/filler
}
# +---------------------------------------------------+

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
func_mailgraph
func_pyzor
func_razor
func_dcc
func_webmin
func_kernmodules
func_services
func_efarequirements
func_cron
func_cleanup
# +---------------------------------------------------+
