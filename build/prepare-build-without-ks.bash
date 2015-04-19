#!/bin/bash
# +--------------------------------------------------------------------+
# EFA 3.0.0.8 build without ks version 20150419
#
# Purpose:
#		This script will 'baseline' an existing CentOS installation
#		to start the build.bash script ONLY use this script if you
#		are unable to use the kickstart methode.
#
# Prerequirements:
#		A minimal installation of CentOS.
#		Working internet connection
#
# +--------------------------------------------------------------------+
# Copyright (C) 2013~2015 http://www.efa-project.org
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

clear

#----------------------------------------------------------------#
# Check if we are root
#----------------------------------------------------------------#
if [ `whoami` == root ]
  then
    echo "[EFA] Good you are root"
else
  echo "[EFA] Please become root to run this."
  exit 1
fi
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Check if we use centos 6.6
#----------------------------------------------------------------#
CENTOS=`cat /etc/centos-release`

if [[ "$CENTOS" == "CentOS release 6.6 (Final)" ]]
  then
    echo "Good you are running CentOS 6.6 x64"
else
  echo "You are not running CentOS 6.6"
  echo "Unsupported system, stopping now"
  echo "If you are running CentOS 6.5 please do a manual upgrade to 6.6 before starting this build"
  exit 1
fi
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Show a disclaimer on using this methode....
#----------------------------------------------------------------#
echo " !!! WARNING !!!"
echo ""
echo "Using this methode is not supported! Please use kickstart where possible."
echo "Only use this methode if there is no option to install using kickstart"
echo "or when it is not possible to use an VM image."
echo ""
echo "This setup will possible put your system in an unsupported state."
echo ""
echo "Again use kickstart or a VM image where possible"
echo ""
echo -n "Are you sure you want to continue? (y/N):"
read YN
flag=1
while [ $flag != "0" ]
    do
      if [[ "$YN" == "Y" || "$YN" == "y" ]]; then
        flag=0
      elif [[ "$YN" == "" || "$YN" == "N" || "$YN" == "n" ]]; then
		echo "Aborting this setup"
        exit 1
      else
          echo -n "Are you sure you want to continue? (y/N):"
          read YN
      fi
  done
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Upgrade system
#----------------------------------------------------------------#
yum -y update
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Configure firewall
#----------------------------------------------------------------#
cat > /etc/sysconfig/iptables << 'EOF'
# Firewall configuration written by system-config-firewall
# Manual customization of this file is not recommended.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 25 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 10000 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF

/sbin/service iptables restart
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Set root password to EfaPr0j3ct
#----------------------------------------------------------------#
echo "root:EfaPr0j3ct" | chpasswd --md5 root
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# add packages
#----------------------------------------------------------------#
yum -y install \
@base \
@core \
gpg \
mysql-server \
mysql \
screen \
php \
php-gd \
php-mysql \
httpd \
dnsmasq \
rrdtool \
rrdtool-perl \
postfix \
cyrus-sasl-md5 \
ImageMagick \
ntp \
patch \
tree \
rpm-build \
binutils \
glibc-devel \
gcc \
make \
opencv \
perl-Archive-Tar \
perl-Archive-Zip \
perl-Compress-Zlib \
perl-Convert-BinHex \
perl-Digest-SHA1 \
perl-DBD-MySQL \
perl-DBD-SQLite \
perl-CGI \
perl-HTML-Parser \
perl-IO-stringy \
perl-IO-Socket-INET6 \
perl-IO-Socket-SSL \
perl-IO-Zlib \
perl-MailTools \
perl-MIME-tools \
perl-Pod-Escapes \
perl-Pod-Simple \
perl-Test-Pod \
perl-TimeDate \
perl-Time-HiRes \
perl-Net-DNS \
perl-Net-IP \
perl-Net-SSLeay \
perl-Encode-Detect \
perl-Module-Build \
mod_ssl \
system-config-keyboard \
openssl-devel

#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Remove packages
#----------------------------------------------------------------#
yum -y remove \
aic94xx-firmware \
ql2400-firmware \
libertas-usb8388-firmware \
zd1211-firmware \
ql2200-firmware \
ipw2200-firmware \
iwl5150-firmware \
iwl6050-firmware \
iwl6000g2a-firmware \
iwl6000-firmware \
ivtv-firmware \
xorg-x11-drv-ati-firmware \
atmel-firmware \
iwl4965-firmware \
iwl3945-firmware \
rt73usb-firmware \
ql23xx-firmware \
bfa-firmware \
iwl1000-firmware \
iwl5000-firmware \
iwl100-firmware \
ql2100-firmware \
ql2500-firmware \
rt61pci-firmware \
ipw2100-firmware \
alsa-utils \
alsa-lib
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# E.F.A. items
#----------------------------------------------------------------#
mkdir /var/log/EFA
mkdir /usr/src/EFA
/usr/bin/wget -q -O /usr/src/EFA/build.bash -o /var/log/EFA/wget.log https://raw.githubusercontent.com/E-F-A/v3/3.0.0.6/build/build.bash --no-check-certificate
chmod 700 /usr/src/EFA/build.bash
#----------------------------------------------------------------#

#----------------------------------------------------------------#
# Show final messages
#----------------------------------------------------------------#
echo ""
echo "All done, you are now ready to start the build script"
echo "We can now launch the build script."
echo "If you do not want to launch the build script now then"
echo "you will need to start this your self with the command:"
echo ""
echo "logsave /var/log/EFA/build.log /usr/src/EFA/build.bash"
echo ""
echo -n "Do you want to start the build script? (y/N):"
read YN
flag=1
while [ $flag != "0" ]
    do
      if [[ "$YN" == "Y" || "$YN" == "y" ]]; then
	    logsave /var/log/EFA/build.log /usr/src/EFA/build.bash
        flag=0
      elif [[ "$YN" == "" || "$YN" == "N" || "$YN" == "n" ]]; then
		echo ""
		echo "Please don't forget to run the build script"
        exit 1
      else
          echo -n "Do you want to start the build script? (y/N):"
          read YN
      fi
  done
#----------------------------------------------------------------#
#EOF
