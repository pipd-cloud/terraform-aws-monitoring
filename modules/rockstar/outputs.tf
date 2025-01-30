output "rockstar_sns_topic" {
  description = "The AWS rockstar SNS topic."
  value       = aws_sns_topic.rockstar_topic
}

output "rockstar_iam_role" {
  description = "The IAM role that AWS rockstar assumes in Slack."
  value       = aws_iam_role.rockstar_role
}
