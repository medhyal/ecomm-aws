==========================================================
Ecomm Deployment plan for AWS
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

2. Create EC2 instance using "Amazon Linux 2 AMI (HVM), SSD Volume Type - ami-09d95fab7fff3776c" in AWS default VPC.
3. sudo yum -y update
4. sudo yum -y install git
5. git clone https://github.com/medhyal/ecomm-aws.git
6. cd ~/ecomm-aws
7. chmod 755 *.sh
8. ./ec2_vm_setup.sh
9. Logout and login again.
10. . .bashrc
11. aws configure
12. Specify some name for s3 below (eg: my.s3.store.com) -

   echo "s3name=k8s.xxx.xxx.com" >> ~/ecomm-aws/envprop.properties
   
13. cd ~/ecomm-aws
14. ./initAWSInfra.sh
15. ./deployKubernetes.sh
   Check if cluster is up:
   cd ~/ecomm-aws/ && kops --name $(terraform output domain-name) --state $(terraform output s3bucket-str) validate cluster
   
16. ./deployKafka.sh
17. ./deployApps.sh


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
