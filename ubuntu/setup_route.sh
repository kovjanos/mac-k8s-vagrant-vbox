#!/bin/sh

IFNAME=$1

. /vagrant/config

ALREADYHAS=$(ip route |grep ${K8S_SVC_CIDR} |wc -l)

if [ ${ALREADYHAS} -gt 0 ]; then
  echo "K8S SVC address route already set, exiting..."
else
  ip route add ${K8S_SVC_CIDR} dev ${IFNAME} src $(hostname -i)
fi
