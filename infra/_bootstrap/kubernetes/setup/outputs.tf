output "output_kube_resources_mod_namespaces" {
    value    =  [for key, value in kubernetes_namespace.namespaces : value.metadata[0].name ]
}

output "output_kube_resources_mod_service_accounts" {
    value   =   [for key, value in kubernetes_service_account.kubernetes_service_account: value.metadata[0].name]
}