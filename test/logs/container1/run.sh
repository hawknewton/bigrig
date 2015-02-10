#!/bin/sh
while :
do
  echo "$(date) container 1 stdout"
  echo "$(date) container 1 stderr" 1>&2
  sleep 1
done
