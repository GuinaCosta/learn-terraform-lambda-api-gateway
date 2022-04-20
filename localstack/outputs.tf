# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.my_lambda_function.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_api_gateway_stage.lambda_api_gw_stage.invoke_url
}

output "api_gateway_execute_arn" {
  value = aws_api_gateway_rest_api.lambda_api_gw.execution_arn
  description = "API Gateway execution URI"
}