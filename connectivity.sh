#!/bin/bash

# This prints whether the current machine has internet connectivity, and DNS

check=$(ping -c 3 www.google.com | grep ttl)

if [ "$check" != "" ]; then
  echo Connected
else
  echo Not connected
fi
