output "ecr_dev_repository_url" {
  description = "URL of the dev ECR repository"
  value       = module.ecr_dev.repository_url
}

output "ecr_dev_repository_arn" {
  description = "ARN of the dev ECR repository"
  value       = module.ecr_dev.repository_arn
}

output "ecr_dev_repository_name" {
  description = "Name of the dev ECR repository"
  value       = module.ecr_dev.repository_name
}