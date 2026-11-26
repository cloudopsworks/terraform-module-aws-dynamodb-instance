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

# Case 19: spoke_def longer than 3 digits is rejected.
run "rejects_long_spoke_def" {
  command = plan

  variables {
    spoke_def = "0001"
  }

  expect_failures = [var.spoke_def]
}

# Case 20: spoke_def must have exactly 3 characters.
run "rejects_short_spoke_def" {
  command = plan

  variables {
    spoke_def = "01"
  }

  expect_failures = [var.spoke_def]
}
