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
        software-properties-common \
        bash-completion \
        binutils





### install podman
echo "Installing podman..."
. /etc/os-release
# override VERSION_ID with PODMAN_UBUNTU_VERSION until released for 22.04 
VERSION_ID=${PODMAN_UBUNTU_VERSION}
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/testing/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:testing.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/testing/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
apt-get update -qq
apt-get -qq -y install podman cri-tools containers-common
rm /etc/apt/sources.list.d/devel:kubic:libcontainers:testing.list
cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['docker.io']
EOF





### k8s, containerd
echo "Installing k8s, ver: ${K8S_VERSION}..."
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get -qq update 
apt-get -y -qq install  docker.io containerd kubelet=${K8S_VERSION}${K8S_VERSION_P} kubeadm=${K8S_VERSION}${K8S_VERSION_P} kubectl=${K8S_VERSION}${K8S_VERSION_P} kubernetes-cni
apt-mark hold kubelet kubeadm kubectl kubernetes-cni





### containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
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
sudo mkdir -p /etc/containerd

### containerd config
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF

### crictl uses containerd as default
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

### kubelet should use containerd
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF



### pull k8s images
echo "Fetching k8s images..."
kubeadm config images pull --kubernetes-version=${K8S_VERSION}


### etcdctl
echo "Installing etcdctl..."
ETCDCTL_VERSION_FULL=etcd-v${ETCDCTL_VERSION}-linux-amd64
wget -q https://github.com/etcd-io/etcd/releases/download/v${ETCDCTL_VERSION}/${ETCDCTL_VERSION_FULL}.tar.gz
tar -xzf ${ETCDCTL_VERSION_FULL}.tar.gz
mv ${ETCDCTL_VERSION_FULL}/etcdctl /usr/bin/
rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz




### Install k9s
echo "Installing k9s..."
rm -f k9s_Linux_x86_64.tar.gz
wget -q https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_x86_64.tar.gz
tar -xzf k9s_Linux_x86_64.tar.gz
rm -f /usr/bin/k9s 
mv k9s /usr/bin/
rm -f k9s_Linux_x86_64.tar.gz




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
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet && systemctl start kubelet

