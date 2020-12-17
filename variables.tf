variable "region" { default = "us-east-1" }
variable "domain_name" { default = "demo.aws.apted.io" }
variable "admin_cidrs" { 
  type = list(string) 
  default = ["72.21.196.0/24"] 
}