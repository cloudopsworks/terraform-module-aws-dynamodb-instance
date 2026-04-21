##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

## DynamoDB configuration as YAML
#db:
#  attributes:
#    - name: "attribute_name1"
#      type: "S" # "S" for String, "N" for Number, "B" for Binary
#    - name: "attribute_name2"
#      type: "S" # "S" for String, "N" for Number, "B" for Binary
#  hash_key: "hash_key_name" # Required
#  range_key: "range_key_name" # (optional) Defaults to null
#  autoscaling:
#     enabled: true | false # (optional) Defaults to false
#     defaults:
#     indexes:
#     read:
#     write:
#  capacity:
#    billing_mode: "PAY_PER_REQUEST" | "PROVISIONED" # defaults to "PAY_PER_REQUEST"
#    write: 0 # (optional) Defaults to 0
#    read: 0 # (optional) Defaults to 0
#  deletion_protection: true | false # (optional) Defaults to false
#  encryption:
#    enabled: true | false # (optional) Defaults to false
#    kms_key_arn: "arn:aws:kms:region:account-id:key/key-id" # (optional) Defaults to null
#  recovery:
#    enabled: true | false # (optional) Defaults to false
#    period_in_days: -1 # (optional) Defaults to -1 (which means no limit)
#  replicas: # (optional) Defaults to []
#    - region_name: "us-west-2"
#      propagate_tags: true | false # (optional) Defaults to false
#      point_in_time_recovery: true | false # (optional) Defaults to false
#      kms_key_arn: "arn:aws:kms:region:account-id:key/key-id" # (optional) Defaults to null
#  stream:
#    enabled: true | false # (optional) Defaults to false
#    view_type: "NEW_IMAGE" | "OLD_IMAGE" | "NEW_AND_OLD_IMAGES" | "KEYS_ONLY" # (optional) Defaults to null
#  table_class: "STANDARD" | "STANDARD_INFREQUENT_ACCESS" # (optional) Defaults to null
#  ttl:
#    enabled: true | false # (optional) Defaults to false
#    attribute_name: "ttl_attribute_name" # (optional) Defaults to null
#  global_secondary_indexes: # (optional) Defaults to []
#    - name: "gsi_name"
#      hash_key: "gsi_hash_key" # Required
#      range_key: "gsi_range_key" # (optional) Defaults to null
#      read_capacity: 0 # (optional) Defaults to 0
#      write_capacity: 0 # (optional) Defaults to 0
#      projection_type: "ALL" | "KEYS_ONLY" | "INCLUDE" # (optional) Defaults to "ALL"
#      non_key_attributes: # (optional) Defaults to []
#        - "attribute_name1"
#        - "attribute_name2"
#      on_demand_throughput:
#        max_read_request_units: 0 # (optional) Defaults to 0
#        max_write_request_units: 0 # (optional) Defaults to 0
#  ignore_changes_global_secondary_index: true | false # (optional) Defaults to false
#  local_secondary_indexes: # (optional) Defaults to []
#    - name: "lsi_name"
#      range_key: "lsi_range_key" # Required
#      projection_type: "ALL" | "KEYS_ONLY" | "INCLUDE" # (optional) Defaults to "ALL"
#      non_key_attributes: # (optional) Defaults to []
#        - "attribute_name1"
#        - "attribute_name2"
#  import_table: # (optional) to import form S3
#    input_type: "CSV" | "DYNAMODB_JSON" | "ION" # (required)
#    input_compression_type: "GZIP" | "BZIP2" | "ZSTD" | "NONE" # (optional) Defaults to "NONE"
#    bucket: "s3-bucket-name" # (required) S3 bucket where the data is stored
#    key_prefix: "s3-prefix" # (optional) Defaults to ""
#    input_format_options:
#      csv:
#        delimiter: "," # (optional) Defaults to ","
#        header_list: # (optional) Defaults to []
variable "db" {
  description = "DynamoDB configuration entry"
  type        = any
  default     = {}
}

variable "name_prefix" {
  description = "Prefix to use for all resources"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name to use for all resources"
  type        = string
  default     = ""
}