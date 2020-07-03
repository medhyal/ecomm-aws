#!/bin/bash

function prop {
    grep "${1}" ~/ecomm-aws/envprop.properties|cut -d'=' -f2
}

cd ~/ecomm-aws

kops delete cluster --name $(terraform output domain-name) --state s3://$(prop s3name) --yes

terraform destroy -auto-approve
