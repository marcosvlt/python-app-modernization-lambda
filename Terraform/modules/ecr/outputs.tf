output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.repository.arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.repository.name
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.repository.registry_id
}