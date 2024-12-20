data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_s3_bucket" "s3_access_logs_bucket" {
  bucket = var.s3_access_logs_bucket
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/${filesha1("${path.module}/lambda/python/lambda.py")}.zip"
}

data "aws_iam_policy_document" "canary_role_trust_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "canary_role_inline_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetOject"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.canary_bucket.arn}/*"]
  }
  statement {
    actions = [
      "s3:GetBucketLocation"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.canary_bucket.arn]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group/aws/lambda/cwsyn-*"
    ]
  }
  statement {
    actions = [
      "s3:ListAllMyBuckets",
      "xray:PutTraceSegments"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "cloudwatch:PutMetricData"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
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
}

