# --- WAF: IP Set ---
# Note: Since the WAF for CloudFront must be in us-east-1, we use the aliased provider.
resource "aws_wafv2_ip_set" "country_set" {
  provider = aws.us-east-1

  name               = "${var.project_name}CountrySet"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []
}

# --- WAF: Web ACL ---
resource "aws_wafv2_web_acl" "main" {
  provider = aws.us-east-1

  name  = "${var.project_name}WebACL"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "AllowCountryRule"
    priority = 1
    action {
      allow {}
    }
    statement {
      geo_match_statement {
        country_codes = [var.my_country_code]
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "allowCountryRule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "mainWebACL"
    sampled_requests_enabled   = false
  }
}

# --- CloudFront Distribution ---
resource "aws_cloudfront_distribution" "site" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend_hosting.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend_hosting.bucket}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for ${var.project_name}"
  default_root_object = "login.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_hosting.bucket}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.main.arn
}