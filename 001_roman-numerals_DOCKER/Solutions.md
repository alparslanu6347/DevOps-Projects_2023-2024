## docker-instance (host) : Amazon Linux 2023 , t2.micro ###

# Launch a Docker Machine Instance `Amazon Linux 2023 AMI, t2.micro, ports: 22, 80`  and Connect with SSH

```bash
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

# Building Docker Image with Dockerfile

- dockerfile reference
[https://docs.docker.com/engine/reference/builder/]

```bash (home/ec2-user)
pwd   # home/ec2-user
mkdir roman-numerals
cd roman-numerals/
```

- Create application code and save it to file, and name it `romans.py`

```py (romans.py)
from flask import Flask, render_template, request

app = Flask(__name__)


def convert(decimal_num):
    roman = {1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC',
             50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'}
    num_to_roman = ''

    for i in roman.keys():
        num_to_roman += roman[i]*(decimal_num//i)
        decimal_num %= i
    return num_to_roman


@app.route('/', methods=['POST', 'GET'])
def main_post():
    if request.method == 'POST':
        alpha = request.form['number']
        if not alpha.isdecimal():
            return render_template('index.html', developer_name='Arrow', not_valid=True)
        number = int(alpha)
        if not 0 < number < 4000:
            return render_template('index.html', developer_name='Arrow', not_valid=True)
        return render_template('result.html', number_decimal=number, number_roman=convert(number), developer_name='Arrow')
    else:
        return render_template('index.html', developer_name='Arrow', not_valid=False)


if __name__ == '__main__':
    # app.run(debug=True)
    app.run(host='0.0.0.0', port=80)
```

- Create a Dockerfile listing necessary packages and modules, and name it `Dockerfile`.

```Dockerfile
FROM ubuntu
RUN apt-get update -y
RUN apt-get install python3 -y
RUN apt-get install python3-pip -y
RUN pip3 install flask
COPY . /app
WORKDIR /app
EXPOSE 80
CMD python3 ./romans.py
```



```bash (pwd : home/ec2-user/roman-numerals)   OR   (pwd : local/roman-numerals)
pwd   # roman-numerals
sudo dnf install tree -y
tree
.
    ├── commands.txt
    ├── Dockerfile
    ├── romans.py
    └── templates
        ├── index.html
        └── result.html
```

- Build your image

```bash (home/ec2-user/roman-numerals)
docker build -t "<Your_Docker_Hub_Account_Name>/<Your_Image_Name>:<Tag>" .
docker build -t "alparslanu6347/romans:1.0" .

docker image ls
    REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
    romans         latest    c9f7a2724a6e   11 seconds ago   473MB
    ubuntu         latest    08d22c0ceb15   2 weeks ago      77.8MB
```

- Run the newly built image as container in detached mode, connect host `port 80` to container `port 80`, and name container as `romans_container`. Then list running containers and connect to EC2 instance from the browser to see the app is running.

```bash (home/ec2-user/roman-numerals)
docker run -d --name romans_container -p 80:80 alparslanu6347/romans:1.0
    87fff02dbf00b6b3f1bb3930d71d88612f0e278d7238ea934f572e691e8764e7


##### OR YOU CAN USE 1 of THESE 2 COMMANDS
docker run -d --name romans_container --network host alparslanu6347/flask-app:2.0  #  host => use network of host/instance = -p 80:80
docker run --rm -d --name romans_container -p 80:80 alparslanu6347/romans:1.0   # When we use --rm with the container, it automatically deletes it when we stop it  (docker container stop romans_container  # when we stop it it will be deleted)

docker container ls
```
- Go to browser and check the application : `ec2-instance public IP -->> browser: http://52.201.220.206/`


- Login in to Docker with credentials.

```bash
docker login  # ***username***  , ***password***
```

- Push newly built image to Docker Hub, and show the updated repo on Docker Hub.

```bash
docker push <Your_Docker_Hub_Account_Name>/<Your_Image_Name>:<Tag>
docker push alparslanu6347/romans:1.0
```

- We can also tag the same image with different tags.

```bash
docker image tag alparslanu6347/romans:1.0 alparslanu6347/romans:latest
docker image ls

docker push alparslanu6347/romans:latest
```

- Go to [dockerhub](https://hub.docker.com/) and check your repositories (`repository = <Your_Docker_Hub_Account_Name>/<Your_Image_Name>`)


```bash (home/ec2-user/roman-numerals)
docker container ls
docker container stop romans_container
docker rm romans_container      # Deletes the container if it is not running   
docker rm -f romans_container   # Deletes the container even if it is running

docker image ls
docker image rm alparslanu6347/romans:1.0       #  The output "Untagged: alparslanu6347/flask-app:2.0" indicates that the specified tag has been unlinked from the image, essentially marking it as unused. As a result, the image is no longer listed under that specific tag..
docker image rm alparslanu6347/romans:latest    # deleted
docker image rm ubuntu

##### OR YOU CAN USE THESE 2 COMMANDS

docker rm -f $(docker ps -aq)   # delete all containers
docker image prune -af          # delete all images
```