#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"
echo "[TASK 1] Setting Root Password"
printf "qwe123\nqwe123\n" | passwd

echo "[TASK 2] Setting Sshd Config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

echo "[TASK 3] Change Timezone & Setting Profile & Bashrc"
# Change Timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

#  Setting Profile & Bashrc
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc

echo "[TASK 4] Disable ufw & AppArmor"
systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor

echo "[TASK 5] Install Packages"
apt update -qq
apt-get install prettyping sshpass bridge-utils net-tools jq tree resolvconf wireguard ngrep ipset iputils-arping ipvsadm -y -qq
# Install Batcat - https://github.com/sharkdp/bat
apt-get install bat -y
echo 'alias cat=batcat' >> /etc/profile

echo "[TASK 6] Change DNS Server IP Address"
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

echo "[TASK 7] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-m" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done

echo "[TASK 8] Install Docker Engine"
curl -fsSL https://get.docker.com | sh

echo "[TASK 9] Change Cgroup Driver Using Systemd"
cat <<EOT > /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOT
systemctl daemon-reload
systemctl restart docker

echo "[TASK 10] Disable and turn off SWAP"
swapoff -a

echo "[TASK 11] Install Kubernetes components (kubeadm, kubelet and kubectl) - v$2"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=$2-00 kubectl=$2-00 kubeadm=$2-00
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

echo ">>>> Initial Config End <<<<"
