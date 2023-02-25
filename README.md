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
After creating the Dockerfile, I had to build it and push it to Docker Hub:

```tf
docker build -t maksymrzd/mywebsite:v3 .
docker push maksymrzd/mywebsite:v3
```

![image](https://user-images.githubusercontent.com/114437342/221334852-a42f45f4-bcad-4cbe-89a6-c4cba4093b07.png)

Now we can proceed to the next step. <br>
<h3 align="left">Step #2: Terraform</h3>
Here I wrote a simple code for creating an instance and attaching the security group to it.<br>
Then I added the connection block, which uses access keys to connect.<br>
After that, I created the `provisioner "remote-exec"` block with specific commands:

```tf
provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "sudo yum install docker -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker pull maksymrzd/mywebsite:v3",
      "sudo docker run -d -p 8080:80 maksymrzd/mywebsite:v3",
      "sudo mv mywebsite.conf /etc/nginx/conf.d/",
      "sudo nginx -t",
      "sudo systemctl restart nginx"
    ]
    }
```
<ul>
<li> `sudo yum update -y` </li>
Simple update of all packages on a new instance.
<li> `sudo amazon-linux-extras install nginx1 -y` </li>
Installation of nginx.
<li> `sudo systemctl start/enable nginx` </li>
Starting and enabling nginx service.
</ul>




