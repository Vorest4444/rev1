provider "aws" {
  region     = "us-east-2"
  access_key = var.accesskey
  secret_key = var.secretkey
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "Lab6SG" {

  name   = "Lab6SG"
  vpc_id = "vpc-05f8476e"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "Lab6alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Lab6SG.id]
  subnets            = ["subnet-d52b36af", "subnet-15da7d7e"]
}

resource "aws_instance" "ec2" {
  count           = 2
  ami             = "ami-0a0ad6b70e61be944"
  instance_type   = var.instance
  key_name        = var.keypair
  security_groups = [aws_security_group.Lab6SG.name]

  tags = {
    Name = format("Instance-%d", count.index)
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "Lab6tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-05f8476e"
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count            = length(aws_instance.ec2)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.ec2[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}