locals {
    tags                            = var.default_tags
    ecr_repositories                = var.ecr_repositories
    ecr_repositories_config         = var.ecr_repositories_config

}

resource "aws_ecr_repository" "aws_ecr_repository" {
    for_each                = toset(local.ecr_repositories)
    name                    = each.value
    force_delete            = try( local.ecr_repositories_config[each.value].force_delete,  true )
    image_tag_mutability    = try( local.ecr_repositories_config[each.value].image_tag_mutability,  "MUTABLE" )


    tags = merge(local.tags , {
        Name        = each.value
    })
}