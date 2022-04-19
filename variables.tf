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

#handlers/lambdaHandler.lambdaHandler
variable "lambda_handler" {
  default = "app.handler"
  type = string
  description = "define lambda handler function"
}

variable "lambda_environment_variables" {
  type = map(string)
  description = "(required)lambda environment variables"
}

variable "secret_value" {
  default = {
    secret_key = "jwt.sss.xxx"
  }
  type = map(string)
  description = "secret object to add into secrets manager"
}