output "roman-numerals_instance_public-ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.arrow_roman-numerals_ec2.public_ip
}

output "roman-numerals_instance_public-dns" {
  description = "EC2 Instance Public DNS"
  value       = aws_instance.arrow_roman-numerals_ec2.public_dns
}