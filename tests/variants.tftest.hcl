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

# The upstream module creates one of three aws_dynamodb_table resources. Each run overrides only the
# expected variant: if another variant were planned, the outputs would stay unknown and the run would fail.

# Case 25: no autoscaling selects the standard table resource.
run "standard_table_variant" {
  command = plan

  override_resource {
    target = module.this.aws_dynamodb_table.this
    values = { id = "app_table", arn = "arn:aws:dynamodb:us-east-1:123456789012:table/app_table" }
  }

  assert {
    condition     = output.dynamodb_table_arn == "arn:aws:dynamodb:us-east-1:123456789012:table/app_table"
    error_message = "Expected the standard aws_dynamodb_table.this variant."
  }
}

# Case 26: autoscaling selects the autoscaled table resource.
run "autoscaled_table_variant" {
  command = plan

  variables {
    db = {
      attributes  = [{ name = "id", type = "S" }]
      hash_key    = "id"
      capacity    = { billing_mode = "PROVISIONED", read = 5, write = 5 }
      autoscaling = { enabled = true, read = { max_capacity = 50 }, write = { max_capacity = 50 } }
    }
  }

  override_resource {
    target = module.this.aws_dynamodb_table.autoscaled
    values = { id = "app_table", arn = "arn:aws:dynamodb:us-east-1:123456789012:table/app_table" }
  }

  assert {
    condition     = output.dynamodb_table_id == "app_table"
    error_message = "Expected the aws_dynamodb_table.autoscaled variant."
  }
}

# Case 27: autoscaling plus ignore_changes_global_secondary_index selects the GSI-ignoring resource.
run "autoscaled_gsi_ignore_variant" {
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
        { name = "email-index", hash_key = "email", projection_type = "ALL", read_capacity = 5, write_capacity = 5 },
      ]
      ignore_changes_global_secondary_index = true
      autoscaling = {
        enabled = true
        read    = { max_capacity = 50 }
        write   = { max_capacity = 50 }
        indexes = { "email-index" = { read_min_capacity = 5, read_max_capacity = 50, write_min_capacity = 5, write_max_capacity = 50 } }
      }
    }
  }

  override_resource {
    target = module.this.aws_dynamodb_table.autoscaled_gsi_ignore
    values = { id = "app_table", arn = "arn:aws:dynamodb:us-east-1:123456789012:table/app_table" }
  }

  assert {
    condition     = output.dynamodb_table_id == "app_table"
    error_message = "Expected the aws_dynamodb_table.autoscaled_gsi_ignore variant."
  }
}

# Case 28: ignore_changes_global_secondary_index without autoscaling keeps the standard resource.
run "ignore_gsi_without_autoscaling_keeps_standard_variant" {
  command = plan

  variables {
    db = {
      attributes                            = [{ name = "id", type = "S" }]
      hash_key                              = "id"
      ignore_changes_global_secondary_index = true
    }
  }

  override_resource {
    target = module.this.aws_dynamodb_table.this
    values = { id = "app_table", arn = "arn:aws:dynamodb:us-east-1:123456789012:table/app_table" }
  }

  assert {
    condition     = output.dynamodb_table_id == "app_table"
    error_message = "Expected the standard aws_dynamodb_table.this variant."
  }
}
