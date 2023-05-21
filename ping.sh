#!/bin/bash

# get value from terraform output
DNS_NAME=$(terraform output alb_dns_name | tr -d '"')

curl http://"${DNS_NAME}"
