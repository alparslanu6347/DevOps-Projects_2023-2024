FROM python:alpine
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . /app
WORKDIR /app
RUN addgroup -S myappgroup && adduser -S myappuser -G myappgroup
USER myappuser
EXPOSE 80
CMD python ./phonebook-app.py