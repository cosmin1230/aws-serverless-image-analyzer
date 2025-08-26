output "cloudfront_url" {
  description = "The URL for the frontend website."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.id
}

output "app_client_id" {
  description = "The ID of the Cognito App Client."
  value       = aws_cognito_user_pool_client.main.id
}