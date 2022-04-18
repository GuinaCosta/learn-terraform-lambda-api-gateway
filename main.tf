resource "random_pet" "lambda_bucket_name" {
  prefix = var.lambda_name
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  force_destroy = true
}

data "archive_file" "lambda_zip_file" {
  type = "zip"

  source_dir  = "${path.module}/build"
  output_path = "${path.module}/build.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda.zip"
  source = data.archive_file.lambda_zip_file.output_path

  etag = filemd5(data.archive_file.lambda_zip_file.output_path)
}

data "archive_file" "lambda_layer_zip_file" {
  type = "zip"

  source_dir  = "${path.module}/lambda-layers/axios/nodejs"
  output_path = "${path.module}/axios.zip"
}

resource "aws_lambda_layer_version" "my_lambda_custom_axios_layer" {
  layer_name = "axios-lambda-layer"
  filename = data.archive_file.lambda_zip_file.output_path
  compatible_runtimes = ["nodejs14.x"]

  description = "Add axios dependency as a Node.js 14.x Layer"

  source_code_hash = data.archive_file.lambda_layer_zip_file.output_base64sha256
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name = var.lambda_name

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "nodejs14.x"
  handler = var.lambda_handler
  layers = [aws_lambda_layer_version.my_lambda_custom_axios_layer.arn]

  environment {
    variables = var.lambda_environment_variables
  }

  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_function_url" "my_lambda_function_url" {
  function_name      = aws_lambda_function.my_lambda_function.arn
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.my_lambda_function.function_name}"

  retention_in_days = 7
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


// API Gateway
resource "aws_apigatewayv2_api" "lambda" {
  name          = "${var.lambda_name}serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "${var.lambda_name}_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "my_lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.my_lambda_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "my_lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.my_lambda.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}