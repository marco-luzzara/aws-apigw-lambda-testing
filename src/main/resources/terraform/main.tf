terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default = "us-east-1"
}

# provider in Localstack is overridden by provider_override.tf file because the
# endpoints must be manually set
provider "aws" {
  access_key                  = "accesskey"
  secret_key                  = "secretkey"
  region                      = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localstackmaintest:4566"
    apigatewayv2   = "http://localstackmaintest:4566"
    cloudformation = "http://localstackmaintest:4566"
    cloudwatch     = "http://localstackmaintest:4566"
    dynamodb       = "http://localstackmaintest:4566"
    ec2            = "http://localstackmaintest:4566"
    es             = "http://localstackmaintest:4566"
    elasticache    = "http://localstackmaintest:4566"
    firehose       = "http://localstackmaintest:4566"
    iam            = "http://localstackmaintest:4566"
    kinesis        = "http://localstackmaintest:4566"
    lambda         = "http://localstackmaintest:4566"
    rds            = "http://localstackmaintest:4566"
    redshift       = "http://localstackmaintest:4566"
    route53        = "http://localstackmaintest:4566"
    s3             = "http://localstackmaintest:4566"
    secretsmanager = "http://localstackmaintest:4566"
    ses            = "http://localstackmaintest:4566"
    sns            = "http://localstackmaintest:4566"
    sqs            = "http://localstackmaintest:4566"
    ssm            = "http://localstackmaintest:4566"
    stepfunctions  = "http://localstackmaintest:4566"
    sts            = "http://localstackmaintest:4566"
    cognitoidentity = "http://localstackmaintest:4566"
    cognitoidp     = "http://localstackmaintest:4566"
  }
}

module "authentication" {
  source = "./authentication"

  admin_user_credentials = {
    username = "admin1@amazon.com"
    password = "adminadmin"
  }
}

module "admin_lambda" {
  source = "./logic_lambda"

  admin_lambda_dist_bucket_key = var.admin_lambda_dist_bucket_key
  admin_lambda_system_properties = {
    cognito_main_user_pool_id = module.authentication.cognito_main_pool_id
    cognito_main_user_pool_client_id = module.authentication.cognito_main_pool_client_id
    cognito_main_user_pool_client_secret = module.authentication.cognito_main_pool_client_secret
  }
}

module "authorizer_lambda" {
  source = "./authorizer_lambda"

  authorizer_lambda_dist_bucket_key = var.authorizer_lambda_dist_bucket_key
  authorizer_lambda_system_properties = {
    cognito_main_user_pool_id = module.authentication.cognito_main_pool_id
    cognito_main_user_pool_client_id = module.authentication.cognito_main_pool_client_id
    cognito_main_user_pool_client_secret = module.authentication.cognito_main_pool_client_secret
  }
}

module "webapp_apigw" {
  source = "./webapp_apigw"

  admin_lambda_info = {
    invoke_arn = module.admin_lambda.invoke_arn
    function_name = module.admin_lambda.function_name
    lambda_arn = module.admin_lambda.lambda_arn
  }
  authorizer_lambda_info = {
    invoke_arn = module.authorizer_lambda.invoke_arn
    function_name = module.authorizer_lambda.function_name
    lambda_arn = module.authorizer_lambda.lambda_arn
  }
  cognito_user_pool_arn = module.authentication.cognito_main_pool_arn
}

resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on = [module.webapp_apigw]

  rest_api_id = module.webapp_apigw.webapp_apigw_rest_api_id
  stage_name  = "test"
}