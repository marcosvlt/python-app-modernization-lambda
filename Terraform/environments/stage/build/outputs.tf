
output "ecr_stage_repository_arn" {
  description = "ARN of the stage ECR repository"
  value       = module.ecr_stage.repository_arn
}

output "ecr_stage_repository_name" {
  description = "Name of the stage ECR repository"
  value       = module.ecr_stage.repository_name
}

output "ecr_stage_repository_url" {
  description = "URL of the stage ECR repository"
  value       = module.ecr_stage.repository_url
}