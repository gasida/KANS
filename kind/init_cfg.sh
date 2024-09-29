#!/usr/bin/env bash

echo "[TASK 0] Setting SSH with Root"
printf "qwe123\nqwe123\n" | passwd >/dev/null 2>&1
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
systemctl restart sshd  >/dev/null 2>&1

echo "[TASK 1] Profile & Bashrc"
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> .bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

echo "[TASK 2] Disable AppArmor"
systemctl stop ufw && systemctl disable ufw >/dev/null 2>&1
systemctl stop apparmor && systemctl disable apparmor >/dev/null 2>&1

echo "[TASK 3] Install Packages"
apt update -qq >/dev/null 2>&1
apt-get install bridge-utils net-tools jq tree unzip kubecolor -y -qq >/dev/null 2>&1

echo "[TASK 4] Install Kind"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64 >/dev/null 2>&1
chmod +x ./kind
mv ./kind /usr/bin

echo "[TASK 5] Install Docker Engine"
curl -fsSL https://get.docker.com | sh >/dev/null 2>&1

echo "[TASK 6] Install kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" >/dev/null 2>&1
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "[TASK 7] Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash >/dev/null 2>&1

echo "[TASK 8] Source the completion"
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 9] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile
echo 'alias kubectl=kubecolor' >> /etc/profile

echo "[TASK 10] Install Kubectx & Kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

echo "[TASK 11] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT

echo "[TASK 12] To increase Resource limits"
# cat /proc/sys/fs/inotify/max_user_watches >> 8192
# cat /proc/sys/fs/inotify/max_user_instances >> 128
sysctl fs.inotify.max_user_watches=524288 >/dev/null 2>&1
sysctl fs.inotify.max_user_instances=512 >/dev/null 2>&1
echo 'fs.inotify.max_user_watches=524288' > /etc/sysctl.d/99-kind.conf
echo 'fs.inotify.max_user_instances=512'  > /etc/sysctl.d/99-kind.conf
sysctl -p >/dev/null 2>&1
sysctl --system >/dev/null 2>&1
