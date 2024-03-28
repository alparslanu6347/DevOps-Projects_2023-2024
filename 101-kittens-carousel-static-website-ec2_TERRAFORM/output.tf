output "kittens_instance_public-ip" { 
  description = "EC2 Instance Public IP"
  value       = aws_instance.arrow_kittens-ec2.public_ip 
}


output "kittens_instance_public-dns" { 
  description = "EC2 Instance Public DNS"
  value       = aws_instance.arrow_kittens-ec2.public_dns 
}

# If you want to add "count" in resource_ec2-instance.tf :
# value = aws_instance.arrow_kittens-ec2.*.public_ip  
# value = aws_instance.arrow_kittens-ec2.*.public_dns