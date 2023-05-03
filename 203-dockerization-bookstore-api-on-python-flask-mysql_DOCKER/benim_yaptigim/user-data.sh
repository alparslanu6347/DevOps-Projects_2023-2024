#! /bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
sudo usermod -a -G docker ec2-user
newgrp docker
curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
TOKEN="******************"  # write your token
USER="*******"  # write your github username
yum install git -y
cd /home/ec2-user && git clone https://$TOKEN@github.com/$USER/bookstore-project.git
cd /home/ec2-user/bookstore-project
docker-compose up -d
