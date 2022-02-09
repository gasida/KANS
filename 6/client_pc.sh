#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"
echo "[TASK 1] Setting Root Password"
printf "qwe123\nqwe123\n" | passwd >/dev/null 2>&1

echo "[TASK 2] Setting Sshd Config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd

echo "[TASK 3] Setting Profile & Bashrc"
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc

echo "[TASK 4] Disable AppArmor"
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 5] Install Packages"
apt update -qq >/dev/null 2>&1
apt-get install sshpass net-tools jq tree resolvconf lynx -y -qq >/dev/null 2>&1

echo "[TASK 6] Change DNS Server IP Address"
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

echo "[TASK 7] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-m" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.10.10$i k8s-w$i" >> /etc/hosts; done

echo "[TASK 8] Install kubectl"
curl -s -LO https://dl.k8s.io/release/v1.22.6/bin/linux/amd64/kubectl 2>&1
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl 2>&1

echo "[TASK 9] Config kubeconfig"
mkdir -p $HOME/.kube
sshpass -p "qwe123" scp -o StrictHostKeyChecking=no root@k8s-m:/etc/kubernetes/admin.conf $HOME/.kube/config 2>&1

echo "[TASK 10] Source the completion"
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 11] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

echo "[TASK 12] Install calicoctl Tool - v3.21.4"
curl -L https://github.com/projectcalico/calico/releases/download/v3.21.4/calicoctl-linux-amd64 -o calicoctl >/dev/null 2>&1
chmod +x calicoctl && mv calicoctl /usr/bin

echo ">>>> Initial Config End <<<<"
