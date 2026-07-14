locals {

    tags                                =   var.default_tags
    
    engine                              =   var.engine
    engine_version                      =   var.engine_version
    identifier                          =   var.cluster_identifier
    port                                =   var.port
    availability_zones                  =   var.availability_zones
    database_name                       =   var.cluster_database_name
    master_username                     =   var.master_username
    master_password                     =   var.master_password
    enabled_cloudwatch_logs_exports     =   var.enabled_cloudwatch_logs_exports
    vpc_security_group_ids              =   var.vpc_security_group_ids

    route_53_record_prefix              =   coalesce( var.route_53_record_prefix , var.cluster_identifier )
    r53_domain_name                     =   var.r53_domain_name

    security_group_ids                  =   distinct(concat(flatten([
                                                    for sec_group in var.vpc_security_group_ids :
                                                        data.aws_security_group.infra_sec_groups[sec_group].id 
                                                    ])))
    subnet_ids                          =   toset(data.aws_subnets.subnets.ids)
}


resource "aws_rds_cluster" "rds_clusters" {
  cluster_identifier              = local.identifier
  engine                          = coalesce( local.engine, "aurora-postgresql" )
  engine_version                  = coalesce( local.engine_version,  "16.1" )
  engine_mode                     = "provisioned"
  port                            = local.port
  availability_zones              = local.availability_zones
  database_name                   = local.database_name
  master_username                 = local.master_username
  master_password                 = local.master_password
  db_cluster_instance_class       = null
  apply_immediately               = true
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports
  vpc_security_group_ids          = local.security_group_ids
  db_subnet_group_name            = aws_db_subnet_group.subnet_group.id

  tags = merge(local.tags , {
    Name  = local.identifier
  })
  
  depends_on = [
    aws_db_subnet_group.subnet_group
  ]
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = "subnet-group-${local.identifier}"
  subnet_ids  = local.subnet_ids

  tags = merge(local.tags , {
    Name = "subnet-group-${local.identifier}"
  })
}

data "aws_vpcs" "app_vpc" {
  tags = {
    Name = "app_vpc"
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = toset(data.aws_vpcs.app_vpc.ids)
  }
}


data "aws_security_group" "infra_sec_groups" {
  for_each  = toset(var.vpc_security_group_ids)
  name = each.value
}



data "aws_route53_zone" "primary" {
  name = local.r53_domain_name
}


resource "aws_route53_record" "rds_route53_record" {
    zone_id = "${data.aws_route53_zone.primary.zone_id}"
    name = "${ local.route_53_record_prefix }.${data.aws_route53_zone.primary.name}"
    type = "CNAME"
    ttl = "300"
    records = [aws_rds_cluster.rds_clusters.endpoint]

    depends_on = [
        aws_rds_cluster.rds_clusters
    ]

}


