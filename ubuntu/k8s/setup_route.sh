#!/bin/sh
IFNAME=$1

. /vagrant/ubuntu/k8s/config

ALREADYHAS=$(ip route |grep ${KUBE_SVC_CIDR} |wc -l)

if [ ${ALREADYHAS} -gt 0 ]; then
  echo "K8S SVC address route already set, exiting..."
else
  ip route add ${KUBE_SVC_CIDR} dev ${IFNAME} src $(hostname -i)
fi
