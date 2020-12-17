variable "region" { default = "us-east-1" }
variable "domain_name" {}
variable "admin_cidrs" { type = list(string) }
variable "certificate_arn" {}