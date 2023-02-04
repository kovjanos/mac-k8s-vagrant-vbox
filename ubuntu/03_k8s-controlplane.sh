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

# let's create one for the first worker for the ingress-nginx command...
cat /etc/kubernetes/admin.conf \
  | sed -e 's/cluster: kubernetes/cluster: vagrant/' \
  | sed -e 's/kubernetes-admin@kubernetes/vagrant-admin@vagrant/' \
  | sed -e 's/user: kubernetes-admin/user: vagrant-admin/' \
  | sed -e 's/name: kubernetes-admin/name: vagrant-admin/' \
  | sed -e 's/name: kubernetes/name: vagrant/'  \
  > /vagrant/local/kube-config 




### install add-ons
echo "Deploying WEAVE CNI..."
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v${K8S_WEAVE_NET_VERSION}/weave-daemonset-k8s.yaml 2>&1 | tee /vagrant/local/k8s/weave.$(hostname -s).out


echo "Deploying Nginx Ingress Controller v${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${KUBE_NGINX_BAREMETAL_INGRESS_CONTROLLER_VERSION}/deploy/static/provider/baremetal/deploy.yaml 2>&1 | tee /vagrant/local/k8s/ingress-nginx.$(hostname -s).out

echo "Patching Nginx Ingress Controller for static NodePort values [80:30001,443:30002]"
kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":80,"nodePort":30001}]}}'
kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec":{"ports":[{"port":443,"nodePort":30002}]}}'



echo "Adding K8s Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${K8S_DASHBOARD_VERSION}/aio/deploy/recommended.yaml 2>&1 | tee /vagrant/local/k8s/dashboard.$(hostname -s).out

echo "  generating initial admin token for kubernetes-dashboard"
cat <<EOF | sudo tee /vagrant/local/k8s/dashboard-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kubernetes-dashboard-admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard-admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard-admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f /vagrant/local/k8s/dashboard-admin.yaml
kubectl -n kubernetes-dashboard create token kubernetes-dashboard-admin-user 2>&1 | tee /vagrant/local/k8s/kubernetes-dashboard-admin-token.$(hostname -s).out




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

