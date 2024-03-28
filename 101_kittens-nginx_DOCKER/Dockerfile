FROM nginx:latest
RUN apt-get update -y
COPY /myapp /usr/share/nginx/html
EXPOSE 80 	
CMD ["nginx", "-g", "daemon off;"]

### OR 

# FROM nginx
# COPY /myapp /usr/share/nginx/html
# RUN chmod 644 /usr/share/nginx/html/index.html
# EXPOSE 80


### nginx example  (helloworld) , IT IS NOT ABOUT THIS APP
# FROM nginx
# ADD https://raw.githubusercontent.com/letsencrypt/helloworld/master/index.html /usr/share/nginx/html/index.html
# RUN chmod 644 /usr/share/nginx/html/index.html
# EXPOSE 80
