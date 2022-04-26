#!/bin/bash

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

