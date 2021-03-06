#
# Copyright &copy; 2014 Nethesis S.r.l.
# http://www.nethesis.it - support@nethesis.it
# 
# This script is part of NethServer.
# 
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
# 
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
# This script will install NethServer.
# Default installation will include only base system.
# If you need to install more modules, you can specifies them on the command line.
#
# Default installtion:
# 
#     nethserver-install
#
# Install mail server
#
#     nethserver-install mail-server
#
#

function log {
    echo `date` "$1" >> /var/log/nethserver-install.log
}

function logexec {
    cmd=$1
    log "$cmd"
    $cmd | tee -a /var/log/nethserver-install.log
}

function end {
    echo
    echo "You can access the Web interface at:"
    hostname=`/sbin/e-smith/db configuration get SystemName`
    domainname=`/sbin/e-smith/db configuration get DomainName`
    echo
    echo -n "    https://$hostname.$domainname:980"
    for k in `/sbin/e-smith/db networks keys`
    do
       role=`/sbin/e-smith/db networks getprop $k role`
       if [ "$role" == "green" ]; then
           ip=$(/sbin/e-smith/db networks getprop eth0 ipaddr)
           echo " (or https://$ip:980)"
       fi
    done
    echo 
    echo "    Login: root" 
    echo "    Password: <your_root_password>"
    echo
    echo
    echo "Installation log can be found here: /var/log/nethserver-install.log"
    echo
    echo
    log "End"
    exit 0
}

rpm -q nethserver-base >/dev/null
if [ $? -eq 0 ]; then
   echo
   echo "NethServer is already installed!"
   log "Already installed"
   end
fi

modules=""
if [ $# -gt 0 ]; then
   echo "The following extra modules will also be installed: $@"
   log "Extra modules: $@"
   for m in $@
   do
       modules="$modules @$m"
   done
fi


log "Starting installation"
echo "Starting installation process. It will take a while..."
echo
echo "Installing base system..."
echo
logexec "rpm --import /etc/pki/rpm-gpg/*"
logexec "yum --disablerepo=* --enablerepo=nethserver-base,nethserver-updates,centos-base,centos-updates --releasever=6.4 install @nethserver-iso -y"
logexec "/sbin/e-smith/signal-event system-init"
if [ "$modules" != "" ]; then
    echo 
    echo "Installing extra modules..."
    echo
    logexec "yum install $modules -y"
fi
end
