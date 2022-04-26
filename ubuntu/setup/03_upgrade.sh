#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt -y -qq -oDpkg::Use-Pty=false remove unattended-upgrades

apt-get -y -qq update
apt-get -y -qq -oDpkg::Use-Pty=false -oDpkg::Options::=--force-confdef -oDpkg::Options::=--force-confold upgrade -qq -oDpkg::Use-Pty=false
apt-get -y -qq -oDpkg::Use-Pty=false install net-tools

