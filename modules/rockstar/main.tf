# EventBridge-Chatbot Notification Transformer
## IAM Role and Policies
resource "aws_iam_role" "event_lambda_role" {
  name_prefix        = "EventLambdaRole_"
  description        = "Role that is assumed by the Event Lambda."
  assume_role_policy = data.aws_iam_policy_document.event_lambda_trust_policy.json
  tags = merge(
    {
      Name = "EventLambdaRole"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_iam_policy" "event_lambda_role_inline_policy" {
  name_prefix = "EventLambdaSNSAccess_"
  description = "Specific permissions that are granted to the EventBridge Lambda function."
  policy      = data.aws_iam_policy_document.event_lambda_inline_policy.json
  tags = merge(
    {
      Name = "EventLambdaSNSAccess"
      TFID = var.id
    },
    var.aws_tags
  )
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
resource "aws_security_group" "event_lambda_sg" {
  name        = "${var.id}-event-lambda-sg"
  description = "The Security Group to associate with the Event Lambda Function."
  vpc_id      = var.vpc_id
  tags = merge(
    {
      Name = "${var.id}-event-lambda-sg"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_vpc_security_group_egress_rule" "event_lambda_sg_full" {
  security_group_id = aws_security_group.event_lambda_sg.id
  description       = "Allow all outbound traffic."
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge(
    {
      Name = "${var.id}-event-lambda-sg-outbound"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_lambda_function" "event_lambda" {
  function_name = "${var.id}-rockstar-event-lambda"
  filename      = data.archive_file.lambda.output_path
  handler       = "lambda.handler"
  runtime       = "python3.10"
  timeout       = 15
  role          = aws_iam_role.event_lambda_role.arn
  tags = merge(
    {
      Name = "${var.id}-rockstar-event-lambda"
      TFID = var.id
    },
    var.aws_tags
  )
  vpc_config {
    security_group_ids = [aws_security_group.event_lambda_sg.id]
    subnet_ids         = var.vpc_subnet_ids
  }
  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.rockstar_topic.arn
    }
  }
}


resource "null_resource" "cleanup" {
  depends_on = [aws_lambda_function.event_lambda]
  triggers = {
    always = timestamp()
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
  tags = merge(
    {
      Name = "${var.id}-${each.key}-event"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_cloudwatch_event_target" "rockstar_lambda_target" {
  for_each = aws_cloudwatch_event_rule.events
  rule     = each.value.id
  arn      = aws_lambda_function.event_lambda.arn
}

## Lambda Execution Policy
resource "aws_lambda_permission" "rockstar_lambda_event_trigger" {
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
## SNS Topics
resource "aws_sns_topic" "rockstar_topic" {
  name = var.id
  tags = merge(
    {
      Name = var.id
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_sns_topic_policy" "rockstar_topic_policy" {
  arn    = aws_sns_topic.rockstar_topic.arn
  policy = data.aws_iam_policy_document.rockstar_topic_policy.json
}


## IAM Role and Policies
resource "aws_iam_role" "rockstar_role" {
  name_prefix        = "ChatbotRole_"
  assume_role_policy = data.aws_iam_policy_document.rockstar_role_trust_policy.json
  tags = merge(
    {
      Name = "ChatbotRole"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_iam_policy" "rockstar_role_inline_policy" {
  name_prefix = "ChatbotReadOnlyAccess_"
  description = "Specific permissions that are granted to the ChatBot assumed role."
  policy      = data.aws_iam_policy_document.rockstar_role_inline_policy.json
  tags = merge(
    {
      Name = "ChatbotReadOnlyAccess"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_iam_role_policy_attachment" "rockstar_managed_policies" {
  for_each   = data.aws_iam_policy.rockstar_role_managed_policies
  policy_arn = each.value.arn
  role       = aws_iam_role.rockstar_role.name
}

resource "aws_iam_role_policy_attachment" "rockstar_inline_policy" {
  policy_arn = aws_iam_policy.rockstar_role_inline_policy.arn
  role       = aws_iam_role.rockstar_role.name
}

## Slack Channel integration
resource "aws_chatbot_slack_channel_configuration" "rockstar_channel" {
  for_each           = toset(var.slack_channels)
  configuration_name = "${var.id}-slack-channel-${each.value}"
  iam_role_arn       = aws_iam_role.rockstar_role.arn
  sns_topic_arns     = concat([aws_sns_topic.rockstar_topic.arn], var.sns_topic_arns)
  slack_team_id      = var.slack_team
  slack_channel_id   = each.value
  logging_level      = "ERROR"
  tags = merge(
    {
      Name = "${var.id}-slack-channel-${each.value}"
      TFID = var.id
    },
    var.aws_tags
  )
}

