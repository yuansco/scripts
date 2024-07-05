#!/bin/bash
echo -n "$1" | base64 > ~/.key.txt
ZIPKEY=$(cat ~/.key.txt)
echo "zip key: $ZIPKEY"
