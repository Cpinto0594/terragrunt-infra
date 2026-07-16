
locals {
  buckets = {
      for key, value in var.buckets: 
      ( value["raw_name"] == true ? key : "${key}-${var.environment}" ) => value 
      if key != "default"
  }
  buckets_public_acls = {
      for key, value in var.buckets: 
      ( value["raw_name"] == true ? key : "${key}-${var.environment}" ) => value 
      if value.acl != "private"
  }

  tags = merge(var.default_tags)
}


resource "aws_s3_bucket" "service_buckets" {
  for_each = local.buckets
  bucket = each.key
  force_destroy = true

  tags = merge(local.tags , {
    Name        = each.key
  })
}

resource "aws_s3_bucket_ownership_controls" "service_buckets" {
  for_each = local.buckets
  bucket = aws_s3_bucket.service_buckets[each.key].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# resource "aws_s3_bucket_public_access_block" "service_buckets" {
#   for_each = local.buckets_public_acls
#   bucket = aws_s3_bucket.service_buckets[each.key].id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# resource "aws_s3_bucket_acl" "service_buckets"  {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.service_buckets,
#     aws_s3_bucket_public_access_block.service_buckets
#   ]

#   for_each = local.buckets
#   bucket = aws_s3_bucket.service_buckets[each.key].id
#   acl = each.value.acl
# }