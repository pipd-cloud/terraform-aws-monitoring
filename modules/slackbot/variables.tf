# Common Variables
## Required
variable "id" {
  description = "The unique identifier for this deployment."
  type        = string
}

## Optional
variable "aws_tags" {
  description = "Additional AWS tags to apply to resources in this module."
  type        = map(string)
  default     = {}
}

# Module Variables
# Required
variable "events" {
  description = "The events that need to be reported in Slack."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The VPC on which the Canary must run."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The IDs subnets on which the Canary must run."
  type        = list(string)
}


variable "slack_channels" {
  description = "A list of Slack Channel IDs to send notifications to."
  type        = list(string)
}

variable "slack_team" {
  description = "The Slack Workspace ID associated with the slackbot."
  type        = string
}

variable "sns_topic_arns" {
  description = "Additional SNS topics to listen to."
  type        = list(string)
  default     = []
}
