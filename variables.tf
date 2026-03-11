variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "my_global_ip" {
  description = "MY ACCESS IP"
  type        = string
}

variable "line_auth_client_id" {
  type = string
}

variable "lambda_exec_role_arn" {
  type = string
}

variable "lambda_image_uri" {
  type = string
}
