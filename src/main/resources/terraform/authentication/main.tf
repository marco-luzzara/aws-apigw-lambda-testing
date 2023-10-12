data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws_account_id    = data.aws_caller_identity.current.account_id
  aws_region        = data.aws_region.current.name
  api_resource_prefix = "arn:aws:execute-api:${local.aws_region}:${local.aws_account_id}:*/*"
}

resource "aws_cognito_user_pool" "main_pool" {
  name = "main-pool"

  auto_verified_attributes = ["email"]
  username_attributes = ["email"]
  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }
}

resource "aws_iam_role" "cognito_admin_user_group_role" {
  name = "cognito-admin-user-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "execute-api:Invoke"
        Effect   = "Allow"
        Resource = [
          "*"
#          "${local.api_resource_prefix}/POST/shops"
        ]
      }
    ]
  })
}

resource "aws_cognito_user_group" "admin_user_group" {
  name         = "admin-user-group"
  user_pool_id = aws_cognito_user_pool.main_pool.id
  role_arn = aws_iam_role.cognito_admin_user_group_role.arn
}

resource "aws_cognito_user_pool_client" "main_pool_client" {
  name            = "main-pool-client"
  user_pool_id    = aws_cognito_user_pool.main_pool.id
  allowed_oauth_flows_user_pool_client = true
  callback_urls = ["https://example.com"]
  allowed_oauth_flows                 = ["implicit"]
  allowed_oauth_scopes                = ["openid", "email", "profile"]

  generate_secret = true
}

resource "aws_cognito_user" "main_admin_user" {
  user_pool_id = aws_cognito_user_pool.main_pool.id
  username    = var.admin_user_credentials.username
  password    = var.admin_user_credentials.password
  attributes = {
    email = var.admin_user_credentials.username
  }
}

resource "aws_cognito_user_in_group" "main_admin_membership" {
  user_pool_id   = aws_cognito_user_pool.main_pool.id
  username       = aws_cognito_user.main_admin_user.username
  group_name     = aws_cognito_user_group.admin_user_group.name
}