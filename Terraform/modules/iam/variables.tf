variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM policy"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for Lambda access"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}