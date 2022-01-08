#!/usr/bin/env bash

# root password
echo ">>>> root password <<<<<<"
printf "qwe123\nqwe123\n" | passwd

# config sshd
echo ">>>> ssh-config <<<<<<"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

# profile bashrc settting
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc

# apparmor disable
systemctl stop apparmor && systemctl disable apparmor

# package install
apt update
apt-get install net-tools jq tree resolvconf iptraf-ng iputils-arping -y

# config dnsserver ip
echo -e "nameserver 168.126.63.1\nnameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

# ip forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
sysctl --system

# dummy interface 
modprobe dummy
ip link add loop1 type dummy
ip link set loop1 up
ip addr add 10.1.1.254/24 dev loop1
