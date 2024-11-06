# EventBridge-Chatbot Notification Transformer
## IAM Role and Policies
resource "aws_iam_role" "event_lambda_role" {
  name               = "${var.id}-event-lambda-role"
  description        = "Role that is assumed by the Event Lambda."
  assume_role_policy = data.aws_iam_policy_document.event_lambda_trust_policy.json
  tags               = var.aws_tags
}

resource "aws_iam_policy" "event_lambda_role_inline_policy" {
  name        = "${var.id}-event-lambda-inline-policy"
  description = "Specific permissions that are granted to the EventBridge Lambda function."
  policy      = data.aws_iam_policy_document.event_lambda_inline_policy.json
  tags        = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "event_lambda_role_managed_policies" {
  for_each   = data.aws_iam_policy.event_lambda_managed_policies
  policy_arn = each.value.arn
  role       = aws_iam_role.event_lambda_role.name
}

resource "aws_iam_role_policy_attachment" "event_lambda_role_inline_policy" {
  policy_arn = aws_iam_policy.event_lambda_role_inline_policy.arn
  role       = aws_iam_role.event_lambda_role.name
}

## Lambda Function
resource "aws_lambda_function" "event_lambda" {
  function_name = "${var.id}-slackbot-event-lambda"
  filename      = data.archive_file.lambda.output_path
  handler       = "lambda.handler"
  runtime       = "python3.10"
  role          = aws_iam_role.event_lambda_role.arn
  tags          = var.aws_tags
  environment {
    variables = {
      "TOPIC_ARN" = aws_sns_topic.slackbot_topic.arn
    }
  }
}

resource "null_resource" "cleanup" {
  depends_on = [aws_lambda_function.event_lambda]
  triggers = {
    "always" = timestamp()
  }
  provisioner "local-exec" {
    command = "rm ${data.archive_file.lambda.output_path}"
  }
}

## Event Patterns
resource "aws_cloudwatch_event_rule" "events" {
  for_each      = var.events
  name          = "${var.id}-${each.key}-event"
  event_pattern = each.value
  tags          = var.aws_tags
}

resource "aws_cloudwatch_event_target" "slackbot_lambda_target" {
  for_each = aws_cloudwatch_event_rule.events
  rule     = each.value.id
  arn      = aws_lambda_function.event_lambda.arn
}

## Lambda Execution Policy
resource "aws_lambda_permission" "slackbot_lambda_event_trigger" {
  for_each      = aws_cloudwatch_event_rule.events
  statement_id  = "Access_${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = each.value.arn
  lifecycle {
    replace_triggered_by = [aws_lambda_function.event_lambda]
  }
}

# Chatbot
## SNS Topic
resource "aws_sns_topic" "slackbot_topic" {
  name = var.id
  tags = var.aws_tags
}

resource "aws_sns_topic_policy" "slackbot_topic_policy" {
  arn    = aws_sns_topic.slackbot_topic.arn
  policy = data.aws_iam_policy_document.slackbot_topic_policy.json
}


## IAM Role and Policies
resource "aws_iam_role" "slackbot_role" {
  name               = "${var.id}-slackbot-role"
  assume_role_policy = data.aws_iam_policy_document.slackbot_role_trust_policy.json
  tags               = var.aws_tags
}

resource "aws_iam_policy" "slackbot_role_inline_policy" {
  name        = "${var.id}-slackbot-inline-policy"
  description = "Specific permissions that are granted to the slackbot assumed role."
  policy      = data.aws_iam_policy_document.slackbot_role_inline_policy.json
  tags        = var.aws_tags
}

resource "aws_iam_role_policy_attachment" "slackbot_managed_policies" {
  for_each   = data.aws_iam_policy.slackbot_role_managed_policies
  policy_arn = each.value.arn
  role       = aws_iam_role.slackbot_role.name
}

resource "aws_iam_role_policy_attachment" "slackbot_inline_policy" {
  policy_arn = aws_iam_policy.slackbot_role_inline_policy.arn
  role       = aws_iam_role.slackbot_role.name
}

## Slack Channel integration
resource "aws_chatbot_slack_channel_configuration" "slackbot_channel" {
  for_each           = toset(var.slack_channels)
  configuration_name = "${var.id}-slack-channel-${each.value}"
  iam_role_arn       = aws_iam_role.slackbot_role.arn
  sns_topic_arns     = [aws_sns_topic.slackbot_topic.arn]
  slack_team_id      = var.slack_team
  slack_channel_id   = each.value
  logging_level      = "ERROR"
  tags               = var.aws_tags
}

