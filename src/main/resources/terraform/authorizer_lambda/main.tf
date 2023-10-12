resource "aws_iam_role" "authorizer_lambda_role" {
  name               = "authorizer-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "authorizer_lambda_policy" {
  name = "authorizer-lambda-policy"
  description = "IAM policy for authorizer lambda execution"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*",
      },
      {
        Action = [
          "cognito-idp:AdminListGroupsForUser",
          "iam:GetRole"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "authorizer_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.authorizer_lambda_policy.arn
  role = aws_iam_role.authorizer_lambda_role.name
}

resource "aws_lambda_function" "authorizer_lambda" {
  function_name = "authorizer-lambda"
  runtime      = "java17"
  handler      = "org.springframework.cloud.function.adapter.aws.FunctionInvoker"
  role         = aws_iam_role.authorizer_lambda_role.arn
  timeout      = 900

  environment {
    variables = {
      LAMBDA_DOCKER_DNS = "127.0.0.1"
      JAVA_TOOL_OPTIONS = <<EOT
        -DMAIN_CLASS=org.example.CloudProjectApplication
        -Dlogging.level.org.springframework=INFO
        -Daws.cognito.user_pool_id=${var.authorizer_lambda_system_properties.cognito_main_user_pool_id}
        -Daws.cognito.user_pool_client_id=${var.authorizer_lambda_system_properties.cognito_main_user_pool_client_id}
        -Daws.cognito.user_pool_client_secret=${var.authorizer_lambda_system_properties.cognito_main_user_pool_client_secret}
        -Dspring.profiles.active=localstack
        -Dspring.cloud.function.definition=authorize
        -javaagent:/var/task/lib/AwsSdkV2DisableCertificateValidation-1.0.jar
      EOT
    }
  }

  s3_bucket = "hot-reload"
  s3_key = var.authorizer_lambda_dist_bucket_key
}