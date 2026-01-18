#################################
# S3 Buckets
#################################

module "input_bucket" {
  source = "../../modules/s3"

  bucket_name   = var.bucket_name_input
  force_destroy = true

  tags = {
    Name        = "FIPE Input Bucket"
    Environment = var.environment
    Project     = "FIPE-Processor"
  }
}

module "output_bucket" {
  source = "../../modules/s3"

  bucket_name   = var.bucket_name_output
  force_destroy = true

  tags = {
    Name        = "FIPE Output Bucket"
    Environment = var.environment
    Project     = "FIPE-Processor"
  }
}

#################################
# IAM Role and Policy for Lambda
#################################

module "lambda_iam" {
  source = "../../modules/iam"

  role_name   = "lambda-fipe-role-${var.environment}"
  policy_name = "lambda-fipe-s3-policy-${var.environment}"

  s3_bucket_arns = [
    "${module.input_bucket.bucket_arn}/*",
    "${module.output_bucket.bucket_arn}/*"
  ]

  tags = {
    Environment = var.environment
    Project     = "FIPE-Processor"
  }
}

#################################
# Lambda Function
#################################

module "fipe_lambda" {
  source = "../../modules/lambda"

  function_name = "fipe-processor-${var.environment}"
  role_arn      = module.lambda_iam.role_arn
  timeout       = 900
  image_uri     = "${var.aws_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repository_name}-${var.environment}:lambda-fipe-${var.environment}-${var.build_version}"

  environment_variables = {
    OUTPUT_BUCKET = var.bucket_name_output
    INPUT_BUCKET  = var.bucket_name_input
    ENVIRONMENT   = var.environment
  }

  s3_bucket_arn  = module.input_bucket.bucket_arn
  s3_bucket_id   = module.input_bucket.bucket_id
  trigger_events = ["s3:ObjectCreated:*"]
  filter_suffix  = ".csv"

  tags = {
    Environment = var.environment
    Project     = "FIPE-Processor"
  }

  depends_on = [module.lambda_iam]
}

##################################