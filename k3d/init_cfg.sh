#!/usr/bin/env bash

echo ">>>> Initial Config Start <<<<"
echo "[TASK 1] Setting Root Password"
printf "qwe123\nqwe123\n" | passwd >/dev/null 2>&1

echo "[TASK 2] Setting Sshd Config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd  >/dev/null 2>&1

echo "[TASK 3] Change Timezone & Install Ccat & Setting Profile & Bashrc"
# Change Timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
# Install Ccat
curl -s -L https://github.com/owenthereal/ccat/releases/download/v1.1.0/linux-amd64-1.1.0.tar.gz | tar -xz  -C /tmp/
cp /tmp/linux-amd64-1.1.0/ccat /usr/local/bin/
chmod +x /usr/local/bin/ccat
#  Setting Profile & Bashrc
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc
echo 'alias cat=/usr/local/bin/ccat' >> /etc/profile

echo "[TASK 4] Disable AppArmor"
systemctl stop ufw && systemctl disable ufw >/dev/null 2>&1
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 5] Install Packages"
apt update -qq >/dev/null 2>&1
apt-get install sshpass bridge-utils net-tools jq tree resolvconf ngrep ipset iputils-arping ipvsadm kubetail golang-go direnv make unzip -y -qq >/dev/null 2>&1

echo "[TASK 6] Change DNS Server IP Address"
echo -e "nameserver 1.1.1.1" > /etc/resolvconf/resolv.conf.d/head
resolvconf -u

echo "[TASK 7] Install k3d & golangci-lint"
# curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.2.2 bash >/dev/null 2>&1
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash >/dev/null 2>&1
# binary will be $(go env GOPATH)/bin/golangci-lint
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.45.2 >/dev/null 2>&1
cp $(go env GOPATH)/bin/golangci-lint /usr/local/bin
# golangci-lint --version

echo "[TASK 8] Install Docker Engine"
curl -fsSL https://get.docker.com | sh >/dev/null 2>&1

echo "[TASK 9] Change Cgroup Driver Using Systemd"
cat <<EOT > /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOT
systemctl daemon-reload >/dev/null 2>&1
systemctl restart docker

echo "[TASK 10] Disable and turn off SWAP"
swapoff -a

echo "[TASK 11] Install kubectl"
#curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/v1.23.4/bin/linux/amd64/kubectl" >/dev/null 2>&1
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "[TASK 12] Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash >/dev/null 2>&1

echo "[TASK 13] Source the completion"
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 14] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

echo "[TASK 15] Install Kubectx & Kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

echo "[TASK 16] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
KUBE_PS1_SYMBOL_DEFAULT=🥰
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT

echo "[TASK 17] To increase Resource limits"
# cat /proc/sys/fs/inotify/max_user_watches >> 8192
# cat /proc/sys/fs/inotify/max_user_instances >> 128
sysctl fs.inotify.max_user_watches=524288 >/dev/null 2>&1
sysctl fs.inotify.max_user_instances=512 >/dev/null 2>&1
echo 'fs.inotify.max_user_watches=524288' > /etc/sysctl.d/99-kind.conf
echo 'fs.inotify.max_user_instances=512'  > /etc/sysctl.d/99-kind.conf
sysctl -p >/dev/null 2>&1
sysctl --system >/dev/null 2>&1

#echo "[TASK 18] Install AWS CLI v2"
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# ./aws/install --bin-dir /usr/bin --install-dir /usr/bin --update
