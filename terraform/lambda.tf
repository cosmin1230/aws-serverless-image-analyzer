# --- Lambda Function Packaging ---
data "archive_file" "writer_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/writer_lambda"
  output_path = "${path.module}/lambda_functions/writer_lambda.zip"
}
data "archive_file" "presigned_url_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_functions/presigned_url_lambda"
  output_path = "${path.module}/lambda_functions/presigned_url_lambda.zip"
}

# --- "Writer" Lambda Function (Rekognition) ---
resource "aws_lambda_function" "writer_lambda" {
  function_name = "${var.project_name}WriterLambda"
  role          = aws_iam_role.writer_lambda_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  filename      = data.archive_file.writer_lambda_zip.output_path
  source_code_hash = data.archive_file.writer_lambda_zip.output_base64sha256
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.rekognition_cache.name
      SNS_TOPIC_ARN       = aws_sns_topic.notifications.arn
    }
  }
}
resource "aws_s3_bucket_notification" "image_upload_trigger" {
  bucket = aws_s3_bucket.image_uploads.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.writer_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
resource "aws_lambda_permission" "allow_s3_to_call_writer" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.writer_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.image_uploads.arn
}

# --- "Pre-signed URL" Lambda Function ---
resource "aws_lambda_function" "presigned_url_lambda" {
  function_name = "${var.project_name}PresignedUrlLambda"
  role          = aws_iam_role.presigned_url_lambda_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.presigned_url_lambda_zip.output_path
  source_code_hash = data.archive_file.presigned_url_lambda_zip.output_base64sha256
  environment {
    variables = {
      UPLOAD_BUCKET_NAME = aws_s3_bucket.image_uploads.bucket
      CLOUDFRONT_URL     = "https://${aws_cloudfront_distribution.site.domain_name}"
    }
  }
}