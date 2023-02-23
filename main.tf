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
