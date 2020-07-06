#!/bin/bash

function prop {
    grep "${1}" ~/ecomm-aws/envprop.properties|cut -d'=' -f2
}

sed -i "s|__S3_NAME__|$(prop s3name)|g" ~/ecomm-aws/main.tf

echo "Creating AWS Infra..."
cd ~/ecomm-aws
terraform init
terraform plan
terraform apply -auto-approve

sed -i '/rds=/d' ~/ecomm-aws/envprop.properties
sed -i '/ecr=/d' ~/ecomm-aws/envprop.properties

echo "rds=$(terraform output ecomm-db-address)" >> ~/ecomm-aws/envprop.properties
echo "ecr=$(terraform output ecomm-ecr-url)" | cut -d'/' -f 1 >> ~/ecomm-aws/envprop.properties

echo "Initilizing DB..."
mysqlsh admin@$(prop rds) --sql --password=admin123 --file=~/ecomm-aws/ecomm.sql

echo "Complete...."
