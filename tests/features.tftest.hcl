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

# Case 13: server-side encryption with a customer managed KMS key.
run "encryption_with_customer_kms_key" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      encryption = {
        enabled     = true
        kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      }
    }
  }

  assert {
    condition     = local.table.server_side_encryption_enabled == true
    error_message = "Encryption must be enabled."
  }

  assert {
    condition     = local.table.server_side_encryption_kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "KMS key ARN was not passed through."
  }
}

# Case 14: point-in-time recovery with a custom recovery window.
run "point_in_time_recovery_window" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      recovery = {
        enabled        = true
        period_in_days = 7
      }
    }
  }

  assert {
    condition     = local.table.point_in_time_recovery_enabled == true && local.table.point_in_time_recovery_period_in_days == 7
    error_message = "PITR settings were not passed through."
  }
}

# Case 15: streams, TTL and infrequent-access table class together.
run "streams_ttl_and_table_class" {
  command = plan

  variables {
    db = {
      attributes  = [{ name = "id", type = "S" }]
      hash_key    = "id"
      table_class = "STANDARD_INFREQUENT_ACCESS"
      stream = {
        enabled   = true
        view_type = "NEW_AND_OLD_IMAGES"
      }
      ttl = {
        enabled        = true
        attribute_name = "expires_at"
      }
    }
  }

  assert {
    condition     = local.table.stream_enabled == true && local.table.stream_view_type == "NEW_AND_OLD_IMAGES"
    error_message = "Stream settings were not passed through."
  }

  assert {
    condition     = local.table.ttl_enabled == true && local.table.ttl_attribute_name == "expires_at"
    error_message = "TTL settings were not passed through."
  }

  assert {
    condition     = local.table.table_class == "STANDARD_INFREQUENT_ACCESS"
    error_message = "table_class was not passed through."
  }
}

# Case 16: global table replicas are read from db.replicas.regions.
run "global_table_replicas" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      stream     = { enabled = true, view_type = "NEW_AND_OLD_IMAGES" }
      replicas = {
        regions = [
          { region_name = "us-west-2", propagate_tags = true, point_in_time_recovery = true },
          { region_name = "eu-west-1" },
        ]
      }
    }
  }

  assert {
    condition     = length(local.table.replica_regions) == 2
    error_message = "Expected two replica regions."
  }

  assert {
    condition     = toset(keys(module.this.dynamodb_table_replicas)) == toset(["us-west-2", "eu-west-1"])
    error_message = "The planned table must carry a replica block per region."
  }
}

# Case 22: replicas given as a plain list directly under db.replicas (entries with different keys).
run "global_table_replicas_plain_list" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      stream     = { enabled = true, view_type = "NEW_AND_OLD_IMAGES" }
      replicas = [
        { region_name = "us-west-2", propagate_tags = true, kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab" },
        { region_name = "eu-west-1" },
      ]
    }
  }

  assert {
    condition     = length(local.replica_regions) == 2 && local.replica_regions[0].region_name == "us-west-2"
    error_message = "The plain list form of db.replicas was not honored."
  }

  assert {
    condition     = toset(keys(module.this.dynamodb_table_replicas)) == toset(["us-west-2", "eu-west-1"])
    error_message = "The planned table must carry a replica block per region."
  }
}

# Case 23: an empty replicas list means no replicas.
run "replicas_empty_list" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      replicas   = []
    }
  }

  assert {
    condition     = length(local.replica_regions) == 0 && length(module.this.dynamodb_table_replicas) == 0
    error_message = "An empty replicas list must not create replicas."
  }
}

# Case 24: a replicas object without regions means no replicas.
run "replicas_object_without_regions" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      replicas   = {}
    }
  }

  assert {
    condition     = length(local.replica_regions) == 0
    error_message = "A replicas object without regions must not create replicas."
  }
}

# Case 17: global and local secondary indexes, including INCLUDE projections.
run "secondary_indexes" {
  command = plan

  variables {
    db = {
      attributes = [
        { name = "pk", type = "S" },
        { name = "sk", type = "S" },
        { name = "created_at", type = "N" },
        { name = "gsi_pk", type = "S" },
      ]
      hash_key  = "pk"
      range_key = "sk"
      global_secondary_indexes = [
        {
          name               = "by-gsi-pk"
          hash_key           = "gsi_pk"
          range_key          = "created_at"
          projection_type    = "INCLUDE"
          non_key_attributes = ["status", "amount"]
        },
      ]
      local_secondary_indexes = [
        {
          name            = "by-created-at"
          range_key       = "created_at"
          projection_type = "KEYS_ONLY"
        },
      ]
    }
  }

  assert {
    condition     = length(local.table.global_secondary_indexes) == 1 && local.table.global_secondary_indexes[0].projection_type == "INCLUDE"
    error_message = "GSI was not passed through."
  }

  assert {
    condition     = local.table.global_secondary_indexes[0].non_key_attributes == ["status", "amount"]
    error_message = "GSI non_key_attributes were not passed through."
  }

  assert {
    condition     = length(local.table.local_secondary_indexes) == 1 && local.table.local_secondary_indexes[0].range_key == "created_at"
    error_message = "LSI was not passed through."
  }
}

