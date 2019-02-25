#!/bin/bash

echo "Install terrform"

echo "Run terraform"
cd terraform
terraform init
terraform plan -out plan
terraform apply plan

echo "Congratulations your app is deployed and available at:"
echo "Give it about a minute, then ..."
echo
echo "Visit https://$(terraform output lb_address)"
