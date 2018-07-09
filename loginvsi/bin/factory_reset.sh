#!/bin/bash

echo "WARNING: YOU ARE ABOUT TO REMOVE ALL CONFIGURATION"
echo "AND DATA FROM THIS MACHINE."
echo "ARE YOU SURE?"

echo Read variables from when the virtual appliance was built.
source /loginvsi/build.conf

echo "Stopping all microservices. This may take a while"
for svc in $(docker service ls -q); do
	docker service scale $svc=0
done

echo Leaving docker swarm
docker swarm leave --force
systemctl disable loginvsid &>/dev/null
systemctl disable docker-cleanup &>/dev/null

echo "Removing network configuration"
if [ -f "/etc/network/interfaces" ]; then
    rm /etc/network/interfaces
fi

echo Reset hostname and domain name
hostname $INITIALHOSTNAME

echo "127.0.0.1	localhost $INITIALHOSTNAME $INITIALHOSTNAME.local
    127.0.1.1	$INITIALHOSTNAME.local
    # The following lines are desirable for IPv6 capable hosts
    ::1     localhost ip6-localhost ip6-loopback
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
" > /etc/hosts

echo Reset admin username and password
echo "admin:admin" | chpasswd

echo Reset message of the day
echo "Welcome to $TITLE - version $version
This system is not yet configured, please logon with username: admin and password: admin" > /etc/issue

echo '#!/bin/sh
[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi

printf "Welcome to %s\n" "$TITLE"
printf "%s (%s %s %s)\n" "$DISTRIB_DESCRIPTION" "$(uname -o)" "$(uname -r)" "$(uname -m)"

' > /etc/update-motd.d/00-header

echo Remove MOTD
if [ -f "/etc/motd" ]; then
    rm /etc/motd
fi

echo Create first run check file
if [ -f "/loginvsi/first_run.chk" ]; then
    rm /loginvsi/first_run.chk
fi

echo Remove second run check file
if [ -f "/loginvsi/second_run.chk" ]; then
    rm /loginvsi/second_run.chk
fi

# Remove data
rm /loginvsi/data/*

# Re-enable first run 
echo "#!/bin/bash" > /home/admin/.bash_profile
echo "if [ ! -f '/loginvsi/first_run.chk' ]; then"  >> /home/admin/.bash_profile
echo "  echo 'admin' | sudo -S -p '' echo 'Starting LoginVSI configuration tool...'" >> /home/admin/.bash_profile
echo "  sudo /loginvsi/firstrun" >> /home/admin/.bash_profile
echo "fi" >> /home/admin/.bash_profile
chmod +x /home/admin/.bash_profile

#Reset default shell for admin user
sed -i 's#admin:x:1000:1000:administrator,,,:/home/admin:/usr/bin/startmenu#admin:x:1000:1000:administrator,,,:/home/admin:/bin/bash#' /etc/passwd

# Cleanup
rm -rf /home/admin/*
rm -rf /home/admin/.bash_history
rm -rf /root/.bash_history
rm -rf /root/.ssh

reboot

echo "Press ENTER to continue"; read
