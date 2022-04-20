terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = "us-east-1"
  access_key = "test"
  secret_key = "testABC"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  skip_metadata_api_check = true
  s3_use_path_style = true
  endpoints {
    s3 = "http://localhost:4566"
    lambda = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    iam = "http://localhost:4566"
    eks = "http://localhost:4566"
    cloudwatch = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
  }
}