#!/bin/bash

############################
# By ImStaked
############################

#######################
# EMAIL SETTINGS
#######################
NOTIFY_EMAIL='<NOT_USED_YET>'

#######################
# DISCORD
#######################
discord_url="<DISCORD_WEBHOOK_URL>"

#######################
# FetchAI
#######################
FETCH_PUBLIC_RPC="https://fetch-rpc.polkachu.com/status"
FET_NODE="http://<IP:PORT>/status"

#######################
# Osmosis Nodes
#######################
OSMO_RPC_URL="https://osmosis-rpc.polkachu.com/status"
OSMO_NODE_URL="http://<IP:PORT>/status"

function check_fetch
{ 
    FET_HEIGHT=$(curl -s "$FET_NODE" | jq -r .result.sync_info.latest_block_height | tr -dc '0-9')
    FET_PUB_HEIGHT=$(curl -s "$FETCH_PUBLIC_RPC" | jq -r .result.sync_info.latest_block_height)
    FET_catchup_status=$(curl -s $FET_NODE | jq .result.sync_info.catching_up)
    FET_DIFF=$((FET_HEIGHT-FET_PUB_HEIGHT))
    if [ -z "$FET_HEIGHT" ]
    then
       curl -H "Content-Type: application/json" -X POST -d '{"content":"'"FETCH node: Did not return a block height number"'"}'  $discord_url 
    fi
    if [ "$FET_catchup_status" = true ]
    then
#	    echo FetchAI is Catching up
        curl -H "Content-Type: application/json" -X POST -d '{"content":"'"FETCH node is : Catching UP"'"}'  $discord_url
    else
        if [ $FET_DIFF -gt 1 ]
        then
#	        echo Fetch RPC server is : $FET_DIFF : blocks behind
    	    curl -H "Content-Type: application/json" -X POST -d '{"content":"'"FETCH RPC node is : ${FET_DIFF} blocks behind"'"}'  $discord_url
        else
    	    echo FetchAI is healthy
        fi
    fi
}

function check_osmosis
{
# Osmosis Health Check
    osmo_latest_height=$(curl -s $OSMO_NODE_URL | jq -r .result.sync_info.latest_block_height)
    osmo_external_height=$(curl -s $OSMO_RPC_URL | jq -r .result.sync_info.latest_block_height)
    osmo_diff=$((osmo_external_height - osmo_latest_height))
    osmosis_catchup_status=$(curl -s $OSMO_NODE_URL | jq .result.sync_info.catching_up)

    if [ -z "$osmo_latest_height" ]
    then
        curl -H "Content-Type: application/json" -X POST -d '{"content":"'"OSMOSIS node: Did not return a block height number"'"}'  $discord_url 
    fi

    if [ "$osmosis_catchup_status" = true ] 
    then
        #echo Osmosis is Catching up
        curl -H "Content-Type: application/json" -X POST -d '{"content":"'"OSMOSIS RPC node is : Catching UP"'"}'  $discord_url
        else
            if [ $osmo_diff -gt 3 ]
            then
                #echo -e "Osmosis node is "$osmo_diff" block behind \n"
                curl -H "Content-Type: application/json" -X POST -d '{"content":"'"OSMOSIS RPC node is : ${osmo_diff} blocks behind"'"}'  $discord_url
            else
                echo Osmosis is Healthy
            fi
    fi
}

check_fetch
check_osmosis
