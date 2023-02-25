<h1 align="center">Hosting website on AWS<br>Using Docker and nginx</h1>

<h2 align="left">Getting started</h2>
<h3 align="left">Step #1: Docker Image</h3>
Firstly, I created a simple image of my website using docker and pushed my image to Docker Hub.<br>
To do this, I made a Dockerfile with following configuration:

```tf
FROM nginx:latest

COPY . /usr/share/nginx/html
```

It simply copies all the files(html and css) to specific folder.<br>
<br>
After creating the Dockerfile, we have to build it and push it to Docker Hub:

```tf
docker build -t maksymrzd/mywebsite:v3 .
docker push maksymrzd/mywebsite:v3
```

Now we can proceed to the next step. <br>
<h3 align="left">Step #2: Terraform</h3>
