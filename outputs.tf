output "elastic_ip" {
  value       = aws_eip.web.public_ip
  description = "Public IP address to access the application"
}

output "application_url" {
  value       = "http://${aws_eip.web.public_ip}"
  description = "Application URL"
}
