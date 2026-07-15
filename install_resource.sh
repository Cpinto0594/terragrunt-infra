#!/bin/bash
echo Installing Terraform and Terragrunt...

TF_VERSION=1.15.8
TG_VERSION=v1.1.1


echo Installing JQ ...
sudo apt-get install jq -y

echo Installing UNZIP ...
sudo apt install  unzip -y

echo Downloading Terraform...
curl -L "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -o terraform_${TF_VERSION}_linux_amd64.zip
unzip terraform_${TF_VERSION}_linux_amd64.zip
chmod +x terraform
sudo mv terraform /bin

echo Downloading Terragrunt...
curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64" -o terragrunt
chmod +x terragrunt
sudo mv terragrunt /bin

rm terraform_${TF_VERSION}_linux_amd64.zip

echo Installing AWS Cli ...
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
sudo ./aws/install

rm -r ./aws
rm ./awscliv2.zip