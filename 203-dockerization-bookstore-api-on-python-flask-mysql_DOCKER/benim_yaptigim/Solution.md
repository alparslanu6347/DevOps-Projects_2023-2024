```bash
mkdir bookstore
cd bookstore

tree    #tüm dosyalar bookstore klasörü içinde
    .
    ├── bookstore-api.py
    ├── docker-compose.yml
    ├── Dockerfile
    └── requirements.txt

docker-compose up -d
docker container ls
docker image ls
docker network ls
```

- http://52.3.241.41  (ec2 Public IP : 52.3.241.41)

```bash
docker rm -f $(docker ps -aq)  # tüm container'ları siler 
docker image prune -af  # tüm imajlari silmek icin
docker network rm ******  # network siler
```

# RESOURCES

- https://hub.docker.com/_/mysql
- https://docs.docker.com/compose/compose-file/compose-versioning/
- https://docs.docker.com/compose/profiles/
- https://github.com/docker/awesome-compose
- https://docs.docker.com/compose/gettingstarted/
- https://docs.docker.com/develop/develop-images/dockerfile_best-practices/