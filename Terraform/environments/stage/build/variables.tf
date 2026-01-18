variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Base name for ECR repositories"
  type        = string
}