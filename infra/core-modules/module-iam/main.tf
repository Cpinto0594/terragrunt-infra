locals {
  managed_infra_roles    = var.managed_infra_roles
  managed_infra_policies = var.managed_infra_policies

  managed_infra_users = var.managed_infra_users

  roles_policies_assoc = flatten([for role, definition in local.managed_infra_roles :
    [for policyArn in concat(
      [for managed_policy in coalesce(definition.managed_policies, []) : aws_iam_policy.infra_policies[managed_policy].arn],
      [for arn in coalesce(definition.managed_policies_arn, []) : replace(arn, "{{AWS_ACCOUNT}}", var.account_id)]
      ) : { role = role, policy_arn = policyArn }
    ]
  ])

  managed_user_policies = flatten([for user, definition in local.managed_infra_users :
    [for key, managedPolicy in definition.managed_policies_definitions :
      { key = key, managedPolicy = managedPolicy, user = user }
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
      resources = coalesce(statement.value.Resource, [])
    }
  }
}


##  Assume Policy document for infra roles
##This is used to create the assume role policy document for each role defined in the managed_infra_roles variable
data "aws_iam_policy_document" "infra_services_roles_data" {
  for_each = local.managed_infra_roles

  dynamic "statement" {
    for_each = each.value.assume_role_policy == null ? [] : each.value.assume_role_policy.Statement

    content {
      actions = statement.value.Action
      effect  = statement.value.Effect


      dynamic "principals" {
        for_each = toset(coalesce(statement.value.Principal.Service, []))
        content {
          type        = "Service"
          identifiers = [replace(principals.value, "{{AWS_ACCOUNT}}", var.account_id)]
        }

      }

      dynamic "principals" {
        for_each = toset(coalesce(statement.value.Principal.AWS, []))
        content {
          type        = "AWS"
          identifiers = [replace(principals.value, "{{AWS_ACCOUNT}}", var.account_id)]
        }

      }
    }
  }
}

resource "aws_iam_policy" "infra_policies" {
  for_each = local.managed_infra_policies
  name     = each.key
  policy   = data.aws_iam_policy_document.infra_policies_data[each.key].json
}


resource "aws_iam_role" "infra_services_roles" {
  for_each = local.managed_infra_roles
  name     = each.key
  path     = each.value.path

  assume_role_policy = data.aws_iam_policy_document.infra_services_roles_data[each.key].json

  depends_on = [
    aws_iam_policy.infra_policies
  ]

  tags = merge(local.tags, {
    Name = each.key
  })
}


resource "aws_iam_role_policy_attachment" "managed_policies_attachment" {
  for_each   = { for index, assoc in local.roles_policies_assoc : index => assoc }
  role       = each.value.role
  policy_arn = each.value.policy_arn
  depends_on = [aws_iam_role.infra_services_roles]
}



resource "aws_iam_user" "managed_users" {
  for_each = local.managed_infra_users
  name     = each.key
  path     = each.value.path != null ? each.value.path : "/"

  tags = merge(local.tags, {
    Name = each.key
  })
}

# resource "aws_iam_access_key" "managed_users_access_key" {
#   user = aws_iam_user.managed_users.name
# }

data "aws_iam_policy_document" "managed_users_policy_document" {
  for_each = { for policy in local.managed_user_policies : policy.key => policy }
  version  = each.value.managedPolicy.policy.Version

  dynamic "statement" {
    for_each = each.value.managedPolicy.policy.Statement
    content {
      effect    = statement.value.Effect
      actions   = statement.value.Action
      resources = [for resource in statement.value.Resource : replace(resource, "{{AWS_ACCOUNT}}", var.account_id)]
    }
  }
}

resource "aws_iam_user_policy" "managed_users_policy" {
  for_each   = { for policy in local.managed_user_policies : policy.key => policy }
  name       = each.key
  user       = aws_iam_user.managed_users[each.value.user].name
  policy     = data.aws_iam_policy_document.managed_users_policy_document[each.key].json
  depends_on = [aws_iam_user.managed_users]
}
