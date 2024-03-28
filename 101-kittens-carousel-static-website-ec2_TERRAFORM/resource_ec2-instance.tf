terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "arrow_kittens-ec2" {
  ami                         = "ami-041feb57c611358bd" # Amazon Linux 2023
  instance_type               = var.instance_type
  key_name                    = var.instance_keypair
  associate_public_ip_address = var.enable_public_ip
  availability_zone           = "us-east-1a"                      # Default VPC
  subnet_id                   = "subnet-069d7f45d2659c70c"        # us-east-1a - Default VPC
  vpc_security_group_ids      = [aws_security_group.arrow_sec.id] # resource_security-group.tf
  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
      #!/bin/sh
      dnf update -y
      dnf install httpd -y
      dnf install wget -y
      FOLDER="https://raw.githubusercontent.com/alparslanu6347/kittens-terraform/main/static-web"
      cd /var/www/html
      wget $FOLDER/index.html
      wget $FOLDER/cat0.jpg
      wget $FOLDER/cat1.jpg
      wget $FOLDER/cat2.jpg
      wget $FOLDER/cat3.png
      systemctl start httpd
      systemctl enable httpd
      EOF
}
