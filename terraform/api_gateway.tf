# --- API Gateway: Main Definition ---
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}API"
  description = "API for the Serverless Image Analyzer"
}

# --- API Gateway: Cognito Authorizer ---
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "CognitoAuthorizer"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  provider_arns   = [aws_cognito_user_pool.main.arn]
  identity_source = "method.request.header.Authorization"
}

# --- API Gateway: Resources ---
resource "aws_api_gateway_resource" "uploads" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "uploads"
}
resource "aws_api_gateway_resource" "results" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "results"
}
resource "aws_api_gateway_resource" "results_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.results.id
  path_part   = "{imagekey}"
}

# --- Endpoint: POST /uploads ---
resource "aws_api_gateway_method" "uploads_post" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.uploads.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = ["openid"]
}
resource "aws_api_gateway_integration" "uploads_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.uploads.id
  http_method             = aws_api_gateway_method.uploads_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.presigned_url_lambda.invoke_arn
}

# --- Endpoint: GET /results/{imagekey} ---
resource "aws_api_gateway_method" "results_get" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.results_proxy.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = ["openid"]
}
resource "aws_api_gateway_integration" "results_get_dynamodb" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.results_proxy.id
  http_method             = aws_api_gateway_method.results_get.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:dynamodb:action/GetItem"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn
  request_templates = {
    "application/json" = jsonencode({
      TableName = aws_dynamodb_table.rekognition_cache.name
      Key       = { ImageKey = { S = "$input.params('imagekey')" } }
    })
  }
}
resource "aws_api_gateway_method_response" "results_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results_proxy.id
  http_method = aws_api_gateway_method.results_get.http_method
  status_code = "200"
  response_parameters = { "method.response.header.Access-Control-Allow-Origin" = true }
}
resource "aws_api_gateway_integration_response" "results_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results_proxy.id
  http_method = aws_api_gateway_method.results_get.http_method
  status_code = aws_api_gateway_method_response.results_get_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'https://${aws_cloudfront_distribution.site.domain_name}'"
  }
}

# --- CORS: OPTIONS Method for /uploads ---
resource "aws_api_gateway_method" "uploads_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.uploads.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "uploads_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{ \"statusCode\": 200 }" }
}
resource "aws_api_gateway_method_response" "uploads_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
resource "aws_api_gateway_integration_response" "uploads_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  status_code = aws_api_gateway_method_response.uploads_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.site.domain_name}'"
  }
}

# --- CORS: OPTIONS Method for /results/{imagekey} ---
resource "aws_api_gateway_method" "results_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.results_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "results_options_mock" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results_proxy.id
  http_method = aws_api_gateway_method.results_options.http_method
  type        = "MOCK"
  request_templates = { "application/json" = "{ \"statusCode\": 200 }" }
}
resource "aws_api_gateway_method_response" "results_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results_proxy.id
  http_method = aws_api_gateway_method.results_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
resource "aws_api_gateway_integration_response" "results_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.results_proxy.id
  http_method = aws_api_gateway_method.results_options.http_method
  status_code = aws_api_gateway_method_response.results_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.site.domain_name}'"
  }
}

# --- Deployment & Stage ---
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.uploads.id,
      aws_api_gateway_method.uploads_post.id,
      aws_api_gateway_integration.uploads_post_lambda.id,
      aws_api_gateway_method.uploads_options.id,
      aws_api_gateway_integration.uploads_options_mock.id,
      aws_api_gateway_resource.results_proxy.id,
      aws_api_gateway_method.results_get.id,
      aws_api_gateway_integration.results_get_dynamodb.id,
      aws_api_gateway_method.results_options.id,
      aws_api_gateway_integration.results_options_mock.id,
    ]))
  }
  lifecycle { create_before_destroy = true }
}
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
}

# --- Lambda Permission ---
resource "aws_lambda_permission" "allow_api_gateway_to_call_presigned_url" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}