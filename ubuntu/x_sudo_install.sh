#!/bin/bash

sudo chmod a+x /vagrant/ubuntu/*.sh

sudo /vagrant/ubuntu/01_install-hosts.sh

# packer 1.8.0 has outdated go/crypt libs so we injected a modern ssh-key, time to remove it
sudo sed -i '/ecdsa-sha2-nistp521.*vagrant insecure public key/d' /home/vagrant/.ssh/authorized_keys
