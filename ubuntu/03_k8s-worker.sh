#!/bin/bash

. /vagrant/config


if [ -f /vagrant/local/k8s/join-worker.sh ]; then
  sh /vagrant/local/k8s/join-worker.sh  2>&1 | tee /vagrant/local/k8s/join.$(hostname -s).out


  if [ -f /vagrant/local/kube-config ]; then
    echo "Waiting 90s for ingress-nginx-controller to become available..."
    kubectl --kubeconfig=/vagrant/local/kube-config wait deployment -n ingress-nginx ingress-nginx-controller --for condition=Available=True --timeout=90s
    kubectl --kubeconfig=/vagrant/local/kube-config -n kubernetes-dashboard create ingress kubernetes-dashboard --class=nginx --rule="kubernetes-dashboard/*=kubernetes-dashboard:443,tls" --annotation nginx.ingress.kubernetes.io/backend-protocol=HTTPS
    rm -f /vagrant/local/kube-config
  fi
fi

