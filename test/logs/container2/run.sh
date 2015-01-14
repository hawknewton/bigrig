#!/bin/sh
while :
do
  sleep 5
  echo "$(date) container 2 stdout"
  echo "$(date) container 2 stderr" 1>&2
done
