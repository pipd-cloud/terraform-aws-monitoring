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
