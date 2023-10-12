
// ******************************** Customer Lambda Variables

variable "authorizer_lambda_dist_bucket_key" {
  description = "Bucket key for the distribution zip of the authorizer lambda"
  type        = string
  default = "apigateway-authorizer.zip"
}

// ******************************** Admin Lambda Variables

variable "admin_lambda_dist_bucket_key" {
  description = "Bucket key for the distribution zip of the admin lambda"
  type        = string
  default = "admin-api.zip"
}
