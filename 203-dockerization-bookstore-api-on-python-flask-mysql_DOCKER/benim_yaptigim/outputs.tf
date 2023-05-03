output "public_ip" {
  value = "http://${aws_instance.bookstore_ec2.public_ip}"
}

output "public_dns" {
  value = "http://${aws_instance.bookstore_ec2.public_dns}"
}