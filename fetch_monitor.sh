#!/bin/bash

############################
# By ImStaked
############################

# Email Settings
MAIL_SUBJECT="FETCH ALERT"
MAIL_TO="ALERT_MAILBOX_GOES_HERE"

# Node Settings
FETCH_PUBLIC_RPC="https://fetch-rpc.polkachu.com"
FET_NODE="http://127.0.0.1:26657"

function check_fetch
{
    FET_HEIGHT=$(curl -s "$FET_NODE"/status | jq -r .result.sync_info.latest_block_height)
    FET_PUB_HEIGHT=$(curl -s "$FETCH_PUBLIC_RPC"/status | jq -r .result.sync_info.latest_block_height)
    FET_DIFF=$((FET_PUB_HEIGHT - FET_HEIGHT))

    if [ $FET_DIFF -gt 5 ]
    then
        echo FetchAI is $FET_DIFF blocks behind | mail -s $MAIL_SUBJECT -a "From: notify@YOURDOMAIN" $MAIL_TO
    fi
}


check_fetch
