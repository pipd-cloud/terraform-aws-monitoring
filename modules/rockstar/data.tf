locals {
  lambda_sha1 = filesha1("${path.module}/lambda/lambda.py")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/${local.lambda_sha1}.zip"
}

data "aws_iam_policy_document" "rockstar_topic_policy" {
  statement {
    sid = "Default"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.rockstar_topic.arn
    ]

  }
  statement {
    sid = "Services"
    principals {
      type = "Service"
      identifiers = [
        "costalerts.amazonaws.com",
        "cloudwatch.amazonaws.com",
        "budgets.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
    actions = ["sns:Publish"]
    effect  = "Allow"
    resources = [
      aws_sns_topic.rockstar_topic.arn
    ]
  }
}

data "aws_iam_policy_document" "rockstar_role_trust_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy" "rockstar_role_managed_policies" {
  for_each = toset([
    "ReadOnlyAccess"
  ])
  name = each.value
}

data "aws_iam_policy_document" "rockstar_role_inline_policy" {
  statement {
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "event_lambda_trust_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy" "event_lambda_managed_policies" {
  for_each = toset([
    "AWSLambdaBasicExecutionRole"
  ])
  name = each.value
}

data "aws_iam_policy_document" "event_lambda_inline_policy" {
  statement {
    actions = [
      "sns:Publish"
    ]
    effect    = "Allow"
    resources = [aws_sns_topic.rockstar_topic.arn]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:CreateTags"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "bedrock:InvokeModel"
    ]
    effect    = "Allow"
    resources = ["arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-micro*"]
  }
}
