#!/bin/bash
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd /

# get latest versions of packages
apt-get update && apt-get upgrade -y
# install security updates
unattended-upgrades

# install docker-ce
apt-get remove docker docker-engine

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce

# install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# clone repo and pull images
if [ -d "/dockerrepo" ]; then
    rm -rf /dockerrepo
fi
git clone -b stable ssh://tfs.loginvsi.com/tfs/NextGen/Shared/_git/C_Hosting /dockerrepo
cd /dockerrepo/
docker login -u vsiplayaccount -p 8@0OIS58MajY
export GATEWAY_PORT=443
export COMPOSE_PROJECT_NAME=temp

docker-compose -f "./latest/Host/Internal DB/host-internaldb.yml" up -d

docker-compose -f "./latest/Host/Internal DB/host-internaldb.yml" down -v
docker logout

if [ -d /loginvsi ]; then
    rm -rf /loginvsi
fi
mkdir /loginvsi
cp -r "/dockerrepo/latest/Host/Internal DB/host-internaldb.yml" /loginvsi/
rm -rf /dockerrepo
cp -f $SCRIPT_PATH/loginvsid /usr/bin/
cp -f $SCRIPT_PATH/loginvsid.service /etc/systemd/system/
cp -f $SCRIPT_PATH/firstrun /loginvsi/
cp -f $SCRIPT_PATH/.env /loginvsi/
cp -f $SCRIPT_PATH/sshd_config /etc/ssh/
hostname "loginvsi-ng"

echo "#!/bin/bash" > /home/administrator/.bash_profile
echo "if [ ! -f '/loginvsi/first_run.chk' ]; then"  >> /home/administrator/.bash_profile
echo "  echo 'admin' | sudo -S -p '' echo 'Starting LoginVSI configuration tool...'" >> /home/administrator/.bash_profile
echo "  sudo /loginvsi/firstrun" >> /home/administrator/.bash_profile
echo "fi" >> /home/administrator/.bash_profile
chmod +x /home/administrator/.bash_profile
chmod +x /loginvsi/firstrun

echo "administrator:admin" | chpasswd
cp $SCRIPT_PATH/issue /etc/
cp $SCRIPT_PATH/hosts /etc/
echo "This system is not yet configured, please logon with username: administrator and password: admin" >> /etc/issue

echo '#!/bin/sh
[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

printf "Welcome to LoginVSI NG!(tm)\n"
printf "%s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"

' > /etc/update-motd.d/00-header

if [ -f '/etc/update-motd.d/10-help-text' ]; then
	rm /etc/update-motd.d/10-help-text
fi
if [ -f '/etc/update-motd.d/90-updates-available' ]; then
	rm /etc/update-motd.d/90-updates-available
fi


if [ -f "/loginvsi/first_run.chk" ]; then
    rm /loginvsi/first_run.chk
fi



#docker rm -f $(docker ps -a -q)
#docker network prune -f