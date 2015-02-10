#!/bin/sh
while :
do
  sleep 1
  echo "$(date) container 2 stdout"
  echo "$(date) container 2 stderr" 1>&2
done
