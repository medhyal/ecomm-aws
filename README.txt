==========================================================
Ecomm Deployment plan to AWS
==========================================================

1. Get all access from AWS root user:
AmazonRDSFullAccess
IAMFullAccess
AmazonEC2ContainerRegistryFullAccess
IAMUserChangePassword
AmazonRDSDataFullAccess
AmazonECS_FullAccess
AmazonEC2ContainerRegistryPowerUser
AWSAccountUsageReportAccess
AWSAccountActivityAccess
AmazonEC2FullAccess
ElasticLoadBalancingFullAccess
AmazonS3FullAccess
AdministratorAccess
AmazonVPCFullAccess
AmazonRoute53FullAccess

2. Create EC2 instance (Amazon Linux) in AWS default VPC.
3. sudo yum -y update
4. sudo yum -y install git
5. git clone https://github.com/medhyal/ecomm-aws.git
6. cd ~/ecomm-aws
7. chmod 755 *.sh
8. ./ec2_vm_setup.sh
9. . .bashrc
10. aws configure
11. Run below commands

   echo "defaultvpc=vpc-xxxxxxx" >> ~/ecomm-aws/envprop.properties
   echo "default-vpcip=xxx.x.x.x/16" >> ~/ecomm-aws/envprop.properties
   echo "defaultroute=rtb-xxxxxxx" >> ~/ecomm-aws/envprop.properties
   echo "s3name=xxxxxxxxx" >> ~/ecomm-aws/envprop.properties
   
7. ./initAWSInfra.sh
8. ./deployKubernetes.sh
   Check if cluster is up:
   kops --name dev.ecomm.com --state s3://k8s.msr.ecomm.com validate cluster
   
9. ./deployKafka.sh
10. ./deployApps.sh


==========================================================
Delete All Cluster and AWS Infra
==========================================================
~/ecomm-aws/destroyAll.sh


==========================================================
Test Ecomm Application
==========================================================
Run in Setup VM -

curl http://<ELB IP/Domain Name>/api/category/88

curl http://<ELB IP/Domain Name>/api//category/products?catId=88


==========================================================
Check Kafka
==========================================================
1. Login to kafka pod
kubectl exec -it kafka-xxxxx-bkgfv -- /bin/bash

2. Run
./bin/kafka-topics.sh --list --bootstrap-server kafka:9092

3. To check kafka messages for topic
./bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic xxxxxxxxx.com.ecomm.sku --from-beginning


==========================================================
Connect to MySQL RDS
==========================================================
Run - "mysqlsh"

Run below commands in prompt:

\connect admin@xxxxxxxx.rds.amazonaws.com:3306
\sql use ecomm;
\quit


==========================================================
SSH to nodes
==========================================================
ssh -i ~/.ssh/id-rsa admin@172.11.0.111


==========================================================
Check application logs in pods
==========================================================
1. kubectl logs -l app=ecomm-catalog
 OR
1. kubectl get pods -o wide
2. kubectl logs ecomm-catalog-xxxxxxx-xxxxxx

