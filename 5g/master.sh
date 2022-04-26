#!/usr/bin/env bash

echo ">>>> K8S Controlplane config Start <<<<"

echo "[TASK 1] Initial Kubernetes - Pod CIDR 172.16.0.0/16 , API Server 192.168.10.10"
#kubeadm init --token 123456.1234567890123456 --token-ttl 0 --apiserver-advertise-address=192.168.10.10
kubeadm init --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10

echo "[TASK 2] Setting kube config file"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "[TASK 3] Install Calico CNI - v$2"
#kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/gasida/KANS/main/3/calico-kans-v$2.yaml

echo "[TASK 4] Install calicoctl Tool - v$2"
curl -L https://github.com/projectcalico/calico/releases/download/v$2/calicoctl-linux-amd64 -o calicoctl
chmod +x calicoctl && mv calicoctl /usr/bin

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
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

echo "[TASK 8] Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=false
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT
kubectl config rename-context "kubernetes-admin@kubernetes" "$1-Lab"

echo "[TASK 9] Install Packages"
apt install kubetail etcd-client -y -qq

echo "[TASK 10] Install Helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "[TASK 11] Install Metrics server - v0.6.1"
kubectl apply -f https://raw.githubusercontent.com/gasida/KANS/main/8/metrics-server.yaml

echo "[TASK 12] Dynamically provisioning persistent local storage with Kubernetes - v0.0.22"
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo ">>>> K8S Controlplane Config End <<<<"
