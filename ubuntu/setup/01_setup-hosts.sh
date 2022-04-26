#!/bin/bash
set -e
IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# remove ubuntu entry
sed -e '/^.*ubuntu-jammy.*/d' -i /etc/hosts


# Update /etc/hosts about other hosts
cat >> /etc/hosts.cluster <<EOF
192.168.57.11 kubemaster1
192.168.57.12 kubemaster2
192.168.57.13 kubemaster3
192.168.57.14 kubemaster4
192.168.57.21 kubenode1
192.168.57.22 kubenode2
192.168.57.23 kubenode3
192.168.57.24 kubenode4
192.168.57.25 kubenode5
192.168.57.26 kubenode6
192.168.57.27 kubenode7
192.168.57.28 kubenode8
EOF

cat /etc/hosts.cluster |grep -v "${HOSTNAME}$" >> /etc/hosts
