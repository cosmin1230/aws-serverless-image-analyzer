resource "aws_s3_bucket" "image_uploads" {
  bucket = lower("${var.project_name}-uploads-${random_string.suffix.result}")
}

resource "aws_s3_bucket_public_access_block" "image_uploads" {
  bucket = aws_s3_bucket.image_uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "image_uploads" {
  bucket = aws_s3_bucket.image_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST", "PUT", "GET", "HEAD"]
    allowed_origins = ["https://${aws_cloudfront_distribution.site.domain_name}"]
    expose_headers  = ["ETag"]
  }

  depends_on = [aws_s3_bucket_public_access_block.image_uploads]
}

# --- Frontend S3 Bucket ---
resource "aws_s3_bucket" "frontend_hosting" {
  bucket = lower("${var.project_name}-frontend-${random_string.suffix.result}")
}

resource "aws_s3_bucket_public_access_block" "frontend_hosting" {
  bucket = aws_s3_bucket.frontend_hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend_hosting" {
  bucket = aws_s3_bucket.frontend_hosting.id
  index_document {
    suffix = "login.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_hosting" {
  bucket = aws_s3_bucket.frontend_hosting.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend_hosting.arn}/*"
    }]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.frontend_hosting]
}

# --- DynamoDB & SNS ---
resource "aws_dynamodb_table" "rekognition_cache" {
  name           = "${var.project_name}Cache"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ImageKey"
  attribute {
    name = "ImageKey"
    type = "S"
  }
}
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}Notifications"
}
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.user_email
}

# --- Random Suffix for Uniqueness ---
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# --- S3: Frontend File Uploads (The Automation Magic) ---
resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.frontend_hosting.id
  key          = "login.html"
  content_type = "text/html"

  # Render the template with live values
  content = templatefile("${path.module}/frontend/login.html", {
    aws_region             = var.aws_region,
    user_pool_id           = aws_cognito_user_pool.main.id,
    app_client_id          = aws_cognito_user_pool_client.main.id,
    cloudfront_domain_name = aws_cloudfront_distribution.site.domain_name
  })
  
  # Ensure the file is re-uploaded if the template changes
  etag = filemd5("${path.module}/frontend/login.html")
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend_hosting.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile("${path.module}/frontend/index.html", {
    aws_region             = var.aws_region,
    user_pool_id           = aws_cognito_user_pool.main.id,
    app_client_id          = aws_cognito_user_pool_client.main.id,
    cloudfront_domain_name = aws_cloudfront_distribution.site.domain_name,
    api_gateway_id         = aws_api_gateway_rest_api.main.id
  })

  etag = filemd5("${path.module}/frontend/index.html")
}