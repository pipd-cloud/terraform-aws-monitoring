output "slackbot_sns_topic" {
  description = "The SNS topic associated with the Slack Chatbot."
  value       = module.slackbot.slackbot_sns_topic
}
