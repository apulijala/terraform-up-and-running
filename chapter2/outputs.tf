output "public_ip" {
  value = aws_autoscaling_group.example
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}