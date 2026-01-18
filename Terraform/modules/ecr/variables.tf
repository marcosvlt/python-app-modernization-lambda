variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "Lifecycle policy for the ECR repository"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}