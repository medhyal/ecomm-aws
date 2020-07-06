#############################################################################################################
### Provider and AZ
#############################################################################################################
provider "aws" { region="us-east-1"}
#############################################################################################################


#############################################################################################################
### Variables declarations
#############################################################################################################

variable "vpc_cidr_block" {default = "172.50.0.0/16"}
variable "project_name" { default = "ecomm-dev"}
variable "domain" { default = "ecomm.com"}
variable "default-vpc" { default="__DEF_VPC__" }
variable "default-vpc-ip" { default="__DEF_VPC_IP__" }
variable "default-vpc-route_table_id" { default="__DEF_VPC_IP_ROUTE_ID__" }
variable "domain-name" { default="dev.ecomm.com" }

variable "networks-private" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    n0 = {
      cidr_block        = "172.50.0.0/20"
      availability_zone = "us-east-1a"
	  name="ecomm-dev-subnet-pvt-east-1a"
    }
    n1 = {
      cidr_block        = "172.50.32.0/20"
      availability_zone = "us-east-1b"
	   name="ecomm-dev-subnet-pvt-east-1b"
    }
  }
}

variable "networks-public" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    n0 = {
      cidr_block        = "172.50.48.0/20"
      availability_zone = "us-east-1a"
	  name="ecomm-dev-subnet-pub-east-1a"
    }
    n1 = {
      cidr_block        = "172.50.80.0/20"
      availability_zone = "us-east-1b"
	  name="ecomm-dev-subnet-pub-east-1b"
    }
  }
}

#############################################################################################################
### Resources
#############################################################################################################

########## S3 BUCKET ##########
resource "aws_s3_bucket" "s3b" {
  bucket = "__S3_NAME__"
  acl    = "private"
  tags = {
    Name        = "${var.project_name}-Bucket"
    Environment = var.project_name
  }
}

########## VPC ##########
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

########## VPC PEER ##########
resource "aws_vpc_peering_connection" "vpc-peer" {
  peer_vpc_id   = aws_vpc.vpc.id
  vpc_id        = var.default-vpc
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  tags = {
    Name = "${var.project_name}-vpc-peer"
  }
}

########## ROUTE 53 ##########
resource "aws_route53_zone" "domain" {
  name = var.domain-name
  vpc {
    vpc_id = var.default-vpc
  }
}

########## INTERNET GATEWAY  ##########
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

########## PUBLIC SUBNETS  ##########
resource "aws_subnet" "public-subnets" {
  count = length(var.networks-public)
  availability_zone = var.networks-public["n${count.index}"].availability_zone
  cidr_block        = var.networks-public["n${count.index}"].cidr_block
  vpc_id            = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-subnet-pub"
  }
}

########## NAT GATEWAY  ##########
resource "aws_eip" "nat-eip" {
  vpc = true
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnets.*.id[0]
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

########## PRIVATE SUBNETS  ##########
resource "aws_subnet" "private-subnets" {
  count = length(var.networks-private)
  availability_zone = var.networks-private["n${count.index}"].availability_zone
  cidr_block        = var.networks-private["n${count.index}"].cidr_block
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Name = "${var.project_name}-subnet-pvt"
  }
}

########## SUBNETS ROUTES ##########
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "${var.project_name}-pub-route"
  }
}

resource "aws_route_table_association" "route_table_association" {
  count = length(var.networks-public)
  subnet_id     = aws_subnet.public-subnets.*.id[count.index]
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table" "route_table_pvt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "${var.project_name}-pvt-route"
  }
}

resource "aws_route_table_association" "route_table_pvt_association" {
  count = length(var.networks-private)
  subnet_id     = aws_subnet.private-subnets.*.id[count.index]
  route_table_id = aws_route_table.route_table_pvt.id
}

resource "aws_route" "vpc_pvt_to_def_vpc_route" {
  route_table_id            = aws_route_table.route_table_pvt.id
  destination_cidr_block    = var.default-vpc-ip
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc-peer.id
}

resource "aws_route" "vpc_pub_to_def_vpc_route" {
  route_table_id            = aws_route_table.route_table.id
  destination_cidr_block    = var.default-vpc-ip
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc-peer.id
}

resource "aws_route" "def_vpc_to_vpc_route" {
  route_table_id            = var.default-vpc-route_table_id
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc-peer.id
}

################### Security Groups ###############
resource "aws_security_group" "deb-connector-sg" {
  name        = "deb-connector-sg"
  description = "Allow 30001 port"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "30001 port"
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "ecomm-catalog-deb-sg"
  }
}

resource "aws_security_group" "mysql-rds-sg" {
  name        = "mysql-rds-sg"
  description = "Allow 3306 port"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "3306 port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "ecomm-mysql-rds-sg"
  }
}


################### ECR ############################
resource "aws_ecr_repository" "ecomm-catalog-ecr" {
  name                 = "ecomm-catalog"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  tags = {
    Name        = "ecomm-catalog-ecr"
  }
}

resource "aws_ecr_repository" "ecomm-pricing-ecr" {
  name                 = "ecomm-pricing"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  tags = {
    Name        = "ecomm-pricing-ecr"
  }
}


################### RDS ########################
resource "aws_db_parameter_group" "ecomm-rds" {
  family = "mysql8.0"
  name = "ecomm-rds"

  parameter {
    name = "binlog_format"
    value = "ROW"
  }
}

resource "aws_db_instance" "ecomm-db" {
  availability_zone    = "us-east-1a"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.17"
  instance_class       = "db.t2.micro"
  name                 = "ecommdb"
  username             = "admin"
  password             = "admin123"
  port                 = 3306
  publicly_accessible  = false
  parameter_group_name = "ecomm-rds"
  option_group_name    = "default:mysql-8-0"
  skip_final_snapshot  = true
  backup_retention_period = 1
  vpc_security_group_ids = [aws_security_group.mysql-rds-sg.id]
  depends_on = [aws_db_parameter_group.ecomm-rds]
}


#############################################################################################################
### Output
#############################################################################################################

output "domain-name" {
  value = var.domain-name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = var.vpc_cidr_block
}

output "subnet_ids_pvt" {
  value = aws_subnet.private-subnets.*.id
}

output "subnet_ids_pub" {
  value = aws_subnet.public-subnets.*.id
}

output "networks-private" {
  value = var.networks-private
}

output "networks-public" {
  value = var.networks-public
}

output "s3bucket" {
  value = aws_s3_bucket.s3b.bucket
}

output "s3bucket-str" {
  value = "s3://${aws_s3_bucket.s3b.bucket}"
}

output "ecomm-db-address" {
  value = aws_db_instance.ecomm-db.address
}

output "ecomm-ecr-url" {
  value = aws_ecr_repository.ecomm-catalog-ecr.repository_url
}

output "deb-connector-sg-id" {
  value = aws_security_group.deb-connector-sg.id
}
