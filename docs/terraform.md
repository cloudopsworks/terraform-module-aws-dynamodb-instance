## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.74.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.10 |
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/dynamodb-table/aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_db"></a> [db](#input\_db) | (Required) DynamoDB table configuration object: attributes and hash\_key are required, every other key is optional (capacity, autoscaling, encryption, recovery, stream, ttl, replicas, indexes, import\_table). Default: {}. | `any` | `{}` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Explicit table name that overrides name\_prefix. Hyphens become underscores. Default: "". | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | (Optional) Prefix for the generated table name, followed by the org/spoke/region system name; ignored when name is set. Hyphens become underscores. Default: "". | `string` | `""` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | The ARN of the DynamoDB table |
| <a name="output_dynamodb_table_id"></a> [dynamodb\_table\_id](#output\_dynamodb\_table\_id) | The name/ID of the DynamoDB table |
