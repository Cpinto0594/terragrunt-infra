
locals {
  account_vars      = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars       = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  terra_infra_repo  = local.region_vars.locals.infra_modules_repo
  terra_mod_name    = "infra-modules/core-modules/module-route53"
  terra_mod_version = "v0.0.1"

  default_route53_zones = {
    "${local.account_vars.locals.master_domain}" = {
      comment       = "Primary Infra zone ${local.account_vars.locals.master_domain}"
      force_destroy = true
    }

    "${local.account_vars.locals.r53_domain_name}" = {
      comment       = "Env Infra zone ${local.account_vars.locals.r53_domain_name}"
      force_destroy = true
    }
  }

  default_route53_zone_records = {
    "${local.account_vars.locals.r53_domain_name}" = {
      zone_name         = local.account_vars.locals.master_domain
      description       = "Env Infra record for zone ${local.account_vars.locals.r53_domain_name}"
      type              = "NS"
      ttl               = 300
      records_from_zone = local.account_vars.locals.r53_domain_name
    }
  }

  base_source = "${dirname(find_in_parent_folders("root.hcl"))}/..//${local.terra_mod_name}"
}


include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  //source = "git::${local.terra_infra_repo}/${terra_mod_name}?ref=${local.terra_mod_version}"
  source = "${local.base_source}"
}

inputs = {
  #Module Route53 - Input Vars
  route53_zones = local.default_route53_zones
  route53_zone_records = local.default_route53_zone_records

  #default_tags = merge( local.region_vars.locals.region_tags,  {    terraform: true  }  )
}
