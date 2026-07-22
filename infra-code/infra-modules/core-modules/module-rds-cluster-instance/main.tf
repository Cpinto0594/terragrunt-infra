
module "module_rds_cluster" {
    source = "../core-modules/module-rds/rds-cluster"

    environment                         =   var.environment
    aws_region                          =   var.aws_region
    account_id                          =   var.account_id
    default_tags                        =   var.default_tags

    cluster_identifier                  =   var.cluster_identifier
    engine                              =   var.engine
    engine_version                      =   var.engine_version
    port                                =   var.port
    availability_zones                  =   var.availability_zones
    cluster_database_name               =   var.cluster_database_name
    master_username                     =   var.master_username
    master_password                     =   var.master_password
    enabled_cloudwatch_logs_exports     =   var.enabled_cloudwatch_logs_exports
    vpc_security_group_ids              =   var.vpc_security_group_ids
    r53_domain_name                     =   var.r53_domain_name
    route_53_record_prefix              =   var.route_53_record_prefix
}

module "module_rds_cluster_instance" {
    source = "../core-modules/module-rds/rds-cluster-instance"

    environment                   =   var.environment
    aws_region                    =   var.aws_region
    account_id                    =   var.account_id
    default_tags                  =   var.default_tags
  

    instance_identifier           =   var.instance_identifier
    cluster_name                  =   var.cluster_name
    instance_class                =   var.instance_class

    depends_on = [
        module.module_rds_cluster
    ]  
}