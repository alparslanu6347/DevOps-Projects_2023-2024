#! /bin/bash
dnf update -y
hostnamectl set-hostname ${manager-name}
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
aws ec2 wait instance-status-ok --instance-ids ${leader_id}
ssh-keygen -t rsa -f /home/ec2-user/clarus_key -q -N ""
aws ec2-instance-connect send-ssh-public-key --region ${region} --instance-id ${leader_id} --instance-os-user ec2-user --ssh-public-key file:///home/ec2-user/clarus_key.pub \
&& eval "$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
-i /home/ec2-user/clarus_key ec2-user@${leader_privateip} docker swarm join-token manager | grep -i 'docker')"