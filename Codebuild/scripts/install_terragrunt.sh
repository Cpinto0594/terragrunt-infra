#!/bin/bash
echo Installing Terraform and Terragrunt...

TF_VERSION=1.7.4
TG_VERSION=v0.55.13


yum install -y -q -e 0 yum-utils unzip
curl -L "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -o terraform_${TF_VERSION}_linux_amd64.zip
unzip terraform_${TF_VERSION}_linux_amd64.zip
chmod +x terraform
mv terraform /bin

curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64" -o terragrunt
chmod +x terragrunt
mv terragrunt /bin
