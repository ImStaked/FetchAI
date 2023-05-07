#!/bin/bash

# Settings
MONIKER="<YOUR_MONIKER_HERE"
CHAIN_ID="fetchhub-4"

# Update the system and install prerequesits
sudo apt update && sudo apt upgrade -y && sudo apt autoremove 
sudo apt install make cmake gcc zip unzip pigz git -y

# Install go
wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.4.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
echo "export PATH=$PATH:~/go/bin" >> ~/.bashrc
source ~/.bashrc

# Build the binary from source
git clone https://github.com/fetchai/fetchd.git && cd fetchd
git checkout v0.10.6
make build && make install

# Ensure the correct configuration
rm ~/.fetchd/config/app.toml ~/.fetchd/config/config.toml
fetchd init $MONIKER --chain-id $CHAIN_ID
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/fetchhub-4/fetchhub-4/data/genesis_migrated_5300200.json --output ~/.fetchd/config/genesis.json

# Get latest snapshot
echo "Latest available snapshot timestamp : $(curl -s -I  https://storage.googleapis.com/fetch-ai-mainnet-snapshots/fetchhub-4-pruned.tgz | grep last-modified | cut -f3- -d' ')"
curl -v https://storage.googleapis.com/fetch-ai-mainnet-snapshots/fetchhub-4-pruned.tgz -o- 2>headers.out | tee >(md5sum > md5sum.out) | gunzip -c | tar -xvf - --directory=$PWD/.fetchd
[[ $(grep 'x-goog-hash: md5' headers.out | sed -z 's/^.*md5=\(.*\)/\1/g' | tr -d '\r' | base64 -d | od -An -vtx1 | tr -d ' \n') == $(awk '{ print $1 }' md5sum.out) ]] && echo "OK - md5sum match" || echo "ERROR - md5sum MISMATCH"
echo "Downloaded snapshot timestamp: $(grep last-modified headers.out | cut -f3- -d' ')"

# Create a systemd service 
cat > /etc/systemd/system/fetch.service <<EOF
[Unit]
Description=FetchAI Validator
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=root
Type=simple
Restart=always
RestartSec=30
ExecStart=/root/go/bin/fetchd start --p2p.seeds 17693da418c15c95d629994a320e2c4f51a8069b@connect-fetchhub.fetch.ai:36456,a575c681c2861fe945f77cb3aba0357da294f1f2@connect-fetchhub.fetch.ai:36457,d7cda986c9f59ab9e05058a803c3d0300d15d8da@connect-fetchhub.fetch.ai:36458


[Install]
WantedBy=default.target
EOF

# Enable and Start the service
systemctl enable fetch
systemctl start fetch
