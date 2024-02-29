terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  /* profile = "cw-training" */
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  name = "us-east-1"
}

locals {
  github-repo     = "https://github.com/alparslanu6347/phonebook.git"  # change the github-user name
}

resource "aws_ecr_repository" "ecr-repo" {
  name                 = "arrow/phonebook-app" 
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  force_delete = true
}

variable "myami" {
  default = "ami-0dbc3d7bc646e8516"
}

variable "instancetype" {
  default = "t2.micro"
}

variable "mykey" {
  default = "arrowlevent"  # change the key name
}

resource "aws_instance" "docker-machine-leader-manager" {
  ami           = var.myami
  instance_type = var.instancetype
  key_name      = var.mykey
  root_block_device {
    volume_size = 16
  }
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  user_data = templatefile("leader.sh", {region = data.aws_region.current.name, image-repo = aws_ecr_repository.ecr-repo.repository_url, git-repo = local.github-repo})
  tags = {
    Name = "Docker-Swarm-Leader-Manager"
  }
}

resource "aws_instance" "docker-machine-managers" {
  ami                    = var.myami
  instance_type          = var.instancetype
  key_name               = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  count                  = 2
  user_data = templatefile("manager.sh", {leader_id = aws_instance.docker-machine-leader-manager.id, region = data.aws_region.current.name, leader_privateip = aws_instance.docker-machine-leader-manager.private_ip, manager-name = "Manager-${count.index + 1}"})
  tags = {
    Name = "Docker-Swarm-Manager-${count.index + 1}"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}

resource "aws_instance" "docker-machine-workers" {
  ami                    = var.myami
  instance_type          = var.instancetype
  key_name               = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  count                  = 2
  user_data = templatefile("worker.sh", {leader_id = aws_instance.docker-machine-leader-manager.id, region = data.aws_region.current.name, leader_privateip = aws_instance.docker-machine-leader-manager.private_ip, worker-name = "Worker-${count.index + 1}"})
  tags = {
    Name = "Docker-Swarm-Worker-${count.index + 1}"
  }
  depends_on = [aws_instance.docker-machine-leader-manager]
}

variable "sg-ports" {
  default = [80, 22, 2377, 7946, 8080]
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-swarm-sec-gr-204"
  tags = {
    Name = "swarm-sec-gr"
  }
  dynamic "ingress" {
    for_each = var.sg-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
    from_port   = 7946
    protocol    = "udp"
    to_port     = 7946
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 4789
    protocol    = "udp"
    to_port     = 4789
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_instance_profile" "ec2ecr-profile" {
  name = "swarmprofile204"
  role = aws_iam_role.ec2fulltoecr.name
}

resource "aws_iam_role" "ec2fulltoecr" {
  name = "ec2roletoecrproject"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ec2-user"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstanceStatus",
          "Resource" : "*"
        }
      ]
    })
  }
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}

output "leader-manager-public-ip" {
  value = aws_instance.docker-machine-leader-manager.public_ip
}

output "website-url" {
  value = "http://${aws_instance.docker-machine-leader-manager.public_ip}"
}

output "viz-url" {
  value = "http://${aws_instance.docker-machine-leader-manager.public_ip}:8080"
}

output "manager-public-ip" {
  value = aws_instance.docker-machine-managers.*.public_ip
}

output "worker-public-ip" {
  value = aws_instance.docker-machine-workers.*.public_ip
}

output "ecr-repo-url" {
  value = aws_ecr_repository.ecr-repo.repository_url
}