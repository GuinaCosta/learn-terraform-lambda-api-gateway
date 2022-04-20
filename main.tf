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

  source_dir  = "${path.module}/hello-world"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda.zip"
  source = data.archive_file.lambda_zip_file.output_path

  etag = filemd5(data.archive_file.lambda_zip_file.output_path)
}
/*
data "archive_file" "lambda_layer_zip_file" {
  type = "zip"

  source_dir  = "../${path.module}/lambda-layers/axios/nodejs"
  output_path = "${path.module}/axios.zip"
}

resource "aws_lambda_layer_version" "my_lambda_custom_axios_layer" {
  layer_name = "axios-lambda-layer"
  filename = data.archive_file.lambda_layer_zip_file.output_path
  compatible_runtimes = ["nodejs14.x"]

  description = "Add axios dependency as a Node.js 14.x Layer"

  source_code_hash = data.archive_file.lambda_layer_zip_file.output_base64sha256
}*/

resource "aws_lambda_function" "my_lambda_function" {
  function_name = var.lambda_name

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "nodejs14.x"
  handler = var.lambda_handler
  #layers = [aws_lambda_layer_version.my_lambda_custom_axios_layer.arn]

  environment {
    variables = merge(
      var.lambda_environment_variables,
      {
        "SECRETS_MANAGER_NAME": aws_secretsmanager_secret.my_lambda_secrets.name
      }
    )
  }

  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

/*
resource "aws_lambda_function_url" "my_lambda_function_url" {
  function_name      = aws_lambda_function.my_lambda_function.arn
  authorization_type = "NONE"
}*/

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


resource "aws_secretsmanager_secret" "my_lambda_secrets" {
  name = "${var.lambda_name}-secret"
}

resource "aws_secretsmanager_secret_version" "my_lambda_secret_value" {
  secret_id = aws_secretsmanager_secret.my_lambda_secrets.id

  secret_string = var.secret_value
}

resource "aws_secretsmanager_secret_policy" "my_lambda_secrets_policy" {
  secret_arn = aws_secretsmanager_secret.my_lambda_secrets.arn


  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableAnotherAWSAccountToReadTheSecret",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.lambda_exec.arn}"
      },
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }
  ]
}
POLICY
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

resource "aws_api_gateway_rest_api" "lambda_api_gw" {
  name = "example"
}

resource "aws_api_gateway_resource" "lambda_api_gw_resource" {
  parent_id   = aws_api_gateway_rest_api.lambda_api_gw.root_resource_id
  path_part   = "otl"
  rest_api_id = aws_api_gateway_rest_api.lambda_api_gw.id
}

resource "aws_api_gateway_method" "lambda_api_gw_resource_method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.lambda_api_gw_resource.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api_gw.id
}

resource "aws_api_gateway_integration" "lambda_api_gw_resource_integration" {
  http_method = aws_api_gateway_method.lambda_api_gw_resource_method.http_method
  integration_http_method = aws_api_gateway_method.lambda_api_gw_resource_method.http_method

  resource_id = aws_api_gateway_resource.lambda_api_gw_resource.id
  rest_api_id = aws_api_gateway_rest_api.lambda_api_gw.id
  type        = "AWS_PROXY"

  uri = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_api_gw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api_gw.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.lambda_api_gw_resource.id,
      aws_api_gateway_method.lambda_api_gw_resource_method.id,
      aws_api_gateway_integration.lambda_api_gw_resource_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambda_api_gw_stage" {
  deployment_id = aws_api_gateway_deployment.lambda_api_gw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api_gw.id
  stage_name    = "dev"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_api_gateway_rest_api.lambda_api_gw.name}"

  retention_in_days = 7
}
/*
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

}*/

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:000000000000:${aws_api_gateway_rest_api.lambda_api_gw.id}/*/${aws_api_gateway_method.lambda_api_gw_resource_method.http_method}${aws_api_gateway_resource.lambda_api_gw_resource.path}"
}
