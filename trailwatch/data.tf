data "aws_cloudwatch_log_group" "cloudtrail" {
  name = var.cloudtrail_log_group_name
}
