#!/bin/bash
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWARM="{{SWARM}}"
cd /
export DEBIAN_FRONTEND=noninteractive
# get latest versions of packages
apt-get -qq update 2>&1
apt-get -qq -y dist-upgrade 2>&1
# install security updates
#unattended-upgrades &>/dev/null 

# install docker-ce

#apt-get -qq -y remove docker docker-engine | cat
wget -q -O /pdmenu.deb http://ftp.nl.debian.org/debian/pool/main/p/pdmenu/pdmenu_1.3.4+b1_amd64.deb
apt-get -qq -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    /pdmenu.deb \
    software-properties-common \
	htop \
    sudo 2>&1
echo "admin ALL = (ALL:ALL) ALL" >>/etc/sudoers
#dpkg -i /pdmenu.deb 2>&1
#pdmenu \

#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &>/dev/null
#add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#   $(lsb_release -cs) \
#   stable" &>/dev/null
#apt-get -qq update &>/dev/null
#apt-get -qq -y install docker-ce &>/dev/null
curl -sSL https://get.docker.com | sh 2>&1

# install docker-compose
curl -s -S -L https://github.com/docker/compose/releases/download/1.17.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#dpkg --configure -a
# clone repo and pull images
if [ -d "/dockerrepo" ]; then
    rm -rf /dockerrepo
fi
git clone -q -b stable ssh://tfs.loginvsi.com/tfs/NextGen/Shared/_git/Hosting /dockerrepo
cd /dockerrepo/
echo 8@0OIS58MajY | docker login -u vsiplayaccount --password-stdin
docker pull portainer/portainer 2>&1
docker pull httpd:2.4-alpine 2>&1

cd /dockerrepo/latest/Production/StandaloneInternalDB
docker-compose pull  2>&1

docker logout 2>&1

if [ -d /loginvsi ]; then
    rm -rf /loginvsi
fi
mkdir /loginvsi
mkdir /loginvsi/img
wget -q -O /loginvsi/img/logo_alt.png https://www.loginvsi.com/images/logos/login-vsi-company-logo.png
cp /loginvsi/img/logo_alt.png /loginvsi/img/logo.png
if [ $SWARM == "true" ]; then
    cp -r "/dockerrepo/latest/Production/InternalDB/docker-compose.yml" /loginvsi/
else
    cp -r "/dockerrepo/latest/Production/StandaloneInternalDB/docker-compose.yml" /loginvsi/
fi

rm -rf /dockerrepo
cp -r -f $SCRIPT_PATH/menu /loginvsi/menu

cp -f $SCRIPT_PATH/pdmenurc /etc/pdmenurc
cp -f $SCRIPT_PATH/loginvsid /usr/bin/
cp -f $SCRIPT_PATH/loginvsid.service /etc/systemd/system/
cp -f $SCRIPT_PATH/firstrun /loginvsi/
cp -f $SCRIPT_PATH/sshd_config /etc/ssh/



echo "loginvsi-ng" > /etc/hostname
hostname "loginvsi-ng"


echo "#!/bin/bash" > /home/admin/.bash_profile
echo "if [ ! -f '/loginvsi/first_run.chk' ]; then"  >> /home/admin/.bash_profile
echo "  echo 'admin' | sudo -S -p '' echo 'Starting LoginVSI configuration tool...'" >> /home/admin/.bash_profile
echo "  sudo /loginvsi/firstrun" >> /home/admin/.bash_profile
echo "fi" >> /home/admin/.bash_profile
chmod +x /home/admin/.bash_profile
chmod +x /loginvsi/firstrun
chmod +x /loginvsi/menu/*

echo "admin:admin" | chpasswd
cp $SCRIPT_PATH/issue /etc/
cp $SCRIPT_PATH/hosts /etc/
echo "This system is not yet configured, please logon with username: admin and password: admin" >> /etc/issue

echo '#!/bin/sh
[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

printf "Welcome to {{TITLE}}\n"
printf "%s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"

' > /etc/update-motd.d/00-header

echo "[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=none" > /etc/systemd/network/99-default.link

rm /etc/motd

if [ -f '/etc/update-motd.d/10-help-text' ]; then
	rm /etc/update-motd.d/10-help-text
fi
if [ -f '/etc/update-motd.d/90-updates-available' ]; then
	rm /etc/update-motd.d/90-updates-available
fi


if [ -f "/loginvsi/first_run.chk" ]; then
    rm /loginvsi/first_run.chk
fi

echo "
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
" >>/etc/sysctl.conf

update-rc.d ssh disable


# Cleanup
rm -rf /home/admin/*
rm -rf /home/admin/.bash_history
rm -rf /root/.bash_history
rm -rf /root/.ssh
