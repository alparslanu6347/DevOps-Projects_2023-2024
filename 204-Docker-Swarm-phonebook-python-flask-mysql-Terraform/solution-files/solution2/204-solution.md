- Go to AWS Management Console and launch an EC2 instance using the Amazon Linux 2023 AMI with security group allowing SSH & HTTP connections.

- Connect to your instance with SSH.

```bash
ssh -i .ssh/project.pem ec2-user@ec2-3-133-106-98.us-east-2.compute.amazonaws.com
# .bashrc
hostnamectl set-hostname phonebook_instance
export PS1="\[\e[1;34m\]\u\[\e[33m\]@\h# \W:\[\e[32m\]\\$\[\e[m\] "
```

- AWS configuration , Alternetive way: Attach admin role to the instance

```bash
aws configure
```

- Install Terraform and git

```bash
sudo dnf update -y
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf -y install terraform
sudo dnf install git
```

- Go to github and create a public repo named phonebook.
- clone the project repo to the phone_instance

```bash
git clone https://***github-user***:***TOKEN***@github.com/alparslanu6347/phonebook.git
git clone https://alparslanu6347:***TOKEN***@github.com/alparslanu6347/phonebook.git
cd phonebook
```

- Copy the `init.sql`, `phonebook-app.py`, `requirements.txt` files and `templates` folder to the `phonebook` folder.

```bash (pwd : phonebook)
ls  # init.sql    phonebook-app.py    requirements.txt    templates
```

- Create a Dockerfile.

```Dockerfile
FROM python:alpine
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . /app
WORKDIR /app
RUN addgroup -S myappgroup && adduser -S myappuser -G myappgroup
USER myappuser
EXPOSE 80   # app.run(host='0.0.0.0', port=80)   coming from application
CMD python ./phonebook-app.py
```

- Create a `docker-compose.yaml` file as below.

```yaml
version: "3.8"

services:
  database:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: P123456p
      MYSQL_DATABASE: phonebook_db
      MYSQL_USER: admin
      MYSQL_PASSWORD: Clarusway_1
    configs:
      - source: table
        target: /docker-entrypoint-initdb.d/init.sql
    networks:
      - clarusnet
  app-server:
    image: phonebook_image  # This line will be used for getting the ECR image name dynamically.
    deploy:
      replicas: 3
      update_config:
        parallelism: 2
        delay: 5s
        order: start-first
    ports:
      - "80:80"
    networks:
      - clarusnet

networks:
  clarusnet:

configs:
  table:  # name of the config
    file: ./init.sql
```

```bash (pwd : phonebook)
ls  # init.sql    phonebook-app.py    requirements.txt    templates   Dockerfile    docker-compose.yaml
```

- Push files to the `phonebook` repo

```bash (pwd : phonebook)
git add .
git commit -m "first commit"
git push
```

- Create a folder named `terraform-phonebook` and create `leader.sh , manager.sh, worker.sh, swarm.tf`

```bash
cd
mkdir terraform-phonebook && cd terraform-phonebook
terraform init
terraform apply
```