#!/bin/bash

DNS=$1

echo "Using DNS address: ${DNS}"

sed -i -e "s/#DNS=/DNS=${DNS}/" /etc/systemd/resolved.conf

service systemd-resolved restart
