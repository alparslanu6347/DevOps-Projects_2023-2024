### docker-instance (host) : Amazon Linux 2023 , t2.micro ###

# Launch a Docker Machine Instance `Amazon Linux 2023 AMI, t2.micro, ports: 22, 80`  and Connect with SSH

```bash (home/ec2-user)
ssh -i .ssh/call-training.pem ec2-user@ec2-3-133-106-98.us-east-2.compute.amazonaws.com

# .bashrc
sudo hostnamectl set-hostname docker_project
export PS1="\[\e[1;34m\]\u\[\e[33m\]@\h# \W:\[\e[32m\]\\$\[\e[m\] "
```

# Install Docker

```bash
# Update the installed packages and package cache on your instance.
sudo dnf update -y
# Install the most recent Docker Community Edition package.
sudo dnf install docker -y  # sudo amazon-linux-extras install docker -y
# Start docker service.
sudo systemctl start docker
# Enable docker service so that docker service can restart automatically after reboots.
sudo systemctl enable docker
# Check if the docker service is up and running.
sudo systemctl status docker
whoami # --->>>  ec2-user
# Add the `ec2-user` to the `docker` group to run docker commands without using `sudo`
sudo usermod -a -G docker ec2-user
# Normally, the user needs to re-login into bash shell for the group `docker` to be effective, but `newgrp` command can be used activate `docker` group for `ec2-user`, not to re-login into bash shell.
newgrp docker
# Check the docker version without `sudo`
docker version  # docker --version = docker -v
```

```bash
pwd   # home/ec2-user
mkdir kittens-apache
cd kittens-apache

sudo dnf install tree -y
tree
.
    ├── Solution.md
    ├── Dockerfile
    └── myapp
        ├── cat0.jpg
        ├── cat1.jpg
        ├── cat2.jpg
        └── index.html
```

# Building Docker Image with Dockerfile

- Create a Dockerfile listing necessary packages and modules, and name it `Dockerfile`.

```Dockerfile
FROM ubuntu:latest
RUN apt-get update -y 
RUN apt install -y apache2 
RUN apt install -y apache2-utils 
COPY /myapp /var/www/html/
EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]

# OR

FROM httpd:latest 
COPY ./myapp/ /usr/local/apache2/htdocs/
WORKDIR /usr/local/apache2/htdocs/
EXPOSE 80
```

```bash (pwd: kittens-apache)
docker build -t arrow-image3 .

docker image ls
    REPOSITORY     TAG       IMAGE ID       CREATED         SIZE
    arrow-image3   latest    4515d9d28cc0   5 seconds ago   228MB
    ubuntu         latest    08d22c0ceb15   2 weeks ago     77.8MB

docker run -d --name arrow_container3 -p 80:80 arrow-image3     # OR  -p 80:80    ===>>>    --network host 
    86f5c8b5c03eeb75bed869177cc6d5cb50255714599f899da402d3fe7971f269

docker container ls

# ec2-instance public IP -->> browser: http://52.201.220.206/

docker rm -f $(docker ps -aq)   # delete all containers

docker image prune -af          # delete all images
```