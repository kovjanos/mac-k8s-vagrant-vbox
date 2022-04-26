#!/bin/bash

echo "sysctl net.bridge.bridge-nf-call-iptables=1" > /etc/sysctl.d/99-k8s.conf
sysctl -f /etc/sysctl.d/99-k8s.conf

