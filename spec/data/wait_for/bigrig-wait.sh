#!/bin/sh

BEFORE=$(date +%s)
sleep 2
echo $(($(date +%s) - $BEFORE)) > /tmp/result.txt
