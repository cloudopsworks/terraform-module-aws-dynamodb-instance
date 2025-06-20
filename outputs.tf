##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "dynamodb_table_id" {
  value = module.this.dynamodb_table_id
}

output "dynamodb_table_arn" {
  value = module.this.dynamodb_table_arn
}