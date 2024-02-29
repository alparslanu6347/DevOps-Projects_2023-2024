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
  github-repo     = "https://github.com/alparslanu6347/phonebookapp.git"                    // change repo name 
  github-file-url = "https://raw.githubusercontent.com/alparslanu6347/phonebookapp/main/"   // change repo url  , don't forget / slash
}
// https://docs.docker.com/engine/reference/commandline/build/ : myrepo.git#mybranch   ;  myrepo.git#mybranch:myfolder
data "template_file" "leader-master" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Leader-Manager
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker swarm init
    aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr-repo.repository_url}
    docker service create \
      --name=viz \
      --publish=8080:8080/tcp \
      --constraint=node.role==manager \
      --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      dockersamples/visualizer
    dnf install git -y
    docker build --force-rm -t "${aws_ecr_repository.ecr-repo.repository_url}:latest" ${local.github-repo}#main
    docker push "${aws_ecr_repository.ecr-repo.repository_url}:latest"
    mkdir -p /home/ec2-user/phonebook && cd /home/ec2-user/phonebook
    curl -o "docker-compose.yml" -L ${local.github-file-url}docker-compose.yml
    curl -o "init.sql" -L ${local.github-file-url}init.sql
    sed -i "s|phonebook_image|${aws_ecr_repository.ecr-repo.repository_url}|" /home/ec2-user/phonebook/docker-compose.yml
    docker stack deploy --with-registry-auth -c docker-compose.yml phonebook
  EOF
}

data "template_file" "manager" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Manager
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N ""
    aws ec2-instance-connect send-ssh-public-key --region ${data.aws_region.current.name} --instance-id ${aws_instance.docker-machine-leader-manager.id} --instance-os-user ec2-user --ssh-public-key file:///home/ec2-user/clarus_key.pub \
    && eval "$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
    -i /home/ec2-user/clarus_key ec2-user@${aws_instance.docker-machine-leader-manager.private_ip} docker swarm join-token manager | grep -i 'docker')"
  EOF
}

