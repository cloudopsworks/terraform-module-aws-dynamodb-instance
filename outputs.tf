##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "dynamodb_table_id" {
  value = module.this.dynamodb_table_id
}

output "dynamodb_table_arn" {
  value = module.this.dynamodb_table_arn
}