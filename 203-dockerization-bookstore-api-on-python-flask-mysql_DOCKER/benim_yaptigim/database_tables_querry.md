Database içine bağlanıp sorgulama yapacaksan:

```bash
docker exec -it bookstore-app ash  ## uygulama içeren container'a bağlan
apk add --no-cache mysql-client
mysql -u arrow -p -h bookstore-database  ## arrow_123
SHOW DATABASES;
USE bookstore_db;
SHOW TABLES;
SELECT * FROM books;


docker exec -it bookstore-database bash  ## database içeren container'a bağlan (container name : bookstore-database)
(-h:host=bookstore-database)  ==>> (container name : bookstore-database)
mysql -u root -p -h bookstore-database ## password : levent_123  (docker-compose.yml  içindeki MYSQL_ROOT_PASSWORD: levent_123)
mysql -u arrow -p -h bookstore-database  ## password : arrow_123  

(database name : bookstore_db )
mysql -u arrow -p bookstore_db  ## password : arrow_123   
mysql -u root -p bookstore_db   ## password : levent_123

SHOW DATABASES;
USE bookstore_db
SHOW TABLES;
SELECT * FROM books;

```