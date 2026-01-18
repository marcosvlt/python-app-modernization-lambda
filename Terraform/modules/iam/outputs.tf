output "role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.name
}

output "policy_arn" {
  description = "ARN of the Lambda IAM policy"
  value       = aws_iam_policy.lambda_policy.arn
}