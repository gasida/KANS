#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"


echo "[TASK 1] Setting SSH with Root"
printf "qwe123\nqwe123\n" | passwd >/dev/null 2>&1
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
systemctl restart sshd  >/dev/null 2>&1

echo "[TASK 2] Profile & Bashrc & Change Timezone"
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtimew

echo "[TASK 3] Disable AppArmor"
systemctl stop ufw && systemctl disable ufw >/dev/null 2>&1
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 4] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-m" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done
echo "192.168.20.100 k8s-w0" >> /etc/hosts

echo "[TASK 5] Add Kernel setting - IP Forwarding"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p >/dev/null 2>&1
sysctl --system >/dev/null 2>&1

echo "[TASK 6] Setting Dummy Interface"
modprobe dummy
ip link add loop1 type dummy
ip link set loop1 up
ip addr add 10.1.1.254/24 dev loop1

ip link add loop2 type dummy
ip link set loop2 up
ip addr add 10.1.2.254/24 dev loop2

echo "[TASK 7] Install Packages"
apt update -qq >/dev/null 2>&1
#apt-get install sshpass net-tools jq tree resolvconf ngrep iputils-arping quagga -y -qq >/dev/null 2>&1
apt-get install net-tools jq tree iputils-arping -y -qq >/dev/null 2>&1

echo "[TASK 8] Config FRR Software IP routing suite"
apt-get install frr -y -qq >/dev/null 2>&1
sed -i 's/^pimd=no/pimd=yes/' /etc/frr/daemons
sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons
sed -i 's/^#MAX_FDS=1024/MAX_FDS=1024/' /etc/frr/daemons

cat <<EOF > /etc/frr/frr.conf
frr version 8.1
frr defaults traditional
hostname localhost.localdomain
log syslog informational
no ipv6 forwarding
!
router bgp 64512
 no bgp ebgp-requires-policy
 neighbor k8s peer-group
 neighbor k8s remote-as 64512
 bgp listen range 192.168.0.0/16 peer-group k8s
 !
 address-family ipv4 unicast
  network 10.1.1.0/24
  network 10.1.2.0/24
  neighbor k8s soft-reconfiguration inbound
  maximum-paths 4
  maximum-paths ibgp 4
 exit-address-family
!
line vty
!
EOF
systemctl restart frr >/dev/null 2>&1


echo ">>>> Initial Config End <<<<"
