#!/bin/bash

function prop {
    grep "${1}" ~/ecomm-aws/envprop.properties|cut -d'=' -f2
}

cd ~/

rm -rf ~/ecomm-pricing
git clone https://github.com/medhyal/ecomm-pricing.git

rm -rf ~/ecomm-catalog
git clone https://github.com/medhyal/ecomm-catalog.git

sed -i "s/__ECR_URL__/$(prop ecr)/g" ~/ecomm-pricing/deployment.yaml
sed -i "s/__RDS_URL__/$(prop rds)/g" ~/ecomm-pricing/src/main/resources/application.properties
sed -i "s/__ECR_URL__/$(prop ecr)/g" ~/ecomm-catalog/deployment.yaml
sed -i "s/__RDS_URL__/$(prop rds)/g" ~/ecomm-catalog/src/main/resources/application.properties

echo "Building ecomm-pricing.."

cd ~/ecomm-pricing

mvn clean package

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(prop ecr)/ecomm-pricing

docker build -t ecomm-pricing .

docker tag ecomm-pricing:latest $(prop ecr)/ecomm-pricing:latest

docker push $(prop ecr)/ecomm-pricing:latest

echo "Building ecomm-catalog..."

cd ~/ecomm-catalog

mvn clean package

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(prop ecr)/ecomm-catalog

docker build -t ecomm-catalog .

docker tag ecomm-catalog:latest $(prop ecr)/ecomm-catalog:latest

docker push $(prop ecr)/ecomm-catalog:latest

echo "Deploying to Kubernetes..."

kubectl apply -f ~/ecomm-pricing/deployment.yaml
sleep 30
kubectl apply -f ~/ecomm-catalog/deployment.yaml
