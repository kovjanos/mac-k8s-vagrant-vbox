#!/bin/bash

set -e
IFNAME=$1
DNS=$2



### hostnames setup
echo "Using interface: ${IFNAME}"
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# remove ubuntu entry
. /etc/os-release
sed -e "/^.*ubuntu-${VERSION_CODENAME}.*/d" -i /etc/hosts

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




### DNS update
echo "Using DNS address: ${DNS}"
sed -i -e "s/#DNS=/DNS=${DNS}/" /etc/systemd/resolved.conf
service systemd-resolved restart



### ssh-keys
if [ -f /vagrant/local/my-ssh-key.pub ]; then
  if [ ! $(grep $(cat /vagrant/local/my-ssh-key.pub | cut -f2 -d" ") /root/.ssh/authorized_keys) ]; then 
    cat /vagrant/local/my-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
    cat /vagrant/local/my-ssh-key.pub >> /root/.ssh/authorized_keys
  fi
fi
if [ -f /vagrant/local/ssh-keys/id_rsa ]; then
  echo "Reusing id_rsa from /vagrant/local/ssh-keys/"
else
  mkdir -p /vagrant/local/ssh-keys
  ssh-keygen -b 2048 -t rsa -f /vagrant/local/ssh-keys/id_rsa -q -N ""
fi
if [ -f /vagrant/local/ssh-keys/id_rsa ]; then
  if [ ! -f /root/.ssh/id_rsa ]; then 
    cp /vagrant/local/ssh-keys/id_rsa* /root/.ssh/
    cat /root/.ssh/id_rsa.pub  >> /root/.ssh/authorized_keys
    echo "Host kube*" > /root/.ssh/config
    echo "  StrictHostKeyChecking no" >> /root/.ssh/config
  fi
else
  echo "ERROR: missing /vagrant/local/ssh-keys/id_rsa !"
  exit 127
fi

