variable "admin_lambda_system_properties" {
  description = "Spring active profile for the admin lambda"
  type        = object({
    cognito_main_user_pool_id = string
    cognito_main_user_pool_client_id = string
    cognito_main_user_pool_client_secret = string
  })
}

variable "admin_lambda_dist_bucket_key" {
  description = "Bucket key for the distribution zip of the web app lambda"
  type        = string
}