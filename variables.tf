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
  description = "The list of subnet IDs to use for the rockstar lambda functions."
  type        = list(string)
}

variable "s3_access_logs_bucket" {
  description = "The name of the S3 bucket to which S3 access logs will be written."
  type        = string
  nullable    = true
  default     = null
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
  default     = 300
}

variable "trailwatch_alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state."
  type        = list(string)
  default     = []
}



## rockstar
variable "rockstar_team" {
  description = "The unique ID for the Slack Team on which to set up the AWS Chatbot integration."
  type        = string
}

variable "rockstar_channels" {
  description = "The unique ID for the Slack Channels to which to send notifications."
  type        = list(string)
  default     = []
}

variable "rockstar_events" {
  description = "The events to trigger Slack messages for (EventBridge)."
  type        = map(string)
  default     = {}
}

variable "rockstar_topic_arns" {
  description = "Additional SNS topics to listen to."
  type        = list(string)
  default     = []
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

variable "pagebird_frequency" {
  description = "The rate at which pagebird must be run."
  type        = string
  default     = "rate(5 minutes)"
}

variable "pagebird_alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "pagebird_alarm_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 300
}

variable "pagebird_alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state."
  type        = list(string)
  default     = []
}

variable "pagebird_s3_access_logs_bucket" {
  description = "The name of the S3 bucket to which S3 access logs will be written."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = !var.pagebird || (var.pagebird && (var.pagebird_s3_access_logs_bucket != null || var.s3_access_logs_bucket != null))
    error_message = "You must specify a bucket for S3 access logs if using pagebird."
  }
}
