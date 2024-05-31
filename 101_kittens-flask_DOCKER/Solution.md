
```bash
mkdir kittens
cd kittens

sudo yum install tree -y
tree
    .
    ├── command.txt
    ├── Dockerfile
    └── myapp
        ├── cat0.jpg
        ├── cat1.jpg
        ├── cat2.jpg
        └── index.html

docker build -t arrow-image2 .

docker image ls
    REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
    arrow-image2   latest    a2ec24ad0942   11 seconds ago   160MB
    nginx          latest    ac232364af84   2 days ago       142MB

docker run -d --name arrow_container2 -p 80:80 arrow-image2
    86f5c8b5c03eeb75bed869177cc6d5cb50255714599f899da402d3fe7971f269

docker container ls
```

- ec2 public IP al browser'a yapıştır (http://52.201.220.206/)

```bash
- docker rm -f $(docker ps -aq)   # tüm containerları siler

- docker image prune -af  # tum imajlari silmek icin
```