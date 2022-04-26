#!/bin/bash

. /vagrant/ubuntu/k8s/config

KUBE_CP_ADDRESS=$(hostname -i)



mkdir -p /vagrant/local/k8s

kubeadm init \
--apiserver-advertise-address=${KUBE_CP_ADDRESS} \
--control-plane-endpoint=${KUBE_CP_ENDPOINT} \
--service-cidr=${KUBE_SVC_CIDR} 2>&1 | tee /vagrant/local/k8s/init.$(hostname -s).out

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"  2>&1 | tee /vagrant/local/k8s/weave.$(hostname -s).out


# in HA mode, removing the worker join script would be the loadbalancer's responsibility
# now it's tighten to the master1
if [ "X${KUBE_CP_ENDPOINT}" == "X$(hostname -s)" ]; then
  rm -rf /vagrant/local/k8s/join-worker.sh
fi

# only first master should create the join script
if [ ! -f /vagrant/local/k8s/join-worker.sh ]; then 
  echo "#!/bin/bash" > /vagrant/local/k8s/join-worker.sh
  grep -A4 "join any number of worker nodes" /vagrant/local/k8s/init.kubemaster1.out | grep -A1 "kubeadm join" >> /vagrant/local/k8s/join-worker.sh
fi

