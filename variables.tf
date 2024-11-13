# Common Variables
## Required
variable "id" {
  description = "The unique identifier for this deployment."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to create security groups."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The list of subnet IDs to use for the slackbot lambda functions."
  type        = list(string)
}

variable "s3_access_logs_bucket" {
  description = "The name of the S3 bucket to which S3 access logs will be written."
  type        = string
}

## Optional
variable "aws_tags" {
  description = "Additional AWS tags to apply to resources in this module."
  type        = map(string)
  default     = {}
}

# Module Variables
## TrailWatch
variable "trailwatch" {
  description = "Whether to enable the TrailWatch module."
  type        = bool
  default     = false
}

variable "trailwatch_cloudtrail_log_group_name" {
  description = "The name of the CloudWatch log group storing CloudTrail logs."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = !var.trailwatch || (var.trailwatch && var.trailwatch_cloudtrail_log_group_name != null)
    error_message = "Must specify the CloudTrail log group name if TrailWatch is to be used."
  }
}

variable "trailwatch_alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "trailwatch_alarm_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 1500
}

variable "trailwatch_alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state."
  type        = list(string)
  default     = []
}


## SlackBot
variable "slackbot_team" {
  description = "The unique ID for the Slack Team on which to set up the AWS Chatbot integration."
  type        = string
}

variable "slackbot_channels" {
  description = "The unique ID for the Slack Channels to which to send notifications."
  type        = list(string)
  default     = []
}

variable "slackbot_events" {
  description = "The events to trigger Slack messages for (EventBridge)."
  type        = map(string)
  default     = {}
}

## PageBird
variable "pagebird" {
  description = "Whether to enable the pagebird webpage monitor."
  type        = bool
  default     = false
}

variable "pagebird_website_urls" {
  description = "The list of webpages to monitor with pagebird."
  type        = list(string)
  default     = []
  validation {
    condition     = !var.pagebird || (var.pagebird && length(var.pagebird_website_urls) > 0)
    error_message = "You must provide at least one website URL when using pagebird."
  }
}
