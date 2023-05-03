terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = "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"
}

resource "github_repository" "bookstore-repo" {
  name        = "bookstore-project"
  description = "this repo includes docker files and belongs to arrow"
  auto_init = true
  visibility = "private"
}


resource "github_branch_default" "main" {
  branch = "main"  
  repository = github_repository.bookstore-repo.name
}


variable "docker-files" {
  description = "Files to compose up"
  type        = list(string)
  default     = ["docker-compose.yml", "bookstore-api.py", "Dockerfile", "requirements.txt" ]
}


resource "github_repository_file" "compose" {
  repository = github_repository.bookstore-repo.name
  branch = "main" 
  for_each = toset(var.docker-files)
  file = each.value
  content = file(each.value)
  commit_message = "bookstore repo was created and files were added."
  overwrite_on_create = true
}


resource "aws_instance" "bookstore_ec2" {
  ami                     = "ami-00c39f71452c08778"
  instance_type           = "t2.micro"
  key_name                = "arrow"
  vpc_security_group_ids  = [aws_security_group.arrow.id]
  tags = {
    Name = "Web server of Bookstore"
  }
  # kopyalarken ismini değiştirdim  bookstore-api.py   ==>> app.py
  # curl -s --create-dirs -o "/home/ec2-user/bookstore-api/app.py" -L "$FOLDER"bookstore-api.py  
  # sudo amazon-linux-extras install docker (aws sayfasından)--şu komutun yerine yazılabilir--->>sudo yum install docker -y
  user_data = <<-EOF
          #! /bin/bash
          yum update -y
          yum install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          newgrp docker
          curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          mkdir -p /home/ec2-user/bookstore-api
          TOKEN="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"
          FOLDER="https://$TOKEN@raw.githubusercontent.com/alparslanu6347/bookstore-project/main/"
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/app.py" -L "$FOLDER"bookstore-api.py  
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/requirements.txt" -L "$FOLDER"requirements.txt
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/Dockerfile" -L "$FOLDER"Dockerfile
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/docker-compose.yml" -L "$FOLDER"docker-compose.yml
          cd /home/ec2-user/bookstore-api
          docker build -t alparslanu6347/bookstoreapi:latest .
          docker-compose up -d
          EOF

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
