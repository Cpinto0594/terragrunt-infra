locals {
    # Load account, region and environment variables 
    account_vars            = read_terragrunt_config(find_in_parent_folders("account.hcl"))
    region_vars             = read_terragrunt_config(find_in_parent_folders("region.hcl"))
    namespace_vars          = read_terragrunt_config(find_in_parent_folders("namespace.hcl"))

    providers               = local.account_vars.locals.providers
    aws_region              = local.region_vars.locals.aws_region
    environment             = local.namespace_vars.locals.environment
    state_bucket            = local.namespace_vars.locals.state_bucket
    dynamodb_table          = local.namespace_vars.locals.dynamodb_table

    aws_account_id          = local.account_vars.locals.account_id
    aws_role_name           = local.account_vars.locals.tg_role_name
}

# Generate an dynamic AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${local.providers.aws.version}"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "${local.providers.kubernetes.version}"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "${local.providers.helm.version}"
    }
    
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "${local.providers.kubectl.version}"
    }

    time = {
      source = "hashicorp/time"
      version = "${local.providers.time.version}"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "${local.providers.random.version}"
    }

    tls = {
      source = "hashicorp/tls"
      version = "${local.providers.tls.version}"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "${local.providers.cloudflare.version}"
    }
  }
}
provider "aws" {
  region = "${local.aws_region}"
  assume_role {
    role_arn    =  "arn:aws:iam::${local.account_vars.locals.account_id}:role/${local.account_vars.locals.tg_role_name}"
  }
}

provider "cloudflare" {
  api_token = ""
}
EOF
}

#iam_role = "arn:aws:iam::${local.aws_account_id}:role/${local.aws_role_name}"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "${local.account_vars.locals.account_id}-${local.state_bucket}"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    assume_role = {
      role_arn     = "arn:aws:iam::${local.account_vars.locals.account_id}:role/${local.account_vars.locals.tg_role_name}"
      session_name = "${local.account_vars.locals.tg_role_name}_session"
    }

    region  = "${local.aws_region}"
    encrypt = true
    #dynamodb_table = "${local.dynamodb_table}"
    use_lockfile = true
    s3_bucket_tags = {
      terraform = "true"
    }

    dynamodb_table_tags = {
      terraform = "true"
    }
  }
}


# Combine all account, region and environment variables as Terragrunt input parameters.
# The input parameters can be used in Terraform configurations as Terraform variables.  
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.namespace_vars.locals ,
  { default_tags = merge( local.namespace_vars.locals.namespace_tags, local.region_vars.locals.region_tags, {terraform: true} ) }

)
