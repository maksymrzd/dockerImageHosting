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
}

resource "aws_security_group" "dockersg" {
  dynamic "ingress" {
    for_each = ["80", "22"]
    content {
      description = "HTTP, SSH ports"
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
