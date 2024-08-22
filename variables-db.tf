##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

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