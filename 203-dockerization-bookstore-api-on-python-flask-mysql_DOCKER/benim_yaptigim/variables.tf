variable "git-token" {
  default = "*******************"   # write your token
}


variable "docker-files" {
  description = "Files to compose up"
  type        = list(string)
  default     = ["docker-compose.yml", "bookstore-api.py", "Dockerfile", "requirements.txt"]
}


variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t2.micro"
}

variable "instance_keypair" {
  description = "AWS EC2 Key Pair that need to be associated with EC2 Instance"
  type        = string
  default     = "*****"   # write your keyname
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "arrow_bookstore_instance"
}

variable "enable_public_ip" {
  description = "Enable public IP address"
  type        = bool
  default     = true
}