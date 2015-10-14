#!/bin/bash

# robust_networking
#
# Checks for network availability, if it can connect it will
#   Tell <REDACTED> (Google Drive) it's external and internal ip addresses
#   If the roundtrip time to <REDACTED> isn't too high, start the VPN
#   Provide <REDACTED> a reverse tunnel for sshfs
#
# This provides a flexible, self repairing monitor for network status and connectivity

SLEEP_TIME=60
SLEEP_MAX=900 # 15 minutes
VPN_START_TIME=15

LOST_CONN="yes"
TIME_MAX=200
LOG="/var/log/check_network.log"

SERVER_ADDR="<REDACTED>"
VPN_ADDR="10.8.0.1"

SSH_IDENTITY="/home/pi/.ssh/<REDACTED>"
SSH_PARAMS="-p 9720 -i $SSH_IDENTITY <REDACTED>@$VPN_ADDR"
RSSH_PARAMS="-N -f -C -g -R 9790:localhost:<REDACTED>"
TUNNEL_DIED="no"

SCP_PARAMS="-P 9720 -i $SSH_IDENTITY "
SCP_FILE_LOC="<REDACTED>@"$SERVER_ADDR":GoogleDrive/Personal/"

FILE_NAME="$(uname -n)IPs.txt"
FILE_LOC=/tmp/
FILE="$FILE_LOC""$FILE_NAME"

VPN_FILE="/home/<REDACTED>/Documents/Arch.ovpn"
VPN_PID_FILE="/tmp/.openvpnpid"
VPN_TOO_LONG="no"

SEND_IPS_MSG="Sending external and internal IP address to $SERVER_ADDR"
DISCOVER_SERVER_TIME_MSG="Testing the roundtrip time to $SERVER_ADDR"
DISCOVER_VPN_TIME_MSG="Testing connection to $VPN_ADDR"
VPN_RESTART_MSG="Roundtrip time to $SERVER_ADDR is acceptable, starting the VPN"
VPN_TOO_LONG_MSG="Roundtrip time to $SERVER_ADDR is unacceptable, stopping the VPN"
VPN_SURVIVED_MSG="Roundtrip time to $SERVER_ADDR is acceptable, VPN is already running"
VPN_DIED_MSG="VPN daemon died during startup"
VPN_CONN_SUCCESS_MSG="Connection to VPN succeded, sending new IPs"
VPN_CONN_FAIL_MSG="Connection to VPN failed, stopping the VPN"
RSSH_INTACT_MSG="Reverse SSH tunnel to $VPN_ADDR is intact"
RSSH_START_MSG="Starting reverse SSH tunnel to $VPN_ADDR"

function recover_networking(){

  # Check for a broken VPN blocking us
  if [[ $(ip addr | grep tun ) != "" ]]; then
    stop_services
  fi
}

function stop_services(){
  # Stop the VPN
  if [[ $(ps aux | grep openvpn | grep -v grep) != "" ]]; then
    killall openvpn
    sleep 2
  fi

  # Stop the reverse ssh tunnel
  if [[ $(ssh $SSH_PARAMS 'lsof -i -P | grep -o 9790') != "9790" ]]; then
    kill $(ps aux | grep 'ssh -N' | grep -v grep | awk '{print $2}')
  fi
}

function reverse_ssh() {

  # If the tunnel isn't already running, start it
  if [[ $(ssh $SSH_PARAMS 'lsof -i -P | grep -o 9790') != "9790" ]]; then
    TUNNEL_DIED="yes"

    # Kill any defunct reverse ssh sessions
    if [[ $(ps aux | grep -v grep | grep -o 'ssh -N') == 'ssh -N' ]]; then
      kill $(ps aux | grep 'ssh -N' | grep -v grep | awk '{print $2}')
    fi

    echo "[$(date)] "$RSSH_START_MSG >> $LOG
    ssh $RSSH_PARAMS $SSH_PARAMS >> $LOG

  # The tunnel is already running
  else
    TUNNEL_DIED="no"
    echo "[$(date)] "$RSSH_INTACT_MSG >> $LOG
  fi
}

function send_ips(){
  EXTERNAL_IP=$(curl icanhazip.com)

  echo "[$(date)] "$SEND_IPS_MSG >> $LOG
  touch $FILE
  curl -sSo $FILE icanhazip.com 

  echo >> $FILE
  ip addr >> $FILE
  echo >> $FILE
  echo "Valid as of "$(date) >> $FILE

  scp $SCP_PARAMS $FILE $SCP_FILE_LOC >> $LOG 2>> $LOG
  rm $FILE
}

function connect_vpn(){
  echo "[$(date)] "$DISCOVER_SERVER_TIME_MSG >> $LOG
  SERVER_TIME=$(ping -c 3 $SERVER_ADDR | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

  # Time is acceptable, start the VPN
  if echo $SERVER_TIME $TIME_MAX | awk '{exit !( $1 < $2)}'; then 
    VPN_TOO_LONG="no"
    echo "[$(date)] "$DISCOVER_VPN_TIME_MSG >> $LOG

    # VPN didn't survive the connection loss, restart it and update IPs
    if [[ $(ping -c 3 $VPN_ADDR | grep ttl) == "" ]]; then
      echo "[$(date)] "$VPN_RESTART_MSG >> $LOG

      stop_services
      openvpn --config $VPN_FILE --daemon --writepid $VPN_PID_FILE
      sleep $VPN_START_TIME

      # Check if VPN daemon survived startup
      if [[ $(ps aux | grep $(cat $VPN_PID_FILE) | grep -v grep) == "" ]]; then
        echo "[$(date)] "$VPN_DIED_MSG >> $LOG

      # VPN connection failed, kill it and try again next time
      elif [[ $(ping -c 3 $VPN_ADDR | grep ttl) == "" ]]; then
        echo "[$(date)] "$VPN_CONN_FAIL_MSG >> $LOG
        stop_services

      # VPN connection succeed, send new IPs 
      else
        echo "[$(date)] "$VPN_CONN_SUCCESS_MSG >> $LOG
        send_ips
      fi

    # VPN connection survived
    else
      echo "[$(date)] "$VPN_SURVIVED_MSG >> $LOG
    fi

  # Time is unacceptable, kill the VPN
  else
    VPN_TOO_LONG="yes"
    echo "[$(date)] "$TIME_TOO_LONG_MSG >> $LOG
    stop_services
  fi
}

function main(){
  echo "[$(date)] ""Starting arch_brain.sh" >> $LOG

  while [[ 1 ]]; do

    # Disconnected
    if [[ $(ping -c 3 $SERVER_ADDR | grep ttl) == "" ]]; then
      LOST_CONN="yes"
      SLEEP_TIME=60
      echo "[$(date)] ""Not connected" >> $LOG

      recover_networking

    # Connected
    else
      # Sleep time exponential backoff
      if echo $SLEEP_TIME $SLEEP_MAX | awk '{exit !( $1 < $2)}'; then 
        if [[ "$TUNNEL_DIED" == "no" ]]; then
          SLEEP_TIME=$(expr $SLEEP_TIME + $SLEEP_TIME)
        fi
      fi

      echo "[$(date)] ""Connected" >> $LOG

      # Had lost connection or got it for the first time, send info
      if [[ "$LOST_CONN" == "yes" ]]; then
        echo "[$(date)] ""Regained connection" >> $LOG
        LOST_CONN="no"
        send_ips
      fi

      connect_vpn
      reverse_ssh
    fi

    sleep $SLEEP_TIME
  done
}

main & 
