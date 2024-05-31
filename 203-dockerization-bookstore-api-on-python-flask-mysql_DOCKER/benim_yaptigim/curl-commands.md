***  ec2 public dns değiştir. ***

```bash
curl --request POST \
--url 'http://ec2-44-197-245-177.compute-1.amazonaws.com/books' \
--header 'content-type: application/json' \
--data '{"author":"Paulo Coelho", "title":"The Alchemist", "is_sold":true}'


curl --request POST \
--url 'http://ec2-44-197-245-177.compute-1.amazonaws.com/books' \
--header 'content-type: application/json' \
--data '{"author":"Gabriel Garcia Marquez", "title":"One Hundred Years of Solitude", "is_sold":true}'


curl --request POST \
--url 'http://ec2-44-197-245-177.compute-1.amazonaws.com/books' \
--header 'content-type: application/json' \
--data '{"author":"Harper Lee", "title":"To Kill a Mockingbird", "is_sold":true}'


curl --request PUT \
--url 'http://ec2-44-197-245-177.compute-1.amazonaws.com/books/3' \
--header 'content-type: application/json' \
--data '{"author":"Jose Rodrigues dos Santos", "title":"A Formula de Deus", "is_sold":true}'


curl --request DELETE \
--url 'http://ec2-44-197-245-177.compute-1.amazonaws.com/books/2' \
--header 'content-type: application/json'

```