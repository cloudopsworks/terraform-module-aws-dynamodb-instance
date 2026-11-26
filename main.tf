##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  table_name = replace(var.name != "" ? var.name : "${var.name_prefix}-${local.system_name}", "-", "_")

  # Upstream autoscaling policies index these keys directly, so they must always be present
  # even when the caller overrides only part of the defaults map.
  autoscaling_base_defaults = {
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    target_value       = 70
  }

  # Global table replicas accept either db.replicas.regions (list) or a list placed directly under db.replicas.
  replicas_input  = try(var.db.replicas, [])
  replica_regions = try(local.replicas_input.regions, [for r in local.replicas_input : r if can(local.replicas_input[0])], [])

  # Effective table settings resolved from var.db, kept in one place so they can be asserted in tests.
  table = {
    attributes                            = try(var.db.attributes, [])
    hash_key                              = try(var.db.hash_key, null)
    range_key                             = try(var.db.range_key, null)
    autoscaling_enabled                   = try(var.db.autoscaling_enabled, var.db.autoscaling.enabled, false)
    autoscaling_defaults                  = merge(local.autoscaling_base_defaults, try(var.db.autoscaling_defaults, var.db.autoscaling.defaults, {}))
    autoscaling_indexes                   = try(var.db.autoscaling_indexes, var.db.autoscaling.indexes, {})
    autoscaling_read                      = try(var.db.autoscaling.read, {})
    autoscaling_write                     = try(var.db.autoscaling.write, {})
    billing_mode                          = try(var.db.capacity.billing_mode, "PAY_PER_REQUEST")
    read_capacity                         = try(var.db.capacity.read, 0)
    write_capacity                        = try(var.db.capacity.write, 0)
    deletion_protection_enabled           = try(var.db.deletion_protection, true)
    point_in_time_recovery_enabled        = try(var.db.recovery.enabled, false)
    point_in_time_recovery_period_in_days = try(var.db.recovery.period_in_days, null)
    replica_regions                       = local.replica_regions
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
  }
}

module "this" {
  source                                = "terraform-aws-modules/dynamodb-table/aws"
  version                               = "~> 5.0"
  create_table                          = true
  name                                  = local.table_name
  attributes                            = local.table.attributes
  autoscaling_defaults                  = local.table.autoscaling_defaults
  autoscaling_enabled                   = local.table.autoscaling_enabled
  autoscaling_indexes                   = local.table.autoscaling_indexes
  autoscaling_read                      = local.table.autoscaling_read
  autoscaling_write                     = local.table.autoscaling_write
  billing_mode                          = local.table.billing_mode
  read_capacity                         = local.table.read_capacity
  write_capacity                        = local.table.write_capacity
  deletion_protection_enabled           = local.table.deletion_protection_enabled
  hash_key                              = local.table.hash_key
  range_key                             = local.table.range_key
  point_in_time_recovery_enabled        = local.table.point_in_time_recovery_enabled
  point_in_time_recovery_period_in_days = local.table.point_in_time_recovery_period_in_days
  replica_regions                       = local.table.replica_regions
  server_side_encryption_enabled        = local.table.server_side_encryption_enabled
  server_side_encryption_kms_key_arn    = local.table.server_side_encryption_kms_key_arn
  stream_enabled                        = local.table.stream_enabled
  stream_view_type                      = local.table.stream_view_type
  table_class                           = local.table.table_class
  ttl_enabled                           = local.table.ttl_enabled
  ttl_attribute_name                    = local.table.ttl_attribute_name
  global_secondary_indexes              = local.table.global_secondary_indexes
  ignore_changes_global_secondary_index = local.table.ignore_changes_global_secondary_index
  local_secondary_indexes               = local.table.local_secondary_indexes
  import_table                          = local.table.import_table
  tags                                  = local.all_tags
}
