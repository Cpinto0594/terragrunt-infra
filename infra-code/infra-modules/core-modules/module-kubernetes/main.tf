
locals {

  defaults = yamldecode(file("${path.module}/defaults.yaml"))

  cluster_name              = var.cluster_name
  role_arn                  = var.role_arn
  cluster_security_groups   = var.cluster_security_groups
  logs_retention_days       = var.logs_retention_days
  cluster_version           = var.cluster_version
  enabled_cluster_log_types = var.enabled_cluster_log_types
  oidc_enabled              = var.oidc_enabled

  subnet_ids                = var.subnet_ids
  vpc_id                    = var.vpc_id

  # kube_clusters               =   var.kube_clusters
  kube_node_groups          = var.kube_node_groups
  cluster_addons            = var.cluster_addons

  cluster_addons_names      =   [ for idx, addon in local.cluster_addons: addon.name ]
  cluster_addons_role_names =   { for idx, addon in local.cluster_addons: addon.name => addon.service_account_name
                                  if  try(addon.service_account_name, null) != null 
                                }
  cluster_addons_roles_arns =   { for idx, addon in local.cluster_addons: addon.service_account_name => data.aws_iam_role.cluster_addons_role_names[addon.service_account_name].arn
                                  if  try(addon.service_account_name, null) != null 
                                }

  security_group_ids        =   distinct([
                                        for sec_group in concat(local.defaults["cluster_defaults"]["cluster_security_groups"], coalesce(local.cluster_security_groups, [])) :
                                        data.aws_security_group.kube_sec_groups[sec_group].id
                            ])


  node_groups_computed      =   [ for indx, group in local.kube_node_groups :
                                    merge(local.defaults["cluster_node_defaults"], try(group, {}))
                                ]

  tags                      = var.default_tags

}


resource "aws_eks_cluster" "eks_cluster" {
  name     = local.cluster_name
  role_arn = data.aws_iam_role.kube_iam_sec_role.arn
  version  = coalesce(local.cluster_version, local.defaults["cluster_defaults"]["cluster_version"])

  vpc_config {
    subnet_ids         = local.subnet_ids
    security_group_ids = local.security_group_ids
  }

  enabled_cluster_log_types = coalesce(local.enabled_cluster_log_types, local.defaults["cluster_defaults"]["enabled_cluster_log_types"])
  tags = merge(local.tags, {
    Name = local.cluster_name
  })

  depends_on = [aws_cloudwatch_log_group.kube_cluster_cloudwatch_logs]

}

#Node_groups roles must not contain path
resource "aws_eks_node_group" "eks_clusters_node_group" {
  for_each        = { for idx, node_group in local.kube_node_groups : (tonumber(idx) + 1) => node_group }
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "node_group_${local.cluster_name}_${each.key}"
  subnet_ids      = local.subnet_ids
  version         = aws_eks_cluster.eks_cluster.version

  node_role_arn = data.aws_iam_role.kube_node_iam_sec_roles[coalesce(each.value.node_group_role, local.defaults["cluster_node_defaults"]["node_group_role"])].arn

  instance_types       = try(each.value.instance_types, local.defaults["cluster_node_defaults"]["instance_types"])
  ami_type             = try(each.value.ami_type, local.defaults["cluster_node_defaults"]["ami_type"])
  disk_size            = try(each.value.disk_size, local.defaults["cluster_node_defaults"]["disk_size"])
  capacity_type        = try(each.value.capacity_type, local.defaults["cluster_node_defaults"]["capacity_type"])
  force_update_version = true

  scaling_config {
    desired_size = try(each.value.scaling_config.desired_size, local.defaults["cluster_node_defaults"]["scaling_config"]["desired_size"])
    max_size     = try(each.value.scaling_config.max_size, local.defaults["cluster_node_defaults"]["scaling_config"]["max_size"])
    min_size     = try(each.value.scaling_config.min_size, local.defaults["cluster_node_defaults"]["scaling_config"]["min_size"])
  }

  update_config {
    max_unavailable = try(each.value.update_config.max_unavailable, local.defaults["cluster_node_defaults"]["update_config"]["max_unavailable"])
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]

  tags = merge(local.tags, {
    Name = "node_group_${local.cluster_name}_${each.key}"
  })
}

