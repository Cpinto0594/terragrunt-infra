
module "module_vpc" {
  source = "../../core-modules/module-vpc"
  
  environment = var.environment
  aws_region = var.aws_region
  account_id = var.account_id
  default_tags = var.default_tags

  vpc_cidr = var.vpc_cidr
  private_route_cidrs =  var.private_route_cidrs
  public_route_cidrs =  var.public_route_cidrs
  public_subnets_cidrs =  var.public_subnets_cidrs
  private_subnets_cidrs =  var.private_subnets_cidrs
  public_subnets_available_zones =  var.public_subnets_available_zones
  private_subnets_available_zones =  var.private_subnets_available_zones
  public_route_tables = var.public_route_tables
  private_route_tables = var.private_route_tables
}


module "module_security_groups" {
  source = "../../core-modules/module-security-groups"

  environment         = var.environment
  aws_region          = var.aws_region
  account_id          = var.account_id
  default_tags        = var.default_tags

  app_vpc_id          = module.module_vpc.output_vpc_mod_app_vpc_id
  security_groups     = var.security_groups

    
  depends_on = [
      module.module_vpc
  ] 
}


module "module_iam" {
  source = "../../core-modules/module-iam"

  environment                   = var.environment
  aws_region                    = var.aws_region
  account_id                    = var.account_id
  default_tags                  = var.default_tags

  managed_infra_roles           = var.managed_infra_roles
  managed_infra_policies        = var.managed_infra_policies

    
  depends_on = [
      module.module_vpc
  ] 
}

module "module_codebuild" {
  source = "../../core-modules/module-codebuild"

  environment                   =   var.environment
  aws_region                    =   var.aws_region
  account_id                    =   var.account_id
  default_tags                  =   var.default_tags

  subnet_ids                    =   [for key, value in module.module_vpc.output_vpc_mod_private_subnets : value.id]
  vpc_id                        =   module.module_vpc.output_vpc_mod_app_vpc_id
  codebuild_projects            =   var.iac_core_codebuild_projects

  
  depends_on = [
      module.module_iam , module.module_security_groups , module.module_vpc
  ]  
}

module "module_codepipeline" {
  source = "../../core-modules/module-codepipeline"

  environment                   =   var.environment
  aws_region                    =   var.aws_region
  account_id                    =   var.account_id
  default_tags                  =   var.default_tags
  
  codepipeline_projects         =   var.iac_core_codepipeline_projects

  depends_on = [
      module.module_iam , module.module_security_groups , module.module_vpc, module.module_codebuild,
      aws_codestarconnections_connection.codepipeline_conections
  ]  
}

resource "aws_codestarconnections_connection" "codepipeline_conections" {
  name          = "bitbucket_cs_conections"
  provider_type = "Bitbucket"
}

# resource "aws_route53_zone" "primary" {
#   name = var.master_domain
#      tags = merge( var.default_tags , {
#         Name = var.master_domain
#     })
# }


# resource "aws_route53_zone" "env_zone" {
#   name = "${var.environment}.${var.master_domain}"
#      tags = merge( var.default_tags , {
#         Name = var.master_domain
#     })
# }