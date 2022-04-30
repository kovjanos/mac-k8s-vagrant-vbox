#!/bin/bash

K9S=0.25.18


rm -f k9s_Linux_x86_64.tar.gz
wget -q https://github.com/derailed/k9s/releases/download/v${K9S}/k9s_Linux_x86_64.tar.gz
tar -xzf k9s_Linux_x86_64.tar.gz

rm -f /usr/bin/k9s 
mv k9s /usr/bin/

rm -f k9s_Linux_x86_64.tar.gz

