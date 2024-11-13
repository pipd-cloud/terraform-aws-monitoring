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

# Module variables
## Required
variable "cloudtrail_log_group_name" {
  description = "The name of the CloudWatch log group storing CloudTrail logs."
  type        = string
}

## Optional
variable "cw_alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "cw_alarm_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 1500
}

variable "cw_alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state."
  type        = list(string)
  default     = []
}
