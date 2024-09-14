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


echo "[TASK 5] Install Kubernetes components (kubeadm, kubelet and kubectl) - v$2"
# add kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$2/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$2/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# add docker-ce repo with containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc >/dev/null 2>&1
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# packets traversing the bridge are processed by iptables for filtering
echo 1 > /proc/sys/net/ipv4/ip_forward
# enable br_filter for iptables 
modprobe br_netfilter

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version
apt update -qq >/dev/null 2>&1
apt-get install -y kubelet kubectl kubeadm containerd.io >/dev/null 2>&1 && apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1

# containerd configure to default and cgroup managed by systemd 
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# avoid WARN&ERRO(default endpoints) when crictl run  
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

# ready to install for k8s 
systemctl restart containerd && systemctl enable containerd
systemctl enable --now kubelet


echo "[TASK 6] Install packages"
apt install tree jq bridge-utils net-tools conntrack ipset wireguard -y -qq >/dev/null 2>&1

echo ">>>> Initial Config End <<<<"