module "ecr_dev" {
  source = "../../../modules/ecr"

  repository_name      = "${var.repository_name}-dev"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  scan_on_push         = false

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 dev images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["lambda-fipe-dev"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "FIPE-Processor"
  }
}