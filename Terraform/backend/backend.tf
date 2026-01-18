provider aws {
  region = "us-east-1"
}
 
#####################################################
### This creates a s3 bucket and a dynamoDB table ###
#####################################################
 
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-marcos123456"
}
 
resource "aws_dynamodb_table" "terraform_lock_state" {
  name         = "dynamoDB_to_lock_terraform_state-marcos123456"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
 
#################################

resource "aws_s3_bucket" "terraform_state_build" {
  bucket = "build-terraform-state-marcos123456"
}
 
resource "aws_dynamodb_table" "terraform_lock_state_build" {
  name         = "build-dynamoDB_to_lock_terraform_state-marcos123456"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}