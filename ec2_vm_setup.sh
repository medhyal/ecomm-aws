#!/bin/bash

echo "Installing vim..."
sudo yum -y install vim || echo "VIM installed!!"

echo "Installing unzip..."
sudo yum -y install unzip || echo "unzip installed!!"

echo "Installing bind-utils..."
sudo yum -y install bind-utils || echo "bind-utils installed!!"

echo "Installing jq..."
sudo yum -y install jq || echo "jq installed!!"

echo "Installing kubectl..."
cd ~/
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sleep 3
chmod 755 kubectl
sudo mv ./kubectl /usr/local/bin/
echo "kubectl installed!!"

echo "Installing kops..."
cd ~/
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
sleep 3
chmod 755 kops-linux-amd64
sudo mv ./kops-linux-amd64 /usr/local/bin/kops
echo "kops installed!!"

echo "Installing aws cli..."
cd ~/
curl -LO "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
sleep 3
unzip awscli*.zip
sudo ./aws/install
echo "aws installed!!"

echo "Installing terraform..."
cd ~/
curl -LO https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
sleep 3
unzip terraform*.zip
sudo mv ./terraform /usr/local/bin/
echo "terraform installed!!"

echo "Installing OpenJDK..."
sudo yum -y install java-1.8.0-openjdk-devel
echo "OpenJDK installed!!"

echo "Installing Maven..."
cd ~/
curl -LO https://mirror.olnevhost.net/pub/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
sleep 3
tar xvf apache-maven-3.6.3-bin.tar.gz
echo "export PATH=\$PATH:/$HOME/apache-maven-3.6.3/bin" >> ~/.bashrc
echo "Maven installed!!"

echo "Installing Docker..."
sudo yum -y install docker
sudo service docker start
sudo usermod -aG docker ec2-user
echo "Docker installed!!"

echo "Installing Mysql client..."
cd ~/
curl -LO https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit.tar.gz
sleep 3
tar zxvf mysql-shell-8.0.20-linux-glibc2.12-x86-64bit.tar.gz
echo "export PATH=\$PATH:/$HOME/mysql-shell-8.0.20-linux-glibc2.12-x86-64bit/bin" >> ~/.bashrc
echo "Mysql client installed!!"

echo "Creating key pair..."
cd ~/
mkdir .ssh
ssh-keygen -q -t rsa -N '' -f .ssh/id_rsa|echo -e 'y\n' > /dev/null

echo "Loading bashrc..."
. ~/.bashrc

echo "All Installations complete!!"

