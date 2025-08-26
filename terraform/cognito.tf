# terraform/cognito.tf

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}UserPool"
  
  # Configure users to be able to sign up and sign in with their email address as their username
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}AppClient"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  # Enable both "code" (for the redirect) and "implicit" (for the token) grant types.
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  
  callback_urls                        = ["https://${aws_cloudfront_distribution.site.domain_name}/index.html"]
  logout_urls                          = ["https://${aws_cloudfront_distribution.site.domain_name}/login.html"]
  
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = lower("${var.project_name}-domain-${random_string.suffix.result}")
  user_pool_id = aws_cognito_user_pool.main.id
}