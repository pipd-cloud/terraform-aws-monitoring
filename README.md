<p align="center">
  <a href="https://github.com/terraform-trailwatch-modules" title="Terraform Trailwatch Modules"><img src="https://raw.githubusercontent.com/terraform-trailwatch-modules/art/refs/heads/main/logo.jpg" height="100" alt="Terraform Trailwatch Modules"></a>
</p>

<h1 align="center">Module Name</h1>

<p align="center">
  <a href="https://github.com/terraform-trailwatch-modules/module_name/releases" title="Releases"><img src="https://img.shields.io/badge/Release-1.0.0-1d1d1d?style=for-the-badge" alt="Releases"></a>
  <a href="https://github.com/terraform-trailwatch-modules/module_name/blob/main/LICENSE" title="License"><img src="https://img.shields.io/badge/License-MIT-1d1d1d?style=for-the-badge" alt="License"></a>
</p>

## About
Add information about your module here.

## Features
 - Add your feature list here


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.74.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_pagebird"></a> [pagebird](#module\_pagebird) | ./pagebird | n/a |
| <a name="module_slackbot"></a> [slackbot](#module\_slackbot) | ./slackbot | n/a |
| <a name="module_trailwatch"></a> [trailwatch](#module\_trailwatch) | ./trailwatch | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_rds_cluster.aurora_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.aurora_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_db_snapshot.aurora_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_snapshot) | data source |
| [aws_db_subnet_group.aurora_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_subnet_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | Additional AWS tags to apply to resources in this module. | `map(string)` | `{}` | no |
| <a name="input_db_cluster_instance_count"></a> [db\_cluster\_instance\_count](#input\_db\_cluster\_instance\_count) | n/a | `number` | `2` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | n/a | `string` | `null` | no |
| <a name="input_db_snapshot_identifier"></a> [db\_snapshot\_identifier](#input\_db\_snapshot\_identifier) | Dev | `string` | `null` | no |
| <a name="input_id"></a> [id](#input\_id) | The unique identifier for this deployment. | `string` | n/a | yes |
| <a name="input_pagebird"></a> [pagebird](#input\_pagebird) | Whether to enable the pagebird webpage monitor. | `bool` | `false` | no |
| <a name="input_pagebird_website_urls"></a> [pagebird\_website\_urls](#input\_pagebird\_website\_urls) | The list of webpages to monitor with pagebird. | `list(string)` | `[]` | no |
| <a name="input_slackbot"></a> [slackbot](#input\_slackbot) | Whether to enable the slackbot (+EventBridge) module. | `bool` | `false` | no |
| <a name="input_slackbot_channels"></a> [slackbot\_channels](#input\_slackbot\_channels) | The unique ID for the Slack Channels to which to send notifications. | `list(string)` | `[]` | no |
| <a name="input_slackbot_events"></a> [slackbot\_events](#input\_slackbot\_events) | The events to trigger Slack messages for (EventBridge). | `map(string)` | `{}` | no |
| <a name="input_slackbot_team"></a> [slackbot\_team](#input\_slackbot\_team) | The unique ID for the Slack Team on which to set up the AWS Chatbot integration. | `string` | `null` | no |
| <a name="input_trailwatch"></a> [trailwatch](#input\_trailwatch) | Whether to enable the TrailWatch module. | `bool` | `false` | no |
| <a name="input_trailwatch_alarm_actions"></a> [trailwatch\_alarm\_actions](#input\_trailwatch\_alarm\_actions) | The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state. | `list(string)` | `[]` | no |
| <a name="input_trailwatch_alarm_evaluation_periods"></a> [trailwatch\_alarm\_evaluation\_periods](#input\_trailwatch\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold. | `number` | `1` | no |
| <a name="input_trailwatch_alarm_period"></a> [trailwatch\_alarm\_period](#input\_trailwatch\_alarm\_period) | The period in seconds over which the specified statistic is applied. | `number` | `1500` | no |
| <a name="input_trailwatch_cloudtrail_log_group_name"></a> [trailwatch\_cloudtrail\_log\_group\_name](#input\_trailwatch\_cloudtrail\_log\_group\_name) | The name of the CloudWatch log group storing CloudTrail logs. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_slackbot_sns_topic"></a> [slackbot\_sns\_topic](#output\_slackbot\_sns\_topic) | The SNS topic associated with the Slack Chatbot. |
<!-- END_TF_DOCS -->

## Simple Example
```hcl
module "terraform_trailwatch_efs" {
  source = "terraform-trailwatch-modules/module_name/aws"
  ...
}
```

## Advanced Example
```hcl
module "terraform_trailwatch_efs" {
  source = "terraform-trailwatch-modules/module_name/aws"
  ...
}
```

## Changelog
For a detailed list of changes, please refer to the [CHANGELOG.md](CHANGELOG.md).

## License
This module is licensed under the [MIT License](LICENSE).
