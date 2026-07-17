locals {
  tags = var.default_tags

  networking_namespace = "${var.environment}-networking"

  kube_namespaces       = var.kube_namespaces
  kube_service_accounts = var.kube_service_accounts
  kube_role_bindings    = var.kube_role_bindings
  kube_cluster_roles    = var.kube_cluster_roles

  service_accounts_computed = flatten([for service_account, sac_config in local.kube_service_accounts :
    [for namespace in sac_config.namespaces : { ns : namespace, sac : service_account, annotations:  sac_config.annotations }]
  ])
  role_bindings_computed = flatten([
    for value in local.kube_role_bindings : [
      for binding in value.bindings : { subject : value, binding : binding }
    ]
  ])

}

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(local.kube_namespaces)
  metadata {
    name = "${var.environment}-${each.value}"
    annotations = {
      name = "${var.environment}-${each.value}"
    }

    labels = {
      #"pod-security.kubernetes.io/enforce" : "privileged",
      #"pod-security.kubernetes.io/enforce-version" : "v1.29",
      "app.kubernetes.io/name" = "${var.environment}-${each.value}"
    }
  }
  depends_on = [data.aws_eks_cluster.eks_cluster]
}

resource "kubernetes_service_account_v1" "kubernetes_service_account" {
  for_each = { for value in local.service_accounts_computed : value.sac => value }
  metadata {
    name      = "${var.environment}-${each.key}"
    namespace = startswith(each.value.ns, "@") ? replace(each.value.ns, "@", ""):  "${var.environment}-${each.value.ns}"
    labels = {
      "app.kubernetes.io/name" = "${var.environment}-${each.key}"
    }

    annotations = { for key, value in coalesce(each.value.annotations, {}) : key => replace( value, "{ACCOUNT_ID}", var.account_id ) }
  }
  secret {
    name = kubernetes_secret_v1.kubernetes_account_secret[each.key].metadata[0].name
  }

  depends_on = [
    kubernetes_namespace_v1.namespaces,
    kubernetes_secret_v1.kubernetes_account_secret
  ]
}

resource "kubernetes_secret_v1" "kubernetes_account_secret" {
  for_each = { for value in local.service_accounts_computed : value.sac => value }
  metadata {
    name      = "${var.environment}-${each.key}-secret"
    namespace = startswith(each.value.ns, "@") ? replace(each.value.ns, "@", ""):  "${var.environment}-${each.value.ns}"
    labels = {
      "app.kubernetes.io/name" = "${var.environment}-${each.key}-secret"
    }
  }
  depends_on = [
    kubernetes_namespace_v1.namespaces
  ]
}

resource "kubernetes_cluster_role_v1" "kubernetes_cluster_role" {
  for_each = local.kube_cluster_roles
  metadata {
    name = "${var.environment}-${each.key}"
    labels = {
      "app.kubernetes.io/name" = "${var.environment}-${each.key}"
    }
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = coalesce(rule.value.apiGroups, [""])
      resources  = rule.value.resources
      verbs      = coalesce(rule.value.verbs, ["watch"])
    }
  }
  depends_on = [
    kubernetes_namespace_v1.namespaces
  ]
}

resource "kubernetes_cluster_role_binding_v1" "kubernetes_cluster_role_binding" {
  for_each = { for value in local.role_bindings_computed : value.subject.name => value }

  metadata {
    name = join(
      "-",
      [
        "${var.environment}-${each.key}",
        startswith(each.value.binding.name, "@") ? replace(each.value.binding.name, "@", "") : "${var.environment}-${each.value.binding.name}",
        "role-binding"
      ]
    )
    labels = {
      "app.kubernetes.io/name" = join(
        "-",
        [
          "${var.environment}-${each.key}",
          startswith(each.value.binding.name, "@") ? replace(each.value.binding.name, "@", "") : "${var.environment}-${each.value.binding.name}",
          "role-binding"
        ]
      )
    }
  }

  role_ref {
    api_group = each.value.binding.api_group
    kind      = each.value.binding.kind
    name      = startswith(each.value.binding.name, "@") ? replace(each.value.binding.name, "@", "") : "${var.environment}-${each.value.binding.name}"
  }

  subject {
    kind      = each.value.subject.kind
    name      = "${var.environment}-${each.value.subject.name}"
    namespace = startswith(each.value.subject.namespace, "@") ? replace(each.value.subject.namespace, "@", ""): "${var.environment}-${each.value.subject.namespace}"
  }

  depends_on = [
    kubernetes_namespace_v1.namespaces
  ]
}
