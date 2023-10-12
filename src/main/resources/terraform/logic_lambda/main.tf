resource "aws_iam_role" "admin_lambda_role" {
  name               = "admin-lambda-role"
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

resource "aws_iam_policy" "admin_lambda_policy" {
  name = "admin-lambda-policy"
  description = "IAM policy for admin lambda execution"

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
          "cognito-idp:AdminAddUserToGroup"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action = [
          "sns:CreateTopic",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:sns:*:*:*",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.admin_lambda_policy.arn
  role = aws_iam_role.admin_lambda_role.name
}

resource "aws_lambda_function" "admin_lambda" {
  function_name = "admin-lambda"
  runtime      = "java17"
  handler      = "org.springframework.cloud.function.adapter.aws.FunctionInvoker"
  role         = aws_iam_role.admin_lambda_role.arn
  timeout      = 900

  environment {
    variables = {
      LAMBDA_DOCKER_DNS = "127.0.0.1"
      JAVA_TOOL_OPTIONS = <<EOT
        -DMAIN_CLASS=org.example.CloudProjectApplication
        -Dlogging.level.org.springframework=INFO
        -Daws.cognito.user_pool_id=${var.admin_lambda_system_properties.cognito_main_user_pool_id}
        -Daws.cognito.user_pool_client_id=${var.admin_lambda_system_properties.cognito_main_user_pool_client_id}
        -Daws.cognito.user_pool_client_secret=${var.admin_lambda_system_properties.cognito_main_user_pool_client_secret}
        -Dspring.profiles.active=localstack
        -javaagent:/var/task/lib/AwsSdkV2DisableCertificateValidation-1.0.jar
      EOT
    }
  }

  s3_bucket = "hot-reload"
  s3_key = var.admin_lambda_dist_bucket_key
}