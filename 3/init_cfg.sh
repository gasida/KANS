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

# Letting iptables see bridged traffic
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# local dns setting
echo "192.168.10.10 k8s-m" >> /etc/hosts
echo "192.168.20.100 k8s-w0" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done

# apparmor disable
systemctl stop apparmor && systemctl disable apparmor

# package install
apt update
apt-get install bridge-utils net-tools jq tree resolvconf wireguard ipset -y

# config dnsserver ip
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

# docker install
curl -fsSL https://get.docker.com | sh

# Cgroup Driver systemd
cat <<EOF | tee /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOF
systemctl daemon-reload && systemctl restart docker

# swap off
swapoff -a

# Installing kubeadm kubelet and kubectl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=1.22.6-00 kubectl=1.22.6-00 kubeadm=1.22.6-00
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet
