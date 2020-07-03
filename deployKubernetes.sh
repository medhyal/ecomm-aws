#!/bin/bash

function prop {
    grep "${1}" ~/ecomm-aws/envprop.properties|cut -d'=' -f2
}

cd ~/ecomm-aws

kops create cluster \
--cloud aws \
--state $(terraform output s3bucket-str) \
--node-count 5 \
--master-count 1 \
--master-size t2.large \
--node-size t2.micro \
--zones us-east-1a,us-east-1b \
--name $(terraform output domain-name) \
--dns private \
--network-cidr $(terraform output vpc_cidr) \
--topology private \
--networking calico \
--api-loadbalancer-type internal \
--vpc $(terraform output vpc_id) \
--subnets $(terraform output -json subnet_ids_pvt | jq -r 'join(",")') \
--utility-subnets $(terraform output -json subnet_ids_pub | jq -r 'join(",")') \
--node-security-groups $(terraform output deb-connector-sg-id)

echo "Calling kops update ..."
kops update cluster --name $(terraform output domain-name) --state s3://$(prop s3name) --yes

