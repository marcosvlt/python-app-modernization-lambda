terraform {
  
  backend "s3" {
    bucket         = "terraform-state-marcos123456"
    key            = "stage/terraform-infra.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dynamoDB_to_lock_terraform_state-marcos123456"
    encrypt        = true
  }
}
