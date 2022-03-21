#!/usr/bin/env bash

echo "[TASK 11] Setting SSH Key"
ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
# Copy our key the first time to allow
for (( i=1; i<=$1; i++  )); do sshpass -p "qwe123" ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no "root@k8s-n$i" >/dev/null 2>&1; done
sshpass -p "qwe123" ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@k8s-n0 >/dev/null 2>&1
 
echo "[TASK 12] Install Packages"
apt install -y python3-pip -qq >/dev/null 2>&1

echo "[TASK 13] Git Clone"
git clone -b v2.18.0 https://github.com/kubernetes-sigs/kubespray.git /root/kubespray >/dev/null 2>&1

echo "[TASK 14] Install Kubespray Requirements"
pip3 install -r /root/kubespray/requirements.txt >/dev/null 2>&1

echo "[TASK 15] Install K8s with Kubespray"
cp -rfp /root/kubespray/inventory/sample /root/kubespray/inventory/mycluster
#sed -i 's|kube_version: v1.22.5|kube_version: v1.22.1|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's|kube_pods_subnet: 10.233.64.0\/18|kube_pods_subnet: 172.16.0.0\/16|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's|kube_service_addresses: 10.233.0.0\/18|kube_service_addresses: 10.200.1.0\/24|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's|kube_proxy_strict_arp: false|kube_proxy_strict_arp: true|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i 's|helm_enabled: false|helm_enabled: true|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml
sed -i 's|metrics_server_enabled: false|metrics_server_enabled: true|g' /root/kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml
cat <<EOF > /root/kubespray/inventory/mycluster/hosts.yml
all:
  hosts:
    k8s-n0:
      ansible_host: 192.168.10.100
      ip: 192.168.10.100
      access_ip: 192.168.10.100
    k8s-n1:
      ansible_host: 192.168.10.101
      ip: 192.168.10.101
      access_ip: 192.168.10.101                                              
    k8s-n2:
      ansible_host: 192.168.10.102
      ip: 192.168.10.102
      access_ip: 192.168.10.102
  children:
    kube_control_plane:                                                                         
      hosts:
        k8s-n0:
        k8s-n1:
        k8s-n2:
    kube_node:                                                                                              
      hosts:
        k8s-n0:
        k8s-n1:
        k8s-n2:
    etcd:                                                                                         
      hosts:
        k8s-n0:
        k8s-n1:
        k8s-n2:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
        calico_rr:  
    calico_rr:  
      hosts: {}
EOF
cd /root/kubespray
ansible-playbook -i /root/kubespray/inventory/mycluster/hosts.yml --become --become-user=root /root/kubespray/cluster.yml
cd /root

echo "[TASK 16] ETC"
# source bash-completion for kubectl kubeadm
source <(kubectl completion bash)
## Source the completion script in your ~/.bashrc file
echo 'source <(kubectl completion bash)' >> /etc/profile

## Alias kubectl to k
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

# Install Kubectx & Kubens
git clone https://github.com/ahmetb/kubectx /opt/kubectx >/dev/null 2>&1
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

# Install Kubeps & Setting PS1"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1 >/dev/null 2>&1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
KUBE_PS1_SYMBOL_DEFAULT=🐤
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT
kubectl config rename-context "kubernetes-admin@cluster.local" "kubespray-k8s" >/dev/null 2>&1

# Install Packages"
apt install kubetail etcd-client -y -qq >/dev/null 2>&1

echo ">>>> Initial Config End <<<<"
