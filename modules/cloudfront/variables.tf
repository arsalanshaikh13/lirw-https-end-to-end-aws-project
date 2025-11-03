variable "certificate_domain_name"{}
# variable "alb_domain_name" {}
variable "alb_api_domain_name" {}
variable "additional_domain_name" {}
variable "project_name" {}


variable "alb_waf_name" {
  type    = string
  default = "alb-waf-customHeader-sqli-xss"
}

variable "cloudfront_header_name" {
  type    = string
  default = "X-Custom-Header"
}

variable "cloudfront_header_value" {
  type    = string
  default = "random-value-123456"
}

variable "public_alb_arn" {
  type        = string
  description = "ARN of ALB (load balancer listener or ALB) to associate with WAF"
}