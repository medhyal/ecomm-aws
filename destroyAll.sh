#!/bin/bash

cd ~/ecomm-aws

kops delete cluster --name $(terraform output domain-name) --state s3://$(prop s3name) --yes

terraform destroy -auto-approve
