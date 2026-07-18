#!/bin/sh
while ! CREDS=$(aws eks get-token --cluster-name $1); do
  sleep 1
done
echo ${CREDS}