resource "aws_s3_bucket" "canary_bucket" {
  bucket_prefix = "${var.id}-pagebird-"
  force_destroy = true
  tags = merge(
    {
      Name = "${var.id}-pagebird"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_s3_bucket_logging" "canary_bucket_logging" {
  bucket        = aws_s3_bucket.canary_bucket.id
  target_bucket = data.aws_s3_bucket.s3_access_logs_bucket.id
  target_prefix = aws_s3_bucket.canary_bucket.id
}

resource "aws_s3_bucket_versioning" "canary_bucket_versioning" {
  bucket = aws_s3_bucket.canary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "canary_bucket_lifecycle" {
  bucket = aws_s3_bucket.canary_bucket.id
  rule {
    id = "stale-data"
    filter {}
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    status = "Enabled"
  }
}

resource "aws_s3_object" "canary_script_object" {
  source = data.archive_file.lambda.output_path
  bucket = aws_s3_bucket.canary_bucket.id
  key    = "lambda.zip"
  tags = merge(
    {
      Name = "${var.id}-pagebird-src"
      TFID = var.id
    },
    var.aws_tags
  )
}


resource "aws_iam_policy" "canary_role_inline_policy" {
  name_prefix = "CanaryLambdaAccess_"
  policy      = data.aws_iam_policy_document.canary_role_inline_policy.json
  description = "Specific permissions that are granted to the Synthetics Canary Lambda function."
  tags = merge(
    {
      Name = "CanaryLambdaAccess"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_iam_role" "canary_role" {
  name_prefix        = "CanaryRole_"
  description        = "IAM rule that is used by CloudWatch Synthetics Canaries"
  assume_role_policy = data.aws_iam_policy_document.canary_role_trust_policy.json
  tags = merge(
    {
      Name = "CanaryRole"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_iam_role_policy_attachment" "canary_role_inline_policy" {
  policy_arn = aws_iam_policy.canary_role_inline_policy.arn
  role       = aws_iam_role.canary_role.name
}

resource "aws_security_group" "canary_sg" {
  name        = "${var.id}-canary-sg"
  description = "The Security Group to associate with the Lambda Function."
  vpc_id      = var.vpc_id
  tags = merge(
    {
      Name = "${var.id}-canary-sg"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_vpc_security_group_egress_rule" "canary_sg_full" {
  security_group_id = aws_security_group.canary_sg.id
  description       = "Allow all outbound traffic."
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge(
    {
      Name = "${var.id}-canary-sg-outbound"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_synthetics_canary" "canary" {
  name                     = "${var.id}-pagebird"
  artifact_s3_location     = "s3://${aws_s3_bucket.canary_bucket.id}"
  runtime_version          = "syn-python-selenium-4.1"
  execution_role_arn       = aws_iam_role.canary_role.arn
  s3_bucket                = aws_s3_bucket.canary_bucket.id
  s3_key                   = aws_s3_object.canary_script_object.key
  s3_version               = aws_s3_object.canary_script_object.version_id
  start_canary             = true
  handler                  = "lambda.handler"
  delete_lambda            = true
  success_retention_period = 30
  failure_retention_period = 30
  tags = merge(
    {
      Name = "${var.id}-pagebird"
      TFID = var.id
    },
    var.aws_tags
  )

  vpc_config {
    security_group_ids = aws_security_group.canary_sg.id
    subnet_ids         = var.vpc_subnet_ids
  }

  schedule {
    expression = "rate(1 minute)"
  }
  run_config {
    environment_variables = {
      WEBSITE_URLS = jsonencode(var.website_urls)
    }
  }
}

resource "null_resource" "cleanup" {
  depends_on = [aws_s3_object.canary_script_object]
  triggers = {
    always = timestamp()
  }
  provisioner "local-exec" {
    command = "rm -rf ${data.archive_file.lambda.output_path}"
  }
}
