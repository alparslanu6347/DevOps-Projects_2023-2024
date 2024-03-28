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

resource "aws_instance" "arrow_roman-numerals_ec2" {
  ami                         = "ami-041feb57c611358bd" # Amazon Linux 2023
  instance_type               = var.instance_type
  key_name                    = var.instance_keypair
  vpc_security_group_ids      = [aws_security_group.arrow.id]
  associate_public_ip_address = var.enable_public_ip
  subnet_id                   = "subnet-069d7f45d2659c70c" ## us-east-1a
  user_data                   = file("${path.module}/userdata.sh")
  tags = {
    Name = var.instance_name
  }
}

resource "aws_security_group" "arrow" {
  name        = "arrow-secgrp"
  description = "arrow-secgrp enable SSH-HTTP for roman-numerals project"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "arrow_roman-numerals_secgrp"
  }
}

