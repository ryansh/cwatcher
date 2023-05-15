provider "aws" {
  region     = "ap-southeast-2"
  access_key = ""
  secret_key = ""
  default_tags {
    tags = {
      Environment = var.environment
      Owner      = "Digital"
      Cost       = "Digital"
      Project    = "test"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

