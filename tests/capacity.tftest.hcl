##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Every run uses command = plan against a mocked AWS provider, so no credentials are needed.
mock_provider "aws" {
  override_data {
    target = data.aws_region.current
    values = { region = "us-east-1" }
  }
}

variables {
  org = {
    organization_name = "acme"
    organization_unit = "devops"
    environment_type  = "production"
    environment_name  = "prod"
  }
  spoke_def   = "001"
  name_prefix = "app"
  db = {
    attributes = [{ name = "id", type = "S" }]
    hash_key   = "id"
  }
}

# Case 6: a minimal db object resolves to the documented defaults.
run "minimal_table_uses_defaults" {
  command = plan

  assert {
    condition     = local.table.billing_mode == "PAY_PER_REQUEST"
    error_message = "Default billing mode must be PAY_PER_REQUEST."
  }

  assert {
    condition     = local.table.deletion_protection_enabled == true
    error_message = "Deletion protection must be enabled by default."
  }

  assert {
    condition     = local.table.range_key == null && local.table.hash_key == "id"
    error_message = "Expected hash_key id and no range_key."
  }

  assert {
    condition = alltrue([
      local.table.autoscaling_enabled == false,
      local.table.point_in_time_recovery_enabled == false,
      local.table.server_side_encryption_enabled == false,
      local.table.stream_enabled == false,
      local.table.ttl_enabled == false,
      local.table.ignore_changes_global_secondary_index == false,
    ])
    error_message = "Optional features must be disabled by default."
  }

  assert {
    condition = alltrue([
      length(local.table.global_secondary_indexes) == 0,
      length(local.table.local_secondary_indexes) == 0,
      length(local.table.replica_regions) == 0,
      length(local.table.import_table) == 0,
    ])
    error_message = "Indexes, replicas and import_table must be empty by default."
  }
}

# Case 7: deletion protection can be turned off explicitly.
run "deletion_protection_can_be_disabled" {
  command = plan

  variables {
    db = {
      attributes          = [{ name = "id", type = "S" }]
      hash_key            = "id"
      deletion_protection = false
    }
  }

  assert {
    condition     = local.table.deletion_protection_enabled == false
    error_message = "deletion_protection = false was not honored."
  }
}

# Case 8: composite primary key with provisioned capacity.
run "provisioned_composite_key" {
  command = plan

  variables {
    db = {
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "N" },
      ]
      hash_key  = "pk"
      range_key = "sk"
      capacity = {
        billing_mode = "PROVISIONED"
        read         = 10
        write        = 5
      }
    }
  }

  assert {
    condition     = local.table.hash_key == "pk" && local.table.range_key == "sk"
    error_message = "Composite key was not passed through."
  }

  assert {
    condition     = local.table.billing_mode == "PROVISIONED" && local.table.read_capacity == 10 && local.table.write_capacity == 5
    error_message = "Provisioned capacity was not passed through."
  }

  assert {
    condition     = length(local.table.attributes) == 2
    error_message = "Expected two attribute definitions."
  }
}

# Case 9: autoscaling with only part of the defaults map keeps the remaining upstream defaults.
# Regression test: an empty or partial defaults map used to fail the plan inside the upstream module.
run "autoscaling_partial_defaults" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      capacity = {
        billing_mode = "PROVISIONED"
        read         = 5
        write        = 5
      }
      autoscaling = {
        enabled  = true
        defaults = { target_value = 50 }
        read     = { max_capacity = 100 }
        write    = { max_capacity = 50, target_value = 60 }
      }
    }
  }

  assert {
    condition     = local.table.autoscaling_enabled == true
    error_message = "Autoscaling must be enabled."
  }

  assert {
    condition     = local.table.autoscaling_defaults.target_value == 50
    error_message = "Caller target_value must override the default."
  }

  assert {
    condition     = local.table.autoscaling_defaults.scale_in_cooldown == 0 && local.table.autoscaling_defaults.scale_out_cooldown == 0
    error_message = "Missing cooldown defaults must fall back to 0."
  }

  assert {
    condition     = local.table.autoscaling_read.max_capacity == 100 && local.table.autoscaling_write.target_value == 60
    error_message = "Read/write autoscaling maps were not passed through."
  }
}

# Case 10: autoscaling enabled with no defaults block at all.
run "autoscaling_without_defaults_block" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      capacity   = { billing_mode = "PROVISIONED", read = 1, write = 1 }
      autoscaling = {
        enabled = true
        read    = { max_capacity = 20 }
        write   = { max_capacity = 20 }
      }
    }
  }

  assert {
    condition     = local.table.autoscaling_defaults.target_value == 70
    error_message = "target_value must default to 70."
  }
}

# Case 11: GSI autoscaling via autoscaling.indexes, keyed by index name.
run "autoscaling_gsi_indexes" {
  command = plan

  variables {
    db = {
      attributes = [
        { name = "id", type = "S" },
        { name = "email", type = "S" },
      ]
      hash_key = "id"
      capacity = { billing_mode = "PROVISIONED", read = 5, write = 5 }
      global_secondary_indexes = [
        {
          name            = "email-index"
          hash_key        = "email"
          projection_type = "ALL"
          read_capacity   = 5
          write_capacity  = 5
        },
      ]
      autoscaling = {
        enabled = true
        read    = { max_capacity = 50 }
        write   = { max_capacity = 50 }
        indexes = {
          "email-index" = {
            read_min_capacity  = 5
            read_max_capacity  = 40
            write_min_capacity = 5
            write_max_capacity = 40
          }
        }
      }
    }
  }

  assert {
    condition     = contains(keys(local.table.autoscaling_indexes), "email-index")
    error_message = "Index autoscaling map was not passed through."
  }

  assert {
    condition     = local.table.global_secondary_indexes[0].name == "email-index"
    error_message = "GSI definition was not passed through."
  }
}

# Case 12: legacy flat keys (autoscaling_enabled, autoscaling_defaults, autoscaling_indexes) still work,
# and ignore_changes_global_secondary_index is passed through.
run "autoscaling_legacy_flat_keys" {
  command = plan

  variables {
    db = {
      attributes = [
        { name = "id", type = "S" },
        { name = "status", type = "S" },
      ]
      hash_key = "id"
      capacity = { billing_mode = "PROVISIONED", read = 2, write = 2 }
      global_secondary_indexes = [
        { name = "status-index", hash_key = "status", projection_type = "KEYS_ONLY", read_capacity = 2, write_capacity = 2 },
      ]
      autoscaling_enabled                   = true
      autoscaling_defaults                  = { scale_in_cooldown = 60 }
      autoscaling_indexes                   = { "status-index" = { read_min_capacity = 2, read_max_capacity = 10, write_min_capacity = 2, write_max_capacity = 10 } }
      ignore_changes_global_secondary_index = true
    }
  }

  assert {
    condition     = local.table.autoscaling_enabled == true && local.table.autoscaling_defaults.scale_in_cooldown == 60
    error_message = "Legacy autoscaling_enabled / autoscaling_defaults keys were not honored."
  }

  assert {
    condition     = local.table.autoscaling_defaults.target_value == 70
    error_message = "Legacy defaults map must still be merged with the base defaults."
  }

  assert {
    condition     = local.table.ignore_changes_global_secondary_index == true
    error_message = "ignore_changes_global_secondary_index was not passed through."
  }
}
