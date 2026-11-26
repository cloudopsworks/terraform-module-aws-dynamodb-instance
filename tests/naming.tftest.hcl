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

# Case 1: name_prefix plus the org/spoke/region system name, hyphens turned into underscores.
run "name_from_prefix_and_system_name" {
  command = plan

  assert {
    condition     = local.table_name == "app_devops_prod_production_001_usea1"
    error_message = "Expected app_devops_prod_production_001_usea1, got ${local.table_name}."
  }
}

# Case 2: an explicit name wins over name_prefix, hyphens still converted.
run "explicit_name_overrides_prefix" {
  command = plan

  variables {
    name = "orders-table"
  }

  assert {
    condition     = local.table_name == "orders_table"
    error_message = "Expected orders_table, got ${local.table_name}."
  }
}

# Case 3: the system name follows the region and spoke of the deployment.
run "name_follows_region_and_spoke" {
  command = plan

  variables {
    spoke_def = "042"
    org = {
      organization_name = "acme"
      organization_unit = "Data"
      environment_type  = "staging"
      environment_name  = "Uat"
    }
  }

  override_data {
    target = data.aws_region.current
    values = { region = "eu-west-1" }
  }

  assert {
    condition     = local.table_name == "app_data_uat_staging_042_euwe1"
    error_message = "Expected app_data_uat_staging_042_euwe1, got ${local.table_name}."
  }
}

# Case 4: extra_tags are merged on top of the organization tags.
run "extra_tags_merged_with_org_tags" {
  command = plan

  variables {
    extra_tags = {
      team        = "payments"
      cost-center = "cc-1234"
    }
  }

  assert {
    condition     = local.all_tags["team"] == "payments" && local.all_tags["cost-center"] == "cc-1234"
    error_message = "extra_tags were not merged into the table tags."
  }

  assert {
    condition     = local.all_tags["organization"] == "acme" && local.all_tags["organization-unit"] == "devops"
    error_message = "Organization tags are missing from the table tags."
  }
}

# Case 5: module outputs expose the table name/ID and ARN.
run "outputs_expose_table_id_and_arn" {
  command = plan

  override_resource {
    target = module.this.aws_dynamodb_table.this
    values = {
      id  = "app_devops_prod_production_001_usea1"
      arn = "arn:aws:dynamodb:us-east-1:123456789012:table/app_devops_prod_production_001_usea1"
    }
  }

  assert {
    condition     = output.dynamodb_table_id == "app_devops_prod_production_001_usea1"
    error_message = "dynamodb_table_id output is not wired to the table ID."
  }

  assert {
    condition     = output.dynamodb_table_arn == "arn:aws:dynamodb:us-east-1:123456789012:table/app_devops_prod_production_001_usea1"
    error_message = "dynamodb_table_arn output is not wired to the table ARN."
  }
}

# Case 21: the scaffolded .boilerplate/inputs.yaml plans as delivered (only required keys uncommented).
run "boilerplate_inputs_yaml_plans" {
  command = plan

  variables {
    name_prefix = yamldecode(file(".boilerplate/inputs.yaml")).name_prefix
    name        = yamldecode(file(".boilerplate/inputs.yaml")).name
    db          = yamldecode(file(".boilerplate/inputs.yaml")).db
  }

  assert {
    condition     = local.table.hash_key == "id" && length(local.table.attributes) == 1
    error_message = "The scaffolded inputs.yaml must define the id hash key."
  }

  assert {
    condition     = local.table.billing_mode == "PAY_PER_REQUEST" && local.table.deletion_protection_enabled == true
    error_message = "The scaffolded inputs.yaml must resolve to on-demand billing with deletion protection."
  }
}

# Case 29: hyphens inside the environment type also become underscores.
run "hyphenated_environment_type" {
  command = plan

  variables {
    org = {
      organization_name = "acme"
      organization_unit = "devops"
      environment_type  = "pre-production"
      environment_name  = "uat"
    }
  }

  assert {
    condition     = local.table_name == "app_devops_uat_pre_production_001_usea1"
    error_message = "Expected app_devops_uat_pre_production_001_usea1, got ${local.table_name}."
  }
}

# Case 30: an explicit name keeps its letter case and underscores.
run "explicit_name_keeps_case" {
  command = plan

  variables {
    name_prefix = ""
    name        = "Orders_V2"
  }

  assert {
    condition     = local.table_name == "Orders_V2"
    error_message = "Expected Orders_V2, got ${local.table_name}."
  }
}

# Case 31: short region code for a three-part region with a longer area name.
run "region_short_code_ap_southeast_2" {
  command = plan

  override_data {
    target = data.aws_region.current
    values = { region = "ap-southeast-2" }
  }

  assert {
    condition     = local.table_name == "app_devops_prod_production_001_apso2"
    error_message = "Expected app_devops_prod_production_001_apso2, got ${local.table_name}."
  }
}

# Case 32: extra_tags win over organization tags with the same key.
run "extra_tags_override_org_tags" {
  command = plan

  variables {
    extra_tags = { organization = "acme-override" }
  }

  assert {
    condition     = local.all_tags["organization"] == "acme-override"
    error_message = "extra_tags must take precedence over organization tags."
  }

  assert {
    condition     = local.all_tags["application-type"] == "production"
    error_message = "Non-conflicting organization tags must be kept."
  }
}

# Case 33: with neither name nor name_prefix, the name starts with an underscore (documented behaviour).
run "empty_name_and_prefix" {
  command = plan

  variables {
    name_prefix = ""
    name        = ""
  }

  assert {
    condition     = local.table_name == "_devops_prod_production_001_usea1"
    error_message = "Expected _devops_prod_production_001_usea1, got ${local.table_name}."
  }
}
