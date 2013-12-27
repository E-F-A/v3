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
# +---------------------------------------------------+

# +---------------------------------------------------+
# Update system before we start
# +---------------------------------------------------+
func_upgradeOS () {
    yum -y upgrade
    rpm -e wireless-tools
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# add rpmforge/repoforge repositories
# +---------------------------------------------------+
func_repoforge () {
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm -ivh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Install and configure ClamAV from Repoforge
# +---------------------------------------------------+
func_clamav () {
    yum -y install clamav
    freshclam
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# configure apache
# +---------------------------------------------------+
func_apache () {
    echo "apache configuration"
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
    chkconfig ip6tables off
    chkconfig cpuspeed off
    chkconfig lvm2-monitor off
    chkconfig mdmonitor off
    chkconfig netfs off
    # disable postfix for now and enable after efa-init
    chkconfig postfix off 
    chkconfig smartd off
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
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Init -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-Init
    chmod 700 /usr/local/sbin/EFA-Init
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Configure -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-Configure
    chmod 700 /usr/local/sbin/EFA-Configure
    /usr/bin/wget -q -O /usr/local/sbin/EFA-Update -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-Update
    chmod 700 /usr/local/sbin/EFA-Update
    /usr/bin/wget -q -O /usr/local/sbin/EFA-SA-Update -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-SA-Update
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
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Cron settings
# +---------------------------------------------------+
func_cron () {
    /usr/bin/wget -q -O /etc/cron.daily/EFA-Daily-cron -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-Daily-cron
    chmod 700 /etc/cron.daily/EFA-Daily-cron
    /usr/bin/wget -q -O /etc/cron.monthly/EFA-Monthly-cron -o /var/log/efa/wget.log $gitdlurl/EFA/EFA-Monthly-cron
    chmod 700 /etc/cron.monthly/EFA-Monthly-cron
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Clean-up
# +---------------------------------------------------+
func_cleanup () {
    
    # DISABLED FOR NOW UNTIL TESTING IS OVER...
    # Clean SSH keys (generate at first boot)
    #/bin/rm /etc/ssh/ssh_host_*
    
    # Secure SSH
    #sed -i '/^#PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
}

# +---------------------------------------------------+
# Main logic (this is where we start calling out functions)
# +---------------------------------------------------+
func_upgradeOS
func_repoforge
func_clamav
func_apache
func_kernmodules
func_services
func_efarequirements
func_cron
func_cleanup
# +---------------------------------------------------+