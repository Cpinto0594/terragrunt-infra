
locals {
    externaldns_name            =   "${var.environment}-external-dns"
    external_dns_namespace      =   local.networking_namespace
}


resource "kubectl_manifest" "external_dns" {
    yaml_body = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${local.externaldns_name}
  namespace: ${local.external_dns_namespace}
  labels:
    app.kubernetes.io/name: ${local.externaldns_name}
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: ${local.externaldns_name}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ${local.externaldns_name}
    spec:
      serviceAccountName: ${local.externaldns_name}
      containers:
        - name: ${local.externaldns_name}
          image: registry.k8s.io/external-dns/external-dns:v0.14.2
          args:
            - --source=service
            - --source=ingress
            - --domain-filter=${var.r53_domain_name} # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
            - --provider=aws
            - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
            - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
            - --registry=txt
            - --txt-owner-id=${data.aws_route53_zone.selected.zone_id}
          env:
            - name: AWS_DEFAULT_REGION
              value: ${var.aws_region}
EOF
}

data "aws_route53_zone" "selected" {
  name         = var.r53_domain_name
}


################### HANDLE SERVICE ACCOUNT PERMISSIONS ################################

data "aws_iam_openid_connect_provider" "cluster_oidc_provider" {
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  depends_on = [data.aws_eks_cluster.eks_cluster]
}


data "aws_iam_policy_document" "external_dns_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.cluster_oidc_provider.url, "https://", "")}:aud"
      #variable = "${join("/", slice(split("/", aws_iam_openid_connect_provider.cluster_oidc_provider[0].id), 1, 4))}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.cluster_oidc_provider.url, "https://", "")}:sub"
      #variable = "${join("/", slice(split("/", aws_iam_openid_connect_provider.cluster_oidc_provider[0].id), 1, 4))}:sub"
      values   = ["system:serviceaccount:${local.networking_namespace}:${local.externaldns_name}"]
    }
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.cluster_oidc_provider.arn]
    }
  }
}

resource "aws_iam_role" "external_dns_saccount_role" {
  name               = "ExternalDnsServiceAccountRole"
  assume_role_policy = data.aws_iam_policy_document.external_dns_role_policy.json
  tags = merge(local.tags, {
    Name = "ExternalDnsServiceAccountRole"
  })
}

data "aws_iam_policy" "aws_route_53_editor_policy" {
  name  = "Route53Editor"
}

resource "aws_iam_role_policy_attachment" "pod_identity_cs_driver_role-attach" {
  role       = aws_iam_role.external_dns_saccount_role.name
  policy_arn = data.aws_iam_policy.aws_route_53_editor_policy.arn
}
