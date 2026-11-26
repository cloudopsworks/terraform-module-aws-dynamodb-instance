##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

## DynamoDB table configuration. Only attributes and hash_key are required;
# keys left commented use the module defaults.
#
# db:                             # (Required) DynamoDB table configuration object. Default: {}.
#
##   Attribute definitions. Declare only the attributes used as a table key or as an index key.
#
#   attributes:                   # (Required) List of key attribute definitions.
#     - name: "id"                # (Required) Attribute name.
#       type: "S"                 # (Required) Attribute type: S (String) | N (Number) | B (Binary).
#   hash_key: "id"                # (Required) Partition key. Must be declared in attributes.
#   range_key: "sk"               # (Optional) Sort key. Must be declared in attributes. Default: null (no sort key).
#   table_class: "STANDARD"       # (Optional) Storage class: STANDARD | STANDARD_INFREQUENT_ACCESS. Default: null (AWS uses STANDARD).
#   deletion_protection: true     # (Optional) Block table deletion through the API. Default: true.
#
##   Billing mode and table capacity. read and write are used only with PROVISIONED billing;
#   with autoscaling enabled they are also the minimum capacity of the table.
#
#   capacity:                     # (Optional) Capacity settings. Default: on-demand billing.
#     billing_mode: "PAY_PER_REQUEST"  # (Optional) Billing mode: PAY_PER_REQUEST | PROVISIONED. Default: PAY_PER_REQUEST.
#     read: 5                     # (Optional) Provisioned read capacity units. Default: 0.
#     write: 5                    # (Optional) Provisioned write capacity units. Default: 0.
#
##   Application Auto Scaling for PROVISIONED tables and their GSIs.
#   The defaults map is merged with scale_in_cooldown 0, scale_out_cooldown 0 and target_value 70,
#   so set only the keys you want to change.
#
#   autoscaling:                  # (Optional) Autoscaling settings. Default: disabled.
#     enabled: false              # (Optional) Enable autoscaling. Requires billing_mode PROVISIONED. Default: false.
#     defaults:                   # (Optional) Default policy values for read, write and indexes. Default: {}.
#       scale_in_cooldown: 0      # (Optional) Seconds between scale-in activities. Default: 0.
#       scale_out_cooldown: 0     # (Optional) Seconds between scale-out activities. Default: 0.
#       target_value: 70          # (Optional) Target utilization percentage. Default: 70.
#     read:                       # (Optional) Table read scaling. Omit to skip read scaling. Default: {}.
#       max_capacity: 100         # (Required) Maximum read capacity. The minimum is capacity.read.
#       target_value: 70          # (Optional) Overrides defaults.target_value.
#     write:                      # (Optional) Table write scaling. Omit to skip write scaling. Default: {}.
#       max_capacity: 100         # (Required) Maximum write capacity. The minimum is capacity.write.
#       target_value: 70          # (Optional) Overrides defaults.target_value.
#
##     Per-index scaling, keyed by GSI name. Each entry also accepts
#     scale_in_cooldown, scale_out_cooldown and target_value.
#
#     indexes:                    # (Optional) Map of GSI name to scaling limits. Default: {}.
#       email-index:              # (Optional) GSI name, as declared in global_secondary_indexes.
#         read_min_capacity: 5    # (Required) Minimum read capacity of the index.
#         read_max_capacity: 50   # (Required) Maximum read capacity of the index.
#         write_min_capacity: 5   # (Required) Minimum write capacity of the index.
#         write_max_capacity: 50  # (Required) Maximum write capacity of the index.
#   encryption:                   # (Optional) Server-side encryption settings. Default: AWS owned key.
#     enabled: true               # (Optional) Use a KMS key (AWS managed or customer managed). Default: false.
#     kms_key_arn: "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"  # (Optional) Customer managed key ARN. Default: null (alias/aws/dynamodb).
#   recovery:                     # (Optional) Point-in-time recovery settings. Default: disabled.
#     enabled: true               # (Optional) Enable point-in-time recovery. Default: false.
#     period_in_days: 35          # (Optional) Recovery window, 1 to 35 days. Default: null (AWS uses 35).
#   stream:                       # (Optional) DynamoDB Streams settings. Default: disabled.
#     enabled: true               # (Optional) Enable the stream. Required for replicas. Default: false.
#     view_type: "NEW_AND_OLD_IMAGES"  # (Optional) KEYS_ONLY | NEW_IMAGE | OLD_IMAGE | NEW_AND_OLD_IMAGES. Default: null.
#   ttl:                          # (Optional) Time to live settings. Default: disabled.
#     enabled: true               # (Optional) Enable TTL. Default: false.
#     attribute_name: "expires_at"  # (Optional) Attribute holding the expiry time in epoch seconds. Default: null.
#
##   Global table replicas (version 2019.11.21). Put the list under the regions key,
#   or directly under replicas as a plain list (both forms are equivalent).
#   The stream must be enabled with view_type NEW_AND_OLD_IMAGES.
#
#   replicas:                     # (Optional) Replica settings. Default: no replicas.
#     regions:                    # (Optional) List of replica regions. Default: [].
#       - region_name: "us-west-2"  # (Required) AWS region of the replica.
#         propagate_tags: true    # (Optional) Copy the table tags to the replica. Default: null (false).
#         point_in_time_recovery: true  # (Optional) Enable PITR on the replica. Default: null (false).
#         deletion_protection_enabled: true  # (Optional) Deletion protection on the replica. Default: null (false).
#         kms_key_arn: "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"  # (Optional) KMS key in the replica region. Default: null.
#         consistency_mode: "EVENTUAL"  # (Optional) EVENTUAL | STRONG (multi-Region strong consistency). Default: null (EVENTUAL).
#
##   Global secondary indexes. Every key used by an index must be declared in attributes.
#
#   global_secondary_indexes:     # (Optional) List of GSI definitions. Default: [].
#     - name: "email-index"       # (Required) Index name.
#       hash_key: "email"         # (Required) Partition key of the index.
#       range_key: "created_at"   # (Optional) Sort key of the index. Default: null.
#       projection_type: "INCLUDE"  # (Required) ALL | KEYS_ONLY | INCLUDE.
#       non_key_attributes:       # (Optional) Projected attributes, only with INCLUDE. Default: null.
#         - "status"
#       read_capacity: 5          # (Optional) Read capacity, PROVISIONED billing only. Default: null.
#       write_capacity: 5         # (Optional) Write capacity, PROVISIONED billing only. Default: null.
#       on_demand_throughput:     # (Optional) Request unit caps, PAY_PER_REQUEST billing only. Default: none.
#         max_read_request_units: 100   # (Optional) Maximum read request units. Default: null.
#         max_write_request_units: 100  # (Optional) Maximum write request units. Default: null.
#       warm_throughput:          # (Optional) Pre-warmed throughput of the index. Default: none.
#         read_units_per_second: 12000  # (Optional) Warm read units per second. Default: null.
#         write_units_per_second: 4000  # (Optional) Warm write units per second. Default: null.
#   ignore_changes_global_secondary_index: false  # (Optional) Ignore GSI drift, useful with autoscaled GSIs. Default: false.
#
##   Local secondary indexes. They can only be created with the table and share its hash key.
#
#   local_secondary_indexes:      # (Optional) List of LSI definitions. Default: [].
#     - name: "created-at-index"  # (Required) Index name.
#       range_key: "created_at"   # (Required) Sort key of the index.
#       projection_type: "KEYS_ONLY"  # (Required) ALL | KEYS_ONLY | INCLUDE.
#       non_key_attributes: []    # (Optional) Projected attributes, only with INCLUDE. Default: null.
#
##   Create the table from an S3 import. Applies only when the table is created;
#   later changes to this block replace the table.
#
#   import_table:                 # (Optional) S3 import settings. Default: {} (no import).
#     input_format: "CSV"         # (Required) CSV | DYNAMODB_JSON | ION.
#     input_compression_type: "NONE"  # (Optional) GZIP | ZSTD | NONE. Default: null (NONE).
#     bucket: "my-import-bucket"  # (Required) S3 bucket holding the source data.
#     bucket_owner: "123456789012"  # (Optional) Account ID of the bucket owner. Default: null.
#     key_prefix: "exports/orders/"  # (Optional) Key prefix of the source objects. Default: null.
#     input_format_options:       # (Optional) Format options, CSV only. Default: none.
#       csv:                      # (Optional) CSV options.
#         delimiter: ","          # (Optional) Field delimiter. Default: null (comma).
#         header_list:            # (Optional) Column names when the files have no header row. Default: null.
#           - "id"
#           - "status"
variable "db" {
  description = "(Required) DynamoDB table configuration object: attributes and hash_key are required, every other key is optional (capacity, autoscaling, encryption, recovery, stream, ttl, replicas, indexes, import_table). Default: {}."
  type        = any
  default     = {}
}

## Table naming. The table name is the explicit name when set, otherwise
# the name_prefix followed by the organization unit, environment name, environment type,
# spoke and short region code (for example myapp-devops-prod-production-001-usea1).
# Hyphens are converted to underscores in both cases (myapp_devops_prod_production_001_usea1).
# Set at least one of the two keys.
#
# name_prefix: ""                 # (Optional) Prefix for the generated table name. Ignored when name is set. Default: "".
variable "name_prefix" {
  description = "(Optional) Prefix for the generated table name, followed by the org/spoke/region system name; ignored when name is set. Hyphens become underscores. Default: \"\"."
  type        = string
  default     = ""
}

# name: ""                        # (Optional) Explicit table name, overrides name_prefix. Hyphens become underscores. Default: "".
variable "name" {
  description = "(Optional) Explicit table name that overrides name_prefix. Hyphens become underscores. Default: \"\"."
  type        = string
  default     = ""
}
