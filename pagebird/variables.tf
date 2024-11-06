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

# pagebird
variable "website_urls" {
  description = "The URLs of the pages that you need pagebird to monitor."
  type        = list(string)
  default     = []
}
