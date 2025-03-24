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
# PageBird
variable "website_urls" {
  description = "The URLs of the pages that you need pagebird to monitor."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "The VPC on which the Canary must run."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The IDs subnets on which the Canary must run."
  type        = list(string)
}


variable "s3_access_logs_bucket" {
  description = "The name of the S3 bucket to which S3 access logs will be written."
  type        = string
}

variable "frequency" {
  description = "The rate at which pagebird must be run."
  type        = string
  default     = "rate(5 minutes)"
}

variable "cw_alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 1
}

variable "cw_alarm_period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
  default     = 300
}

variable "cw_alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM/OK state from any other state."
  type        = list(string)
  default     = []
}

variable "clean_up" {
  description = "Whether to clean up the temporary files."
  type        = bool
  default     = false
}
