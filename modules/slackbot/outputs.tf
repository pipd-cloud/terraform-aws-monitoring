output "slackbot_sns_topic" {
  description = "The AWS slackbot SNS topic."
  value       = aws_sns_topic.slackbot_topic
}

output "slackbot_iam_role" {
  description = "The IAM role that AWS slackbot assumes in Slack."
  value       = aws_iam_role.slackbot_role
}
