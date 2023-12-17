#!/bin/bash

. /vagrant/config

export DEBIAN_FRONTEND=noninteractive


### disable swap
swapoff -a
sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab




### cleanup & update OS
echo "Cleanup..."
sudo apt -y -qq -oDpkg::Use-Pty=false remove unattended-upgrades
kubeadm reset -f || true
crictl rm --force $(crictl ps -a -q) || true
apt-mark unhold kubelet kubeadm kubectl kubernetes-cni || true
apt-get remove -y docker.io containerd kubelet kubeadm kubectl kubernetes-cni || true
apt-get autoremove -y
systemctl daemon-reload
sudo apt-get -y -qq update
sudo apt-get -y -qq -oDpkg::Use-Pty=false -oDpkg::Options::=--force-confdef -oDpkg::Options::=--force-confold upgrade -qq -oDpkg::Use-Pty=false
sudo apt-get -y -qq -oDpkg::Use-Pty=false install net-tools




### Install Guest Addons
echo "Installing guest addition for ${GUEST_ADDITION_VERSION}..."
export DEBIAN_FRONTEND=noninteractive
GUEST_ADDITION_ISO=VBoxGuestAdditions_${GUEST_ADDITION_VERSION}.iso
GUEST_ADDITION_MOUNT=/media/VBoxGuestAdditions
apt-get -y -qq -o "Dpkg::Use-Pty=0" install linux-headers-$(uname -r) build-essential dkms bzip2
wget -q http://download.virtualbox.org/virtualbox/${GUEST_ADDITION_VERSION}/${GUEST_ADDITION_ISO}
mkdir -p ${GUEST_ADDITION_MOUNT}
mount -o loop,ro ${GUEST_ADDITION_ISO} ${GUEST_ADDITION_MOUNT}
sh ${GUEST_ADDITION_MOUNT}/VBoxLinuxAdditions.run
rm ${GUEST_ADDITION_ISO}
umount ${GUEST_ADDITION_MOUNT}
rmdir ${GUEST_ADDITION_MOUNT}




### extras
echo "Installing extra packages..."
apt-get -y -qq -o Dpkg::Use-Pty=false install  \
        apt-transport-https \
        ca-certificates \
        curl \
        gpg \
        software-properties-common \
        bash-completion \
        binutils







### install cri
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$CRI_OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRI_VERSION/$CRI_OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRI_VERSION.list

mkdir -p /usr/share/keyrings
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$CRI_OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRI_VERSION/$CRI_OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

apt-get update -qq
apt-get -qq -y install cri-o cri-o-runc 

cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['registry.k8s.io', 'registry.access.redhat.com', 'registry.fedoraproject.org', 'quay.io', 'docker.io']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF







### k8s
echo "Installing k8s, ver: ${K8S_VERSION}..."

#curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
#echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION_MAJOR}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION_MAJOR}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get -qq update
#apt-get -y -qq install kubelet=${K8S_VERSION}${K8S_VERSION_P} kubeadm=${K8S_VERSION}${K8S_VERSION_P} kubectl=${K8S_VERSION}${K8S_VERSION_P}
apt-get -y -qq install  kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl kubernetes-cni

### k8s
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system




### kubelet should use c
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///var/run/crio/crio.sock"
EOF

rm -rf /etc/cni/net.d/100-crio-bridge.conf

sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

### pull k8s images
echo "Fetching k8s images..."
kubeadm config images pull --kubernetes-version=${K8S_VERSION}

echo "Fetchng Weave images..."
crictl pull weaveworks/weave-kube:latest
crictl pull weaveworks/weave-npc:latest

echo "Fetching k8s-dashboard images..."
crictl pull kubernetesui/dashboard:v${K8S_DASHBOARD_VERSION}
#crictl pull kubernetesui/metrics-scraper:v${K8S_DASHBOARD_METRICS}

echo "Fetching ingress-nginx images..."
crictl pull ingress-nginx/controller:v${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}



### etcdctl
echo "Installing etcdctl..."
ETCDCTL_VERSION=$(kubeadm config images list --kubernetes-version ${K8S_VERSION}  |grep etcd |cut -f2 -d: |cut -f1 -d-)
ETCDCTL_VERSION_FULL=etcd-v${ETCDCTL_VERSION}-linux-amd64
wget -q https://github.com/etcd-io/etcd/releases/download/v${ETCDCTL_VERSION}/${ETCDCTL_VERSION_FULL}.tar.gz
tar -xzf ${ETCDCTL_VERSION_FULL}.tar.gz
mv ${ETCDCTL_VERSION_FULL}/etcdctl /usr/bin/
rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz




### Install k9s
echo "Installing k9s..."
K9S_FILE=k9s_Linux_amd64.tar.gz
rm -f ${K9S_FILE}
wget -q https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/${K9S_FILE}
tar -xzf ${K9S_FILE}
rm -f /usr/bin/k9s 
mv k9s /usr/bin/
rm -f ${K9S_FILE}




### setup terminal
echo "Configuring bashrc|vimrc..."
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc




### cleanup
echo "Cache cleanup..."
apt-get -qq clean 



### start services
echo "Daemon restarts..."
systemctl daemon-reload
systemctl enable kubelet && systemctl start kubelet

