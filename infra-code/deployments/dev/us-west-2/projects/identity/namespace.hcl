locals {
    namespace      = "identity"
    version        = "1.0.0"        
    environment    = "dev"
    owner          = "devops"
    custodian      = "cpinto"
    state_bucket   = "terra-${local.namespace}-${local.version}-bucket" 
    dynamodb_table = "dynamo-${local.namespace}-${local.version}-table"

    namespace_tags = {
        namespace      = local.namespace
        environment    = local.environment
        owner          = local.owner
        custodian      = local.custodian
    }
}

dependencies {
    paths = ["../../core"]
}