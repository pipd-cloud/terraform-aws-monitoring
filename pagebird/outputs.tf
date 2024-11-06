output "pagebird_bucket" {
  description = "The bucket in which the pagebird artifacts are stored."
  value       = aws_s3_bucket.canary_bucket
}

output "pagebird_role" {
  description = "The IAM role associated with the pagebird Lambda function."
  value       = aws_iam_role.canary_role
}