## CLUSTER LOG GROUPS
resource "aws_cloudwatch_log_group" "kube_cluster_cloudwatch_logs" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = coalesce(local.logs_retention_days, local.defaults["cluster_defaults"]["logs_retention_days"])
  skip_destroy      = false
  tags = merge(local.tags, {
    Name = "/aws/eks/${local.cluster_name}/cluster"
  })
}

## CLUSTER ADDONS

data "aws_eks_addon_version" "most_recent" {
  for_each                    = toset([ for index, addon in local.cluster_addons : addon.name ])
  addon_name         = each.value
  kubernetes_version =  aws_eks_cluster.eks_cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "addons" {
  for_each                    = { for index, addon in local.cluster_addons : addon.name => addon }
  cluster_name                = local.cluster_name
  addon_name                  = each.key
  addon_version               = coalesce(each.value.version , data.aws_eks_addon_version.most_recent[each.key].version )
  
  service_account_role_arn    = coalesce( local.cluster_addons_roles_arns[ each.value.service_account_name ] ,   each.value.service_account_arn )
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(local.tags, {
    Name = each.key
  })
}

#CLUSTER OIDC PROVIDER
resource "aws_iam_openid_connect_provider" "default_openid_provider" {
  count           = local.oidc_enabled ? 1 : 0
  url             = data.aws_eks_cluster.cluster_datasource.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_tls_cert_issuer.certificates[0].sha1_fingerprint]
  tags = merge(local.tags, {
    Name = "${local.cluster_name}_aws_iam_openid_connect_provider"
  })

  depends_on = [aws_eks_cluster.eks_cluster]
}

################### HANDLE ADDONS EXTRAS ################################
data "aws_iam_policy_document" "pod_identity_csi_driver_policy" {
  count = contains(local.cluster_addons_names, "aws-ebs-csi-driver") ? 1 : 0 
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default_openid_provider[0].url, "https://", "")}:aud"
      #variable = "${join("/", slice(split("/", aws_iam_openid_connect_provider.default_openid_provider[0].id), 1, 4))}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default_openid_provider[0].url, "https://", "")}:sub"
      #variable = "${join("/", slice(split("/", aws_iam_openid_connect_provider.default_openid_provider[0].id), 1, 4))}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.default_openid_provider[0].arn]
    }
  }
}

data "aws_iam_policy" "aws_csi_driver_policy" {
  count = contains(local.cluster_addons_names, "aws-ebs-csi-driver") ? 1 : 0 
  name  = "AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "pod_identity_cs_driver_role" {
  count = contains(local.cluster_addons_names, "aws-ebs-csi-driver") ? 1 : 0 
  name               = "AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_csi_driver_policy[0].json
  tags = merge(local.tags, {
    Name = "AmazonEKS_EBS_CSI_DriverRole"
  })
}

resource "aws_iam_role_policy_attachment" "pod_identity_cs_driver_role-attach" {
  count = contains(local.cluster_addons_names, "aws-ebs-csi-driver") ? 1 : 0 
  role       = aws_iam_role.pod_identity_cs_driver_role[0].name
  policy_arn = data.aws_iam_policy.aws_csi_driver_policy[0].arn
}



data "aws_eks_cluster" "cluster_datasource" {
  name       = local.cluster_name
  depends_on = [aws_eks_cluster.eks_cluster]
}


data "tls_certificate" "cluster_tls_cert_issuer" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  depends_on = [aws_eks_cluster.eks_cluster]
}


data "aws_security_group" "kube_sec_groups" {
  for_each = toset(distinct(concat(local.defaults["cluster_defaults"]["cluster_security_groups"], coalesce(local.cluster_security_groups, []))))
  name     = each.value
}

data "aws_iam_role" "kube_iam_sec_role" {
  name = coalesce(local.role_arn, local.defaults["cluster_defaults"]["role_arn"])
}


data "aws_iam_role" "kube_node_iam_sec_roles" {
  for_each = toset(distinct([
    for indx, config in local.kube_node_groups : coalesce(config.node_group_role, local.defaults["cluster_node_defaults"]["node_group_role"])
  ]))
  name = each.value
}

data "aws_iam_role" "cluster_addons_role_names" {
    for_each = toset([ for name, role_name in local.cluster_addons_role_names :  role_name ])
    name = each.value
    depends_on = [ aws_iam_role.pod_identity_cs_driver_role ]
}
