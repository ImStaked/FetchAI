#!/bin/bash

# Settings
MONIKER="YOURNAME"
CHAIN_ID="fetchhub-4"
VERSION="v0.10.6"

cd ~

# Update the system and install prerequesits
sudo apt update && sudo apt upgrade -y && sudo apt autoremove 
sudo apt install make gcc zip unzip pigz git -y

# Install go NOT WORKING
wget https://raw.githubusercontent.com/ImStaked/FetchAI/main/installer/go_installer.sh
chmod +x go_installer.sh
/home/fetch/go_installer.sh
source /home/fetch/.bashrc

# Build the binary from source
git clone https://github.com/fetchai/fetchd.git && cd fetchd 
git checkout $VERSION
make build
make install
sudo ln -s ~/go/bin/fetchd /usr/local/bin/fetchd

# Init Node and get genesis
fetchd init $MONIKER --chain-id $CHAIN_ID
curl https://raw.githubusercontent.com/fetchai/genesis-fetchhub/fetchhub-4/fetchhub-4/data/genesis_migrated_5300200.json --output ~/.fetchd/config/genesis.json

# Create a systemd service 
sudo echo "
[Unit]
Description=FetchAI Validator
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=fetch
Type=simple
Restart=always
RestartSec=30
ExecStart=/home/fetch/go/bin/fetchd start --p2p.seeds 17693da418c15c95d629994a320e2c4f51a8069b@connect-fetchhub.fetch.ai:36456,a575c681c2861fe945f77cb3aba0357da294f1f2@connect-fetchhub.fetch.ai:36457,d7cda986c9f59ab9e05058a803c3d0300d15d8da@connect-fetchhub.fetch.ai:36458


[Install]
WantedBy=default.target
" > /etc/systemd/system/fetchd.service 

# Get latest snapshot
echo "Latest available snapshot timestamp : $(curl -s -I  https://storage.googleapis.com/fetch-ai-mainnet-snapshots/fetchhub-4-pruned.tgz | grep last-modified | cut -f3- -d' ')"
curl -v https://storage.googleapis.com/fetch-ai-mainnet-snapshots/fetchhub-4-pruned.tgz -o- 2>headers.out | tee >(md5sum > md5sum.out) | gunzip -c | tar -xvf - --directory=$PWD/.fetchd
[[ $(grep 'x-goog-hash: md5' headers.out | sed -z 's/^.*md5=\(.*\)/\1/g' | tr -d '\r' | base64 -d | od -An -vtx1 | tr -d ' \n') == $(awk '{ print $1 }' md5sum.out) ]] && echo "OK - md5sum match" || echo "ERROR - md5sum MISMATCH"
echo "Downloaded snapshot timestamp: $(grep last-modified headers.out | cut -f3- -d' ')"


# Enable and Start the service
systemctl enable fetchd
systemctl start fetchd
