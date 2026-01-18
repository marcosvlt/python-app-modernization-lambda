variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name_input" {
  description = "Name of the input S3 bucket"
  type        = string
  default = "fipe-input-bucket-dev-123456"
}

variable "bucket_name_output" {
  description = "Name of the output S3 bucket"
  type        = string
  default = "fipe-output-bucket-dev-123456"
}

variable "aws_id" {
  description = "AWS Account ID"
  type        = string
  default = "026090532917"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "build_version" {
  description = "Version tag for the Lambda Docker image"
  type        = string
  default     = "2025.12.17-205445-220e145"
}