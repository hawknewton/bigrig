#!/bin/sh
while :
do
  sleep 5
  echo "$(date) container 1 stdout"
  echo "$(date) container 1 stderr" 1>&2
done