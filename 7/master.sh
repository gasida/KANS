#!/usr/bin/env bash

echo ">>>> K8S Controlplane config Start <<<<"

echo "[TASK 1] Initial Kubernetes - Skip Kube-proxy , Pod CIDR 172.16.0.0/16 , API Server 192.168.10.10"
kubeadm init --skip-phases=addon/kube-proxy --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10 >/dev/null 2>&1

echo "[TASK 2] Setting kube config file"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "[TASK 3] Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash >/dev/null 2>&1

echo "[TASK 4] Install Clilium(v1.11.1) Hubble(v0.9.0) w/Helm"
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1
helm install cilium cilium/cilium --version 1.11.1 --namespace kube-system --set kubeProxyReplacement=strict --set k8sServiceHost=192.168.10.10 --set k8sServicePort=6443 --set tunnel=disabled --set autoDirectNodeRoutes=true --set ipv4NativeRoutingCIDR=192.168.0.0/16 --set ipam.operator.clusterPoolIPv4PodCIDR=172.16.0.0/16 --set hubble.relay.enabled=true --set hubble.ui.enabled=true --set operator.replicas=1 --set hostServices.enabled=true --set endpointRoutes.enabled=true --set devices={"enp0s8,enp0s3"} --set bpf.masquerade=true >/dev/null 2>&1
curl -s -L --remote-name-all https://github.com/cilium/cilium-cli/releases/download/v0.10.2/cilium-linux-amd64.tar.gz
tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin >/dev/null 2>&1

# Install Hubble Client
#export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -s -L --remote-name-all https://github.com/cilium/hubble/releases/download/v0.9.0/hubble-linux-amd64.tar.gz
tar xzvfC hubble-linux-amd64.tar.gz /usr/local/bin >/dev/null 2>&1

echo "[TASK 5] Source the completion"
# source bash-completion for kubectl kubeadm
source <(kubectl completion bash)
source <(kubeadm completion bash)
## Source the completion script in your ~/.bashrc file
echo 'source <(kubectl completion bash)' >> /etc/profile
echo 'source <(kubeadm completion bash)' >> /etc/profile

echo "[TASK 6] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

echo "[TASK 7] Install Kubectx & Kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

echo "[TASK 8] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
KUBE_PS1_SYMBOL_DEFAULT=🍒
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT
kubectl config rename-context "kubernetes-admin@kubernetes" "Cilium-k8s" >/dev/null 2>&1

echo "[TASK 9] Install Packages"
apt install kubetail etcd-client -y -qq >/dev/null 2>&1

echo ">>>> K8S Controlplane Config End <<<<"
