data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "bookstore_ec2" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  key_name                    = var.instance_keypair
  vpc_security_group_ids      = [aws_security_group.arrow.id]
  associate_public_ip_address = var.enable_public_ip
  subnet_id                   = "subnet-069d7f45d2659c70c" ## us-east-1a  Bu satırı yazmasak da olur, kendisi bir subnet belirler.
  user_data                   = file("${path.module}/user-data.sh")
  tags = {
    Name = var.instance_name
  }
  depends_on = [github_repository.bookstore-repo, github_repository_file.compose]
}


resource "aws_security_group" "arrow" {
  name        = "bookstore-secgrp"
  description = "arrow-secgrp enable SSH-HTTP for bookstore project"
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
    Name = "arrow_bookstore_secgrp"
  }
}
