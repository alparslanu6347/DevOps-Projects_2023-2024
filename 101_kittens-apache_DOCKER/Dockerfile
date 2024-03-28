FROM ubuntu:latest
RUN apt-get update -y 
RUN apt install -y apache2 
RUN apt install -y apache2-utils 
COPY /myapp /var/www/html/
EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]


# FROM httpd:latest 
# COPY ./myapp/ /usr/local/apache2/htdocs/
# WORKDIR /usr/local/apache2/htdocs/
# EXPOSE 80


