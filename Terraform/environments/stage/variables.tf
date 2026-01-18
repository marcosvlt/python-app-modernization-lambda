variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage"
}

variable "bucket_name_input" {
  description = "Name of the input S3 bucket"
  type        = string
  default = "fipe-input-bucket-stage-123456"
}

variable "bucket_name_output" {
  description = "Name of the output S3 bucket"
  type        = string
  default = "fipe-output-bucket-stage-123456"
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
  default     = "v1.0.0"
}