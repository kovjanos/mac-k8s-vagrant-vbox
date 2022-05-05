#!/bin/bash

. /vagrant/config



### kubeadm init
mkdir -p /vagrant/local/k8s

kubeadm init \
--kubernetes-version=${K8S_VERSION} \
--apiserver-advertise-address=$(hostname -i) \
--control-plane-endpoint=${K8S_CONTROLPLANE_ENDPOINT} \
--service-cidr=${K8S_SVC_CIDR} \
--skip-token-print 2>&1 | tee /vagrant/local/k8s/init.$(hostname -s).out

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

cat /etc/kubernetes/admin.conf \
  | sed -e 's/:6443$/:36443/' \
  | sed -e 's/cluster: kubernetes/cluster: vagrant/' \
  | sed -e 's/kubernetes-admin@kubernetes/vagrant-admin@vagrant/' \
  | sed -e 's/user: kubernetes-admin/user: vagrant-admin/' \
  | sed -e 's/name: kubernetes-admin/name: vagrant-admin/' \
  | sed -e 's/name: kubernetes/name: vagrant/'  \
  > /vagrant/local/kube-vagrant-config 



### install add-ons
echo "Deployeing WEAVE CNI..."
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"  2>&1 | tee /vagrant/local/k8s/weave.$(hostname -s).out

echo "Deploying Nginx Ingress Controller ${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}/deploy/static/provider/baremetal/deploy.yaml

echo "Patching Nginx Ingress Controller for static NodePort values [80:30001,443:30002]"
kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":80,"nodePort":30001}]}}'
kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":443,"nodePort":30002}]}}'

echo "Adding K8s Desktop..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${K8S_DESKTOP_VERSION}/aio/deploy/recommended.yaml




### create tokens for workers t ojoin
# in HA mode, removing the worker join script would be the loadbalancer's responsibility
# now it's tighten to the master1
if [ "X${K8S_CONTROLPLANE_ENDPOINT}" == "X$(hostname -s)" ]; then
  rm -rf /vagrant/local/k8s/join-worker.sh
fi
# only first master should create the join script
if [ ! -f /vagrant/local/k8s/join-worker.sh ]; then 
  echo "#!/bin/bash" > /vagrant/local/k8s/join-worker.sh
  kubeadm token create --print-join-command --ttl 0 >> /vagrant/local/k8s/join-worker.sh
fi

