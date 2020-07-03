#!/bin/bash

function prop {
    grep "${1}" ~/ecomm-aws/envprop.properties|cut -d'=' -f2
}

cd ~/ecomm-kafka

echo "Deploying Zookeeper..."
kubectl apply -f zk_deployment.yaml
sleep 60
echo "Deploying Kafka..."
kubectl apply -f kafka_deployment.yaml
sleep 60
echo "Deploying Debezium Connector..."
kubectl apply -f deb_deployment.yaml
sleep 60

echo "Creating Kafka topic..."

kafkanode=`kubectl get pods | grep kafka | cut -d' ' -f 1`
kubectl exec $kafkanode -- ./bin/kafka-topics.sh --zookeeper zookeeper:2181 --topic ecomm --create --partitions 1 --replication-factor 1

echo "Creating Connector App..."
sed -i "s/__RDS_URL__/$(prop rds)/g" ~/ecomm-kafka/config.json

ipaddrpod=`kubectl get pods -o wide | grep ecomm-debezium-source | awk '{print $7}'`
ipaddr=`kubectl get nodes -o wide | grep  $ipaddrpod | awk '{print $6}'`

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json"  -d @config.json http://$ipaddr:30001/connectors/
