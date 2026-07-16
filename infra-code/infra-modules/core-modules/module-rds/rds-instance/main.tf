locals {
    tags                                =   var.default_tags
    
    r53_domain_name                     =   var.r53_domain_name
    engine                              =   var.engine
    engine_version                      =   var.engine_version
    identifier                          =   var.instance_identifier
    port                                =   var.port
    availability_zone                   =   var.availability_zone
    db_name                             =   var.db_name
    username                            =   var.username
    password                            =   var.password
    enabled_cloudwatch_logs_exports     =   var.enabled_cloudwatch_logs_exports
    vpc_security_group_ids              =   var.vpc_security_group_ids
    allocated_storage                   =   var.allocated_storage
    instance_class                      =   var.instance_class
    route_53_record_prefix              =   coalesce( var.route_53_record_prefix , var.instance_identifier )
    subnet_ids                          =   toset(data.aws_subnets.subnets.ids)

}

resource "aws_db_instance" "rds_instance" {
    identifier                          = local.identifier
    allocated_storage                   = local.allocated_storage
    db_name                             = local.db_name
    instance_class                      = coalesce(local.instance_class, "db.t3.medium")
    engine                              = local.engine
    engine_version                      = local.engine_version
    username                            = local.username
    password                            = local.password
    skip_final_snapshot                 = true
    enabled_cloudwatch_logs_exports     = local.enabled_cloudwatch_logs_exports
    vpc_security_group_ids              = local.vpc_security_group_ids
    availability_zone                   = local.availability_zone
    publicly_accessible                 = true
    port                                = local.port
    db_subnet_group_name                = aws_db_subnet_group.subnet_group.id


    
    tags = merge(local.tags , {
        Name  = local.identifier
    })
  
    depends_on = [
        aws_db_subnet_group.subnet_group
    ]

}

resource "aws_db_subnet_group" "subnet_group" {
  name        = "subnet-group-db-${local.identifier}"
  subnet_ids  = local.subnet_ids

  tags = merge(local.tags , {
    Name = "subnet-group-db-${local.identifier}"
  })
}


resource "aws_route53_record" "rds_route53_record" {
    zone_id = "${data.aws_route53_zone.primary.zone_id}"
    name = "${ local.route_53_record_prefix }.${data.aws_route53_zone.primary.name}"
    type = "CNAME"
    ttl = "300"
    records = [aws_db_instance.rds_instance.endpoint]

    depends_on = [
        aws_db_instance.rds_instance
    ]

}


data "aws_route53_zone" "primary" {
  name = local.r53_domain_name
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

