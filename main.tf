##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  table_name = replace(var.name != "" ? var.name : "${var.name_prefix}-${local.system_name}", "-", "_")
}

module "this" {
  source                                = "terraform-aws-modules/dynamodb-table/aws"
  version                               = "~> 4.0"
  create_table                          = true
  name                                  = local.table_name
  attributes                            = try(var.db.attributes, [])
  autoscaling_defaults                  = try(var.db.autoscaling_defaults, var.db.autoscaling.defaults, {})
  autoscaling_enabled                   = try(var.db.autoscaling_enabled, var.db.autoscaling.enabled, false)
  autoscaling_indexes                   = try(var.db.autoscaling_indexes, var.db.autoscaling.indexes, {})
  autoscaling_read                      = try(var.db.autoscaling.read, {})
  autoscaling_write                     = try(var.db.autoscaling.write, {})
  billing_mode                          = try(var.db.capacity.billing_mode, "PAY_PER_REQUEST")
  read_capacity                         = try(var.db.capacity.read, 0)
  write_capacity                        = try(var.db.capacity.write, 0)
  deletion_protection_enabled           = try(var.db.deletion_protection, false)
  hash_key                              = try(var.db.hash_key, null)
  range_key                             = try(var.db.range_key, null)
  point_in_time_recovery_enabled        = try(var.db.recovery.enabled, false)
  point_in_time_recovery_period_in_days = try(var.db.recovery.period_in_days, null)
  replica_regions                       = try(var.db.replicas.regions, [])
  server_side_encryption_enabled        = try(var.db.encryption.enabled, false)
  server_side_encryption_kms_key_arn    = try(var.db.encryption.kms_key_arn, null)
  stream_enabled                        = try(var.db.stream.enabled, false)
  stream_view_type                      = try(var.db.stream.view_type, null)
  table_class                           = try(var.db.table_class, null)
  ttl_enabled                           = try(var.db.ttl.enabled, false)
  ttl_attribute_name                    = try(var.db.ttl.attribute_name, null)
  global_secondary_indexes              = try(var.db.global_secondary_indexes, [])
  ignore_changes_global_secondary_index = try(var.db.ignore_changes_global_secondary_index, false)
  local_secondary_indexes               = try(var.db.local_secondary_indexes, [])
  import_table                          = try(var.db.import_table, {})
  tags                                  = local.all_tags
}