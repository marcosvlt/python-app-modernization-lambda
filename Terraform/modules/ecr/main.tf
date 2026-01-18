resource "aws_ecr_repository" "repository" {
  name         = var.repository_name
  force_delete = var.force_delete

  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "policy" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.repository.name
  policy     = var.lifecycle_policy
}