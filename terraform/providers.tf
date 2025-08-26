terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.3" }
  }
}
provider "aws" {
  region = var.aws_region
}
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}