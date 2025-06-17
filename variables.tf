## provider
variable "aws_access_key" {
  description = "IAM ACCESS KEY"
  type        = string
}

variable "aws_secret_key" {
  description = "IAM SECRET KEY"
  type        = string
}

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
