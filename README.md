<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_pagebird"></a> [pagebird](#module\_pagebird) | ./modules/pagebird | n/a |
| <a name="module_slackbot"></a> [slackbot](#module\_slackbot) | ./modules/slackbot | n/a |
| <a name="module_trailwatch"></a> [trailwatch](#module\_trailwatch) | ./modules/trailwatch | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_tags"></a> [aws\_tags](#input\_aws\_tags) | Additional AWS tags to apply to resources in this module. | `map(string)` | `{}` | no |
| <a name="input_id"></a> [id](#input\_id) | The unique identifier for this deployment. | `string` | n/a | yes |
| <a name="input_pagebird"></a> [pagebird](#input\_pagebird) | Whether to enable the pagebird webpage monitor. | `bool` | `false` | no |
| <a name="input_pagebird_alarm_actions"></a> [pagebird\_alarm\_actions](#input\_pagebird\_alarm\_actions) | The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state. | `list(string)` | `[]` | no |
| <a name="input_pagebird_alarm_evaluation_periods"></a> [pagebird\_alarm\_evaluation\_periods](#input\_pagebird\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold. | `number` | `1` | no |
| <a name="input_pagebird_alarm_period"></a> [pagebird\_alarm\_period](#input\_pagebird\_alarm\_period) | The period in seconds over which the specified statistic is applied. | `number` | `300` | no |
| <a name="input_pagebird_frequency"></a> [pagebird\_frequency](#input\_pagebird\_frequency) | The rate at which pagebird must be run. | `string` | `"rate(5 minutes)"` | no |
| <a name="input_pagebird_website_urls"></a> [pagebird\_website\_urls](#input\_pagebird\_website\_urls) | The list of webpages to monitor with pagebird. | `list(string)` | `[]` | no |
| <a name="input_s3_access_logs_bucket"></a> [s3\_access\_logs\_bucket](#input\_s3\_access\_logs\_bucket) | The name of the S3 bucket to which S3 access logs will be written. | `string` | n/a | yes |
| <a name="input_slackbot_channels"></a> [slackbot\_channels](#input\_slackbot\_channels) | The unique ID for the Slack Channels to which to send notifications. | `list(string)` | `[]` | no |
| <a name="input_slackbot_events"></a> [slackbot\_events](#input\_slackbot\_events) | The events to trigger Slack messages for (EventBridge). | `map(string)` | `{}` | no |
| <a name="input_slackbot_team"></a> [slackbot\_team](#input\_slackbot\_team) | The unique ID for the Slack Team on which to set up the AWS Chatbot integration. | `string` | n/a | yes |
| <a name="input_slackbot_topic_arns"></a> [slackbot\_topic\_arns](#input\_slackbot\_topic\_arns) | Additional SNS topics to listen to. | `list(string)` | `[]` | no |
| <a name="input_trailwatch"></a> [trailwatch](#input\_trailwatch) | Whether to enable the TrailWatch module. | `bool` | `false` | no |
| <a name="input_trailwatch_alarm_actions"></a> [trailwatch\_alarm\_actions](#input\_trailwatch\_alarm\_actions) | The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state. | `list(string)` | `[]` | no |
| <a name="input_trailwatch_alarm_evaluation_periods"></a> [trailwatch\_alarm\_evaluation\_periods](#input\_trailwatch\_alarm\_evaluation\_periods) | The number of periods over which data is compared to the specified threshold. | `number` | `1` | no |
| <a name="input_trailwatch_alarm_period"></a> [trailwatch\_alarm\_period](#input\_trailwatch\_alarm\_period) | The period in seconds over which the specified statistic is applied. | `number` | `300` | no |
| <a name="input_trailwatch_cloudtrail_log_group_name"></a> [trailwatch\_cloudtrail\_log\_group\_name](#input\_trailwatch\_cloudtrail\_log\_group\_name) | The name of the CloudWatch log group storing CloudTrail logs. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID to create security groups. | `string` | n/a | yes |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | The list of subnet IDs to use for the slackbot lambda functions. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_slackbot_sns_topic"></a> [slackbot\_sns\_topic](#output\_slackbot\_sns\_topic) | The SNS topic associated with the Slack Chatbot. |
<!-- END_TF_DOCS -->