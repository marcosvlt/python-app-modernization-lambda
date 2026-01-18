resource "aws_lambda_function" "function" {
  function_name = var.function_name
  role          = var.role_arn
  package_type  = "Image"
  timeout       = var.timeout
  image_uri     = var.image_uri

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.function.arn
    events              = var.trigger_events
    filter_prefix       = var.filter_prefix
    filter_suffix       = var.filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_s3]
}