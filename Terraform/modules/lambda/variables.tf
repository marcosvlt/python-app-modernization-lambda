variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for Lambda"
  type        = string
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 900
}

variable "image_uri" {
  description = "URI of the container image"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket that triggers the Lambda"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket that triggers the Lambda"
  type        = string
}

variable "trigger_events" {
  description = "S3 events that trigger the Lambda"
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
}

variable "filter_prefix" {
  description = "S3 object key prefix filter"
  type        = string
  default     = ""
}

variable "filter_suffix" {
  description = "S3 object key suffix filter"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to Lambda resources"
  type        = map(string)
  default     = {}
}

variable "build_version" {
  description = "Version tag for the Lambda Docker image"
  type        = string
  default     = "v1.0.0"
}