#!/bin/bash
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd /
export DEBIAN_FRONTEND=noninteractive
# get latest versions of packages
apt-get -qq update &>/dev/null
apt-get -qq -y upgrade &>/dev/null
# install security updates
unattended-upgrades &>/dev/null 

# install docker-ce

apt-get -qq -y remove docker docker-engine | cat
apt-get -qq -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    pdmenu &>/dev/null

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &>/dev/null
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" &>/dev/null
apt-get -qq update &>/dev/null
apt-get -qq -y install docker-ce &>/dev/null

# install docker-compose
curl -s -S -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#dpkg --configure -a
# clone repo and pull images
if [ -d "/dockerrepo" ]; then
    rm -rf /dockerrepo
fi
git clone -q -b master ssh://tfs.loginvsi.com/tfs/NextGen/Shared/_git/P_Hosting /dockerrepo
cd /dockerrepo/
echo 8@0OIS58MajY | docker login -u vsiplayaccount --password-stdin
docker pull portainer/portainer | cat 
docker pull httpd:2.4-alpine | cat

cd /dockerrepo/latest/Development/InternalDB
docker-compose pull --quiet &>/dev/null

docker logout &>/dev/null

if [ -d /loginvsi ]; then
    rm -rf /loginvsi
fi
mkdir /loginvsi
mkdir /loginvsi/img
wget -q -O /loginvsi/img/logo_alt.png https://www.loginvsi.com/images/logos/login-vsi-company-logo.png
cp /loginvsi/img/logo_alt.png /loginvsi/img/logo.png
cp -r "/dockerrepo/latest/Production/InternalDB/docker-compose.yml" /loginvsi/
cp -r "/dockerrepo/latest/Production/InternalDB/.env" /loginvsi/
rm -rf /dockerrepo
cp -r -f $SCRIPT_PATH/menu /loginvsi/menu
cp -f $SCRIPT_PATH/pdmenurc /etc/
cp -f $SCRIPT_PATH/loginvsid /usr/bin/
cp -f $SCRIPT_PATH/loginvsid.service /etc/systemd/system/
cp -f $SCRIPT_PATH/firstrun /loginvsi/
#cp -f $SCRIPT_PATH/.env /loginvsi/
cp -f $SCRIPT_PATH/sshd_config /etc/ssh/
cp -f $SCRIPT_PATH/grub /etc/default/

echo "loginvsi-ng" > /etc/hostname
hostname "loginvsi-ng"
#update-grub &>/dev/null

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

printf "Welcome to LoginVSI NG!(tm)\n"
printf "%s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"

' > /etc/update-motd.d/00-header

echo "[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=none" > /etc/systemd/network/99-default.link

if [ -f '/etc/update-motd.d/10-help-text' ]; then
	rm /etc/update-motd.d/10-help-text
fi
if [ -f '/etc/update-motd.d/90-updates-available' ]; then
	rm /etc/update-motd.d/90-updates-available
fi


if [ -f "/loginvsi/first_run.chk" ]; then
    rm /loginvsi/first_run.chk
fi
rm -rf /home/admin/*


#docker rm -f $(docker ps -a -q)
#docker network prune -f