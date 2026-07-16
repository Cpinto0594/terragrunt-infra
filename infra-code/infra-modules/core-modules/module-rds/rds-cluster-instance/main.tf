locals {

    tags                        =   var.default_tags
    identifier                  =   var.instance_identifier
    cluster_name                =   var.cluster_name
    instance_class              =   var.instance_class
}


resource "aws_rds_cluster_instance" "rds_cluster_instance" {
  identifier            = local.identifier
  cluster_identifier    = data.aws_rds_cluster.rds_cluster.id
  instance_class        = coalesce(local.instance_class, "db.t3.medium")
  engine                = data.aws_rds_cluster.rds_cluster.engine
  engine_version        = data.aws_rds_cluster.rds_cluster.engine_version
  db_subnet_group_name  = data.aws_db_subnet_group.subnet_group.id

  tags = merge(local.tags , {
    Name  = local.identifier
  })
  
}

data "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = local.cluster_name
}

data "aws_db_subnet_group" "subnet_group" {
  name = "subnet-group-${local.cluster_name}"
}