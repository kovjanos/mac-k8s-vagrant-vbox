#!/bin/bash

. /vagrant/config

if [ -f /vagrant/local/k8s/join-worker.sh ]; then
  sh /vagrant/local/k8s/join-worker.sh  2>&1 | tee /vagrant/local/k8s/join.$(hostname -s).out
fi
