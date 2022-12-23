#!/usr/bin/env bash

# set hostname
read -p "New hostname:" hostname
hostname ${hostname}
echo ${hostname} > /etc/hostname

# localtime
ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata


# /etc/resolve.conf (static, immune and ppointing to google)
mv /etc/resolv.conf resolv.conf.orig
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

# APT set main to official
echo -n > /etc/apt/sources.list
echo "deb http://ftp.pl.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list
echo "deb-src http://ftp.pl.debian.org/debian/ stretch main contrib non-free" >> /etc/apt/sources.list
echo "" >> /etc/apt/sources.list
echo "deb http://ftp.pl.debian.org/debian/ stretch-updates main contrib non-free" >> /etc/apt/sources.list
echo "deb-src http://ftp.pl.debian.org/debian/ stretch-updates main contrib non-free" >> /etc/apt/sources.list
echo "" >> /etc/apt/sources.list
echo "deb http://security.debian.org/ stretch/updates main" >> /etc/apt/sources.list
echo "deb-src http://security.debian.org/ stretch/updates main" >> /etc/apt/sources.list
# backports
echo "deb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list

# system update
apt -y update
apt install -y locales-all
export DEBIAN_FRONTEND=noninteractive; apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt -y autoremove


# install basic tools
apt -y install vim git mc psmisc net-tools htop pwgen apt-transport-https ca-certificates curl gnupg2 software-properties-common mailutils sg3-utils duplicity python-boto postfix

# remove not needed tools from OCI image
apt -y purge firewalld puppet-agent puppetlabs-release-pc1 sshguard fail2ban
apt -y autoremove
rm -rf /var/log/puppetlabs /opt/puppetlabs/puppet/cache /etc/puppetlabs /root/.ansible

# remove tech-support account
# userdel -f tech-support

# docker-ce
curl -Ls https://download.docker.com/linux/debian/gpg | apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" > /etc/apt/sources.list.d/docker.list
apt -y update
apt -y install docker-ce

# docker-compose
curl -Ls https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# bashrc & vimrc
cp bashrc /root/.bashrc
echo "set mouse-=a" > /root/.vimrc
source /root/.bashrc

# authorized_keys
mkdir /root/.ssh
chmod 700 /root/.ssh
cp authorized_keys /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# firewall
git clone https://github.com/webdudi/iptables-boilerplate /etc/firewall
make -C /etc/firewall/install install
systemctl restart firewall.service
systemctl restart docker.service

# set docker to work without changing iptables
sed -E 's/^(ExecStart.*)$/\1 --iptables=false/g' -i /lib/systemd/system/docker.service 
systemctl daemon-reload
cp firewall_docker.sh /etc/firewall/custom/docker.sh
sed -E 's/^(ipv4_forwarding.*)$/ipv4_forwarding=true/g' -i /etc/firewall/firewall.conf
systemctl restart firewall.service
systemctl restart docker.service

# nodejs
curl -sL https://deb.nodesource.com/setup_11.x | bash -
apt install -y nodejs

# duply
curl -Ls https://github.com/Oefenweb/duply/raw/master/duply.sh -o /usr/local/bin/duply
chmod 755 /usr/local/bin/duply

# monitoring
dpkg -i ./check_mk/check-mk-agent_1.5.0p11-1_all.deb
cp check_mk/check_docker_container /usr/lib/check_mk_agent/local/check_docker_container
cp check_mk/check_service -o /usr/lib/check_mk_agent/local/check_service
chmod +x /usr/lib/check_mk_agent/local/*

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/disable_ipv6.conf

# disable low-level wrning to console
echo "kernel.printk = 3 4 1 3" > /etc/sysctl.d/disable_console_warnings.conf


# assigning interface names to the hardware addresses of network adapters 

###ip addr | grep ": eth" | awk '{print $2}' | while read interface; do interface=${interface/:/};hwaddr=$(ip addr show $interface | grep ether | awk '{print $2}'); echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="'$hwaddr'", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="'$interface'"' >> /etc/udev/rules.d/70-persistent-net.rules; done


# Postfix main.cf fix
externalAddr=$(ifconfig eth0 | grep "inet " | awk '{print $2}')
cp /etc/postfix/main.cf /etc/postfix/main.cf.bak
postconf -e "mydestination=\$myhostname, localhost, localhost.localdomain, localhost"
postconf -e "relayhost ="
postconf -e "mynetworks=127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.0.0.0/8"
postconf -e "mailbox_size_limit=0"
postconf -e "recipient_delimiter=+"
postconf -e "inet_interfaces = 127.0.0.1 $externalAddr"
postconf -e "default_transport=smtp"
postconf -e "relay_transport=smtp"
postconf -e "inet_protocols=ipv4"
postconf -e "smtp_generic_maps = hash:/etc/postfix/generic"

echo "root@$hostname no-reply@$hostname" > /etc/postfix/generic 
echo "www-data@$hostname no-reply@$hostname" >> /etc/postfix/generic 
postmap /etc/postfix/generic 
/etc/init.d/postfix restart




echo ""
echo ""
echo ""
echo "Now you have a decent server ;)"
echo ""
echo "Almost finished, the only thing left is to reboot."
echo ""
echo "If you have such a possibility then go to the OCI settings and change the SCSI Controller to \"LSI Logic Pararell\"."
echo "Thanks to this your OS will better support detection of changes in hard drives scope, both enlarging and adding new ones."
echo "Changing the SCSI Controller will force OCI reboot - you will not have to perform this manually."
echo ""
echo ""
read -p "[press ENTER, if you want to reboot manually]"
reboot


