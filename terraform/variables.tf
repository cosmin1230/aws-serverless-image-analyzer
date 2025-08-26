variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-west-2"
}
variable "project_name" {
  description = "The base name for all resources."
  type        = string
  default     = "ImageAnalyzer"
}
variable "user_email" {
  description = "The email address to subscribe to the SNS topic for notifications."
  type        = string
}
variable "my_country_code" {
  description = "The two-letter country code for the WAF geo-restriction."
  type        = string
  default     = "IL"
}