# Role for the "Writer" Lambda
resource "aws_iam_role" "writer_lambda_role" {
  name = "${var.project_name}WriterLambdaRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy" "writer_lambda_permissions" {
  name = "${var.project_name}WriterLambdaPermissions"
  role = aws_iam_role.writer_lambda_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      { Action = ["s3:GetObject"], Effect = "Allow", Resource = "${aws_s3_bucket.image_uploads.arn}/*" },
      { Action = ["rekognition:DetectLabels"], Effect = "Allow", Resource = "*" },
      { Action = ["dynamodb:PutItem"], Effect = "Allow", Resource = aws_dynamodb_table.rekognition_cache.arn },
      { Action = ["sns:Publish"], Effect = "Allow", Resource = aws_sns_topic.notifications.arn }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "writer_lambda_basic_execution" {
  role       = aws_iam_role.writer_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Role for the "Pre-signed URL" Lambda
resource "aws_iam_role" "presigned_url_lambda_role" {
  name = "${var.project_name}PresignedUrlLambdaRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy" "presigned_url_lambda_permissions" {
  name = "${var.project_name}PresignedUrlLambdaPermissions"
  role = aws_iam_role.presigned_url_lambda_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "s3:PutObject", Effect = "Allow", Resource = "${aws_s3_bucket.image_uploads.arn}/*" }]
  })
}
resource "aws_iam_role_policy_attachment" "presigned_url_lambda_basic_execution" {
  role       = aws_iam_role.presigned_url_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "api_gateway_dynamodb_role" {
  name = "${var.project_name}ApiGatewayDynamoDBRole"
  
  # This policy allows the API Gateway service to "assume" this role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_dynamodb_policy" {
  role       = aws_iam_role.api_gateway_dynamodb_role.name
  # This is the standard AWS-managed policy that grants read-only access to DynamoDB.
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}