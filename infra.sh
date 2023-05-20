#!/bin/bash

set -o xtrace # print commands as they are executed

terraform apply --auto-approve

# get value from terraform output
PUBLIC_IP=$(terraform output public_ip | tr -d '"')

curl http://"${PUBLIC_IP}":8080
