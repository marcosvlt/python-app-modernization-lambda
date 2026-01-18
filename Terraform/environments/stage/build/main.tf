module "ecr_stage" {
  source = "../../../modules/ecr"

  repository_name      = "${var.repository_name}-stage"
  force_delete         = false
  image_tag_mutability = "MUTABLE"
  scan_on_push         = false

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 stage images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["lambda-fipe-stage"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "stage"
    ManagedBy   = "Terraform"
    Project     = "FIPE-Processor"
  }
}
