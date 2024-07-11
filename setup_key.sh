#!/bin/bash
# setup zip key
echo -n "$1" | base64 > ~/.key.txt
ZIPKEY=$(cat ~/.key.txt)
echo "zip key: $ZIPKEY"
