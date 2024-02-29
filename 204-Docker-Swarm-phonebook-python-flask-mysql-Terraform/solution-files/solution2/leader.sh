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
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${image-repo}
docker service create \
  --name=viz \
  --publish=8080:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer
dnf install git -y
docker build --force-rm -t "${image-repo}:latest" ${git-repo}#main
docker push "${image-repo}:latest"
cd /home/ec2-user
git clone ${git-repo}
sed -i "s|phonebook_image|${image-repo}|" /home/ec2-user/phonebook/docker-compose.yaml
docker stack deploy --with-registry-auth -c /home/ec2-user/phonebook/docker-compose.yaml phonebook