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

# +---------------------------------------------------+

# +---------------------------------------------------+
# Update system before we start
# +---------------------------------------------------+
func_upgradeOS () {
    yum -y upgrade
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
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Disable unneeded kernel modules
# +---------------------------------------------------+
    echo "# Begin Disable modules not required for E.F.A">>/etc/modprobe.conf
    echo "alias ipv6 off">>/etc/modprobe.conf
    echo "alias net-pf-10 off">>/etc/modprobe.conf
    echo "alias pcspkr off">>/etc/modprobe.conf
    echo "# End Disable modules not required for E.F.A.">>/etc/modprobe.conf
}
# +---------------------------------------------------+

# +---------------------------------------------------+
# Main logic (this is where we start calling out functions)
# +---------------------------------------------------+
func_upgradeOS
func_repoforge
func_clamav
func_kernmodules
# +---------------------------------------------------+