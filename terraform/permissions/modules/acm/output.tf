# Output the certificate ARN
output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

# Output the domain name
output "certificate_domain_name" {
  description = "ACM Certificate Domain Name"
  value       = aws_acm_certificate.cert.domain_name
}

# Output the certificate status
output "certificate_status" {
  description = "ACM Certificate Status"
  value       = aws_acm_certificate.cert.status
}