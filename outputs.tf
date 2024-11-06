output "slackbot_sns_topic" {
  description = "The SNS topic associated with the Slack Chatbot."
  value       = var.slackbot ? module.slackbot[0].slackbot_sns_topic : null
}