# Case 18: table created from an S3 import.
run "import_table_from_s3" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      import_table = {
        input_format           = "CSV"
        input_compression_type = "GZIP"
        bucket                 = "my-import-bucket"
        key_prefix             = "exports/orders/"
        input_format_options = {
          csv = {
            delimiter   = ";"
            header_list = ["id", "status"]
          }
        }
      }
    }
  }

  assert {
    condition     = local.table.import_table.input_format == "CSV" && local.table.import_table.bucket == "my-import-bucket"
    error_message = "import_table was not passed through."
  }

  assert {
    condition     = local.table.import_table.input_format_options.csv.delimiter == ";"
    error_message = "CSV format options were not passed through."
  }
}

# Case 37: encryption without a key ARN uses the AWS managed key.
run "encryption_with_aws_managed_key" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      encryption = { enabled = true }
    }
  }

  assert {
    condition     = local.table.server_side_encryption_enabled == true && local.table.server_side_encryption_kms_key_arn == null
    error_message = "Encryption without kms_key_arn must leave the key ARN null."
  }
}

# Case 38: PITR without a window leaves the period null (AWS default of 35 days).
run "point_in_time_recovery_default_window" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      recovery   = { enabled = true }
    }
  }

  assert {
    condition     = local.table.point_in_time_recovery_enabled == true && local.table.point_in_time_recovery_period_in_days == null
    error_message = "PITR without period_in_days must leave the period null."
  }
}

# Case 39: replica attributes reach the planned table resource.
run "replica_attributes_reach_table" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      stream     = { enabled = true, view_type = "NEW_AND_OLD_IMAGES" }
      replicas = {
        regions = [
          {
            region_name                 = "us-west-2"
            propagate_tags              = true
            point_in_time_recovery      = true
            deletion_protection_enabled = true
            consistency_mode            = "STRONG"
            kms_key_arn                 = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
          },
        ]
      }
    }
  }

  assert {
    condition = alltrue([
      module.this.dynamodb_table_replicas["us-west-2"].propagate_tags == true,
      module.this.dynamodb_table_replicas["us-west-2"].point_in_time_recovery == true,
      module.this.dynamodb_table_replicas["us-west-2"].deletion_protection_enabled == true,
      module.this.dynamodb_table_replicas["us-west-2"].consistency_mode == "STRONG",
    ])
    error_message = "Replica attributes were not passed to the table resource."
  }

  assert {
    condition     = module.this.dynamodb_table_replicas["us-west-2"].kms_key_arn == "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "Replica KMS key was not passed to the table resource."
  }
}

# Case 40: GSI on-demand and warm throughput settings are passed through.
run "gsi_throughput_settings" {
  command = plan

  variables {
    db = {
      attributes = [
        { name = "id", type = "S" },
        { name = "email", type = "S" },
      ]
      hash_key = "id"
      global_secondary_indexes = [
        {
          name                 = "email-index"
          hash_key             = "email"
          projection_type      = "KEYS_ONLY"
          on_demand_throughput = { max_read_request_units = 100, max_write_request_units = 50 }
          warm_throughput      = { read_units_per_second = 12000, write_units_per_second = 4000 }
        },
      ]
    }
  }

  assert {
    condition     = local.table.global_secondary_indexes[0].on_demand_throughput.max_read_request_units == 100
    error_message = "GSI on_demand_throughput was not passed through."
  }

  assert {
    condition     = local.table.global_secondary_indexes[0].warm_throughput.write_units_per_second == 4000
    error_message = "GSI warm_throughput was not passed through."
  }
}

# Case 41: minimal S3 import with DynamoDB JSON and no format options.
run "import_table_dynamodb_json_minimal" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      import_table = {
        input_format = "DYNAMODB_JSON"
        bucket       = "my-import-bucket"
      }
    }
  }

  assert {
    condition     = local.table.import_table.input_format == "DYNAMODB_JSON" && !can(local.table.import_table.input_format_options)
    error_message = "Minimal import_table must pass through without format options."
  }
}

# Case 42: stream with KEYS_ONLY view type, TTL disabled.
run "stream_keys_only" {
  command = plan

  variables {
    db = {
      attributes = [{ name = "id", type = "S" }]
      hash_key   = "id"
      stream     = { enabled = true, view_type = "KEYS_ONLY" }
    }
  }

  assert {
    condition     = local.table.stream_enabled == true && local.table.stream_view_type == "KEYS_ONLY"
    error_message = "KEYS_ONLY stream was not passed through."
  }

  assert {
    condition     = local.table.ttl_enabled == false && local.table.ttl_attribute_name == null
    error_message = "TTL must stay disabled when not configured."
  }
}
