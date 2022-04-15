# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}

variable "lambda_name" {
  default = "learn-lambda"
  type = string
  description = "the prefix for the lambda name"
}