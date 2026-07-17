
module "module_vpc" {
  source = "../../core-modules/module-vpc"

  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
  default_tags = var.default_tags

  vpc_cidr                        = var.vpc_cidr
  private_route_cidrs             = var.private_route_cidrs
  public_route_cidrs              = var.public_route_cidrs
  public_subnets_cidrs            = var.public_subnets_cidrs
  private_subnets_cidrs           = var.private_subnets_cidrs
  public_subnets_available_zones  = var.public_subnets_available_zones
  private_subnets_available_zones = var.private_subnets_available_zones
  public_route_tables             = var.public_route_tables
  private_route_tables            = var.private_route_tables
}


module "module_security_groups" {
  source = "../../core-modules/module-security-groups"

  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
  default_tags = var.default_tags

  app_vpc_id      = module.module_vpc.output_vpc_mod_app_vpc_id
  security_groups = var.security_groups


  depends_on = [
    module.module_vpc
  ]
}


module "module_iam" {
  source = "../../core-modules/module-iam"

  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
  default_tags = var.default_tags

  managed_infra_roles    = var.managed_infra_roles
  managed_infra_policies = var.managed_infra_policies
  managed_infra_users    = var.managed_infra_users


  depends_on = [
    module.module_vpc
  ]
}

module "module_route53" {
  source = "../../core-modules/module-route53"

  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = var.account_id
  default_tags = var.default_tags

  master_domain        = var.master_domain
  route53_zones        = var.route53_zones
  route53_zone_records = var.route53_zone_records
  
  depends_on = [
    module.module_vpc
  ]
}

# module "module_codebuild" {
#   source = "../../core-modules/module-codebuild"

#   environment                   =   var.environment
#   aws_region                    =   var.aws_region
#   account_id                    =   var.account_id
#   default_tags                  =   var.default_tags

#   subnet_ids                    =   [for key, value in module.module_vpc.output_vpc_mod_private_subnets : value.id]
#   vpc_id                        =   module.module_vpc.output_vpc_mod_app_vpc_id
#   codebuild_projects            =   var.iac_core_codebuild_projects


#   depends_on = [
#       module.module_iam , module.module_security_groups , module.module_vpc
#   ]  
# }

# module "module_codepipeline" {
#   source = "../../core-modules/module-codepipeline"

#   environment                   =   var.environment
#   aws_region                    =   var.aws_region
#   account_id                    =   var.account_id
#   default_tags                  =   var.default_tags

#   codepipeline_projects         =   var.iac_core_codepipeline_projects

#   depends_on = [
#       module.module_iam , module.module_security_groups , module.module_vpc, module.module_codebuild,
#       aws_codestarconnections_connection.codepipeline_connections_github
#   ]  
# }


resource "aws_codestarconnections_connection" "codepipeline_connections_github" {
  name          = "github_cs_connections"
  provider_type = "GitHub"
}


## WE NEED TO MOVE THIS TO IT'S OWN MODULE, SINCE IT'S NOT RELATED TO THE VPC, IAM OR SECURITY GROUPS.
resource "aws_route53_zone" "primary" {
  force_destroy = true
  name          = var.master_domain
  tags = merge(var.default_tags, {
    Name = var.master_domain
  })
}


resource "aws_route53_zone" "env_zone" {
  name          = "${var.environment}.${var.master_domain}"
  force_destroy = true
  tags = merge(var.default_tags, {
    Name = "${var.environment}.${var.master_domain}"
  })
}

#for prod records high ttl is recommended since the NS records are not expected to change frequently ( 86400 - 172800 / 1 - 2 days ).
#For dev and test environments, a lower TTL can be used to allow for quicker updates if needed.
resource "aws_route53_record" "env_zone-ns" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${var.environment}.${var.master_domain}"
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.env_zone.name_servers
}
