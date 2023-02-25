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
Then I need to provision .conf configuration file for nginx web server.<br>
<br>
Nginx - web server that has gained popularity in recent years due to its speed and efficiency in handling a large number of concurrent connections.Nginx is known for its low memory usage and ability to handle high traffic with less hardware resources. It also supports multiple programming languages, but is most commonly used as a reverse proxy, load balancer, or HTTP cache server.
<br>
That's how I provision .conf file:<br>

```tf
provisioner "file" {
    source = "mywebsite.conf"
    destination = "/home/ec2-user/mywebsite.conf"
```
<br>
File content:<br>

```tf
server {
    listen 80;
    server_name mywebsitedockertest.pp.ua;

    location / {
        proxy_pass http://localhost:8080;
    }
}
```
Here I specified port in listen line and my domain name in server_name line.<br>

After that, I created the `provisioner "remote-exec"` block with specific commands:<br>

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
<li> "sudo yum update -y" </li>
Simple update of all packages on a new instance.
<li> "sudo amazon-linux-extras install nginx1 -y" </li>
Installation of nginx.
<li> "sudo systemctl start/enable nginx" </li>
Starting and enabling nginx service.
<li>"sudo yum install docker -y"</li>
Installation of Docker.
<li>"sudo systemctl start/enable docker"</li>
Starting and enabling docker service.
<li>"sudo docker pull maksymrzd/mywebsite:v3"</li>
Pulling required image.
<li>"sudo docker run -d -p 8080:80 maksymrzd/mywebsite:v3"</li>
Running container on port 8080.
<li>"sudo mv mywebsite.conf /etc/nginx/conf.d/"</li>
Moving nginx configuration file to the needed directory.
<li>"sudo nginx -t"</li>
Checking nginx performance.
<li>"sudo systemctl restart nginx"</li>
Restarting nginx service for proper work.
</ul>

Finally, I added the resource `aws_eip`, which is an Elastic IP.<br>

```tf
resource "aws_eip" "elasticip" {
  instance = aws_instance.dockerhostinstance.id
  vpc      = true
```

The entire terraform code should look like this:<br>

```tf
provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "dockerhostinstance" {
  ami                    = "ami-0c0d3776ef525d5dd"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.dockersg.id]
  key_name               = "aws_key"

  tags = {
    Name = "Docker image hosting"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("aws_key.pem")
  }

  provisioner "file" {
    source = "mywebsite.conf"
    destination = "/home/ec2-user/mywebsite.conf"
  }

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
}

resource "aws_security_group" "dockersg" {
  dynamic "ingress" {
    for_each = ["80", "22", "443"]
    content {
      description = "HTTP, HTTPS, SSH ports"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "elasticip" {
  instance = aws_instance.dockerhostinstance.id
  vpc      = true
}

```

Let's move to the next step.<br>
<h3 align="left">Step #3: DNS</h3>
In this step I create my own domain name and hosted zone in Route 53, and then connect them.<br>
Firstly, I went to Route 53 and created the hosted zone with the name of my domain name:<br>

![image](https://user-images.githubusercontent.com/114437342/221364756-40371bce-1e71-45ae-883a-679ba6e55f66.png)
<br>
Here I added my instance elastic ip as a new record:<br>

![image](https://user-images.githubusercontent.com/114437342/221364867-65d98f1e-a009-413b-9d4f-e6e7e513826f.png)
<br>
After that I went to my domain name settings and added those values from the screen above:<br>

![image](https://user-images.githubusercontent.com/114437342/221365024-1cbc7784-c1c7-4690-9c32-2a0fde0e36ca.png)
<br>

Now we can proceed to the last step.<br>

<h3 align="left">Final step: Check</h3>

When all step above are finished, we can open our website link and verify that it's working perfectly!<br>

![image](https://user-images.githubusercontent.com/114437342/221338288-012985be-8b80-4dad-8a2f-bb245c5f4a14.png)
