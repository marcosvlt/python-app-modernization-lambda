output "input_bucket_name" {
  description = "Name of the input S3 bucket"
  value       = module.input_bucket.bucket_name
}

output "output_bucket_name" {
  description = "Name of the output S3 bucket"
  value       = module.output_bucket.bucket_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.fipe_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.fipe_lambda.function_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.lambda_iam.role_arn
}