locals {
  managed_infra_roles    = var.managed_infra_roles
  managed_infra_policies = var.managed_infra_policies

  roles_policies_assoc = flatten([ for role, definition in local.managed_infra_roles : 
                                      [ for policyArn in concat(
                                          [for managed_policy in coalesce(definition.managed_policies, []) : aws_iam_policy.infra_policies[managed_policy].arn],
                                          [for arn in coalesce(definition.managed_policies_arn, []) : replace(arn, "{{AWS_ACCOUNT}}", var.account_id)]
                                          ) : {role = role, policy_arn = policyArn }
                                      ]
                                ])



  tags = var.default_tags
}


##  Policy document for infra configuration
data "aws_iam_policy_document" "infra_policies_data" {
  for_each = local.managed_infra_policies
  dynamic "statement" {
    for_each = each.value.policy.Statement
    content {
      actions   = statement.value.Action
      effect    = statement.value.Effect
      resources = statement.value.Resource
    }
  }
}

resource "aws_iam_policy" "infra_policies" {
  for_each = local.managed_infra_policies
  name     = each.key
  policy   = data.aws_iam_policy_document.infra_policies_data[each.key].json
}

##  Assume Policy document for apps service roles
data "aws_iam_policy_document" "infra_services_roles_data" {
  for_each = local.managed_infra_roles

  dynamic "statement" {
    for_each = each.value.assume_role_policy.Statement

    content {
      actions = statement.value.Action
      effect  = statement.value.Effect


      dynamic "principals" {
        for_each = statement.value.Principal == null ? [] : ["1"]
        content {
          type        = "Service"
          identifiers = statement.value.Principal.Service
        }
      }
    }
  }
}

resource "aws_iam_role" "infra_services_roles" {
  for_each = local.managed_infra_roles
  name     = each.key
  path     = each.value.path

  assume_role_policy = data.aws_iam_policy_document.infra_services_roles_data[each.key].json

  # managed_policy_arns = flatten(concat(
  #   [for managed_policy in coalesce(each.value.managed_policies, []) : aws_iam_policy.infra_policies[managed_policy].arn],
  #   [for arn in coalesce(each.value.managed_policies_arn, []) : replace(arn, "{{AWS_ACCOUNT}}", var.account_id)]
  # ))

  depends_on = [
    aws_iam_policy.infra_policies
  ]

  tags = merge(local.tags, {
    Name = each.key
  })
}


resource "aws_iam_role_policy_attachment" "managed_policies_attachment" {
  for_each   = { for index, assoc in local.roles_policies_assoc : index => assoc}
  role       = each.value.role
  policy_arn = each.value.policy_arn
}