data "template_file" "worker" {
  template = <<-EOF
    #! /bin/bash
    dnf update -y
    hostnamectl set-hostname Worker
    dnf install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.docker-machine-leader-manager.id}
    ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N ""
    aws ec2-instance-connect send-ssh-public-key --region ${data.aws_region.current.name} --instance-id ${aws_instance.docker-machine-leader-manager.id} --instance-os-user ec2-user --ssh-public-key file:///home/ec2-user/clarus_key.pub \
    && eval "$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
    -i /home/ec2-user/clarus_key ec2-user@${aws_instance.docker-machine-leader-manager.private_ip} docker swarm join-token worker | grep -i 'docker')"
  EOF
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
  default = "ami-06b09bfacae1453cb"   # Amazon Linux 2023
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
  user_data              = data.template_file.leader-master.rendered
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
  user_data              = data.template_file.manager.rendered
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
  user_data              = data.template_file.worker.rendered
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
  assume_role_policy = jsonencode({   // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
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

  inline_policy {   // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"    // https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-configure-IAM-role.html
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




##### 1.  worker ve manager userdata içindeki wait'ten sonraki komutlar aşağıdaki gibi de olabilir. (287-290) #####
#!!!! AMA worker ve manager userdata içine ekleme yapmalıyız. !!!!#
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html
# https://github.com/aws/aws-ec2-instance-connect-cli/blob/master/README.rst#ec2-connect-cli

#ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N ""
#aws ec2-instance-connect send-ssh-public-key --region ${data.aws_region.current.name} --instance-id ${aws_instance.docker-machine-leader-manager.id} --instance-os-user ec2-user --ssh-public-key file:///home/ec2-user/clarus_key.pub \ && eval "$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \ -i /home/ec2-user/clarus_key ec2-user@${aws_instance.docker-machine-leader-manager.private_ip} docker swarm join-token worker | grep -i 'docker')"


# dnf install python3 -y
# dnf install python-pip -y
# pip install ec2instanceconnectcli
# eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \ --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token worker | grep -i 'docker')"



##### 2. resource "aws_iam_role" "ec2fulltoecr" - inline_policy içerisinde "ec2:DescribeInstanceStatus" olmasa da olur. #####

# resource "aws_iam_role" "ec2fulltoecr" {
#   name = "ec2roletoecrproject"
#   assume_role_policy = jsonencode({   // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   inline_policy {   // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
#     name = "my_inline_policy"

#     policy = jsonencode({
#       Version = "2012-10-17"    // https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-configure-IAM-role.html
#       Statement = [
#         {
#           "Effect" : "Allow",
#           "Action" : "ec2-instance-connect:SendSSHPublicKey",
#           "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
#           "Condition" : {
#             "StringEquals" : {
#               "ec2:osuser" : "ec2-user"
#             }
#           }
#         },
#         {
#           "Effect" : "Allow",
#           "Action" : "ec2:DescribeInstances",
#           "Resource" : "*"
#         },
#       ]
#     })
#   }
#   managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
# }



##### 3. sed -i "s|phonebook_image|${aws_ecr_repository.ecr-repo.repository_url}|" /home/ec2-user/phonebook/docker-compose.yml   komutunda sed kullanırken /  yerine | kullandık ==>> aws ecr repo isminde/url'sinde de / olduğundan hata verriyor, bu yüzden | kullandık.


##################       MANAGER/WORKER userdata AÇIKLAMASI:       ####################

# The command ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N "" does the following:

# ssh-keygen: SSH anahtar çiftleri oluşturmak ve yönetmek için kullanılan bir araçtır.
# -t rsa: Anahtar tipini belirtir. Bu durumda RSA algoritması kullanılır.
# -f /home/ec2-user/clarus_key: Yeni oluşturulan anahtar dosyasının adını ve konumunu belirtir.
# -q: Sessiz modda çalıştırır, yani kullanıcıya herhangi bir çıktı göstermez.
# -N "": Bu, şifre koruması olmadan anahtarın oluşturulacağını belirtir.
# Bu komut, "/home/ec2-user" dizininde "clarus_key" adında bir özel anahtar dosyası ve aynı dizinde "clarus_key.pub" adında bir genel anahtar dosyası oluşturur. -N "" seçeneği, anahtarı oluştururken herhangi bir şifre sormaz, yani boş bir şifre belirlenmiş olur. Bu, kullanıcıların anahtarı kullanırken herhangi bir şifre girmeden doğrudan erişim sağlamasına izin verir. Ancak bu, güvenlik açısından dikkatli olunması gereken bir uygulamadır.


# The command ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N "" does the following:

# ssh-keygen: This is a command-line utility for generating and managing SSH key pairs.
# -t rsa: Specifies the type of key to create, in this case, an RSA key.
# -f /home/ec2-user/clarus_key: Specifies the filename of the generated key file and its location.
# -q: This option runs the command in quiet mode, which means it won't display any output to the user.
# -N "": This specifies that the key should be created without a passphrase.
# This command creates a private key file named "clarus_key" in the "/home/ec2-user" directory and a corresponding public key file named "clarus_key.pub" in the same directory. The -N "" option means that no passphrase will be set when generating the key, allowing users to access it without entering a password. However, this practice should be approached with caution from a security standpoint.

##################

# aws ec2-instance-connect send-ssh-public-key --region ${region} --instance-id ${leader_id} --instance-os-user ec2-user --ssh-public-key file:///home/ec2-user/clarus_key.pub

# Bu komut, AWS EC2 Örneği Bağlantısı kullanılarak bir SSH genel anahtarının gönderilmesini sağlar. İlgili parametrelerin işlevi şu şekildedir:

# --region ${region}: Bu parametre, işlemin gerçekleştirileceği AWS bölgesini belirtir. ${region}, komutun çalıştırıldığı yerde tanımlanmış bir değişken olabilir.
# --instance-id ${leader_id}: Bu, anahtarın gönderileceği hedef EC2 örneğinin kimliğini belirtir. ${leader_id}, komutun çalıştırıldığı yerde tanımlanmış bir değişken olabilir.
# --instance-os-user ec2-user: Bu parametre, SSH genel anahtarının gönderileceği EC2 örneğindeki hedef kullanıcıyı belirtir. Bu durumda, kullanıcı "ec2-user" olarak belirtilmiştir.
# --ssh-public-key file:///home/ec2-user/clarus_key.pub: Bu, gönderilmek istenen SSH genel anahtar dosyasının tam yolunu belirtir.
# Bu komut, belirtilen AWS bölgesindeki belirli bir EC2 örneğine, belirtilen kullanıcı adı altında, belirtilen genel anahtarı atar. Bu, örneğin yöneticisi tarafından belirli bir kullanıcının belirli bir EC2 örneğine erişmesine izin vermek için kullanışlı olabilir. Bu şekilde, güvenli bir şekilde SSH erişimi sağlanabilir.


#This command facilitates sending an SSH public key using AWS EC2 Instance Connect. Here's the breakdown of the parameters:

# --region ${region}: This parameter specifies the AWS region where the operation will take place. ${region} could be a variable defined where the command is executed.
# --instance-id ${leader_id}: This identifies the target EC2 instance to which the key will be sent. ${leader_id} could be a variable defined where the command is executed.
# --instance-os-user ec2-user: This parameter specifies the target user on the EC2 instance to which the SSH public key will be sent. In this case, the user is specified as "ec2-user".
#--ssh-public-key file:///home/ec2-user/clarus_key.pub: This specifies the full path of the SSH public key file that is to be sent.
# This command essentially allows for the secure transmission of the SSH public key to a specific EC2 instance in the specified AWS region under the designated user. It can be useful for enabling controlled SSH access to a particular EC2 instance by a specific user, thereby enhancing security.

##########################

# eval "$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \ -i /home/ec2-user/clarus_key ec2-user@${leader_privateip} docker swarm join-token manager | grep -i 'docker')"

# eval: Bu, komut çıktısını değerlendirmek için kullanılır. Komut çıktısını doğrudan çalıştırır.

# ssh: Uzak bir makineye bağlanmak ve komut çalıştırmak için kullanılan komuttur.

# -o UserKnownHostsFile=/dev/null: Bu seçenek, bilinen ana bilgisayar dosyasını /dev/null olarak ayarlar ve bu da ana bilgisayar anahtarının kontrolünü devre dışı bırakır.

# -o StrictHostKeyChecking=no: Bu seçenek, katı ana bilgisayar anahtarının kontrolünü devre dışı bırakır, yani ana bilgisayarın otantikliğini onaylamanız istenmez.

# -i /home/ec2-user/clarus_key: Bu, SSH bağlantısı için kullanılacak özel anahtarın yolunu belirtir.

# ec2-user@${leader_privateip}: Bu, bağlanılmak istenen uzak sunucunun kullanıcı adı ve özel IP adresidir.

# docker swarm join-token manager: Bu, SSH bağlantısı kurulan uzak makinede çalıştırılan komuttur. Bu komut, bir yönetici için Docker Swarm katılma belirteci elde etmek için kullanılır.

# Genel olarak, bu komut, sağlanan SSH anahtarı ile belirtilen EC2 örneğine bağlanır ve ardından uzak makinede docker swarm join-token manager komutunu çalıştırarak bir yönetici için Docker Swarm katılma belirteci alır.


# This command is used to execute the SSH command and retrieve information from a remote host. Here's the breakdown of the components:

# eval: This is a shell builtin command in Bash that is used to execute arguments as a shell command. It allows you to run a command and assign its output to a variable.

# ssh: This is the command used for logging into a remote machine and executing commands. In this case, it is used to establish an SSH connection.

# -o UserKnownHostsFile=/dev/null: This option sets the known hosts file to /dev/null, which effectively disables the host key checking.

# -o StrictHostKeyChecking=no: This option disables the strict host key checking, which means it won't prompt you to confirm the authenticity of the host.

# -i /home/ec2-user/clarus_key: This specifies the path to the private key to use for the SSH connection.

# ec2-user@${leader_privateip}: This is the username and the private IP address of the remote host you are trying to connect to.

# docker swarm join-token manager: This is the command that is executed on the remote host after the SSH connection is established. It is used to retrieve the Docker Swarm join token for a manager.

# Overall, this command connects to the specified EC2 instance using the SSH key provided, and then it executes the docker swarm join-token manager command on that remote instance to obtain the Docker Swarm join token for a manager node.