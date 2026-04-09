output "nlb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "DNS name of the Network Load Balancer"
}

output "application_url" {
  value       = "http://${aws_lb.web.dns_name}"
  description = "Application URL"
}
