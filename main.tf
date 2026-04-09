provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "web" {
  name_prefix = "web-sg-"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-security-group"
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data = base64encode(<<-EOF
#!/bin/bash
yum update -y
yum install docker -y
systemctl enable docker
systemctl start docker
docker run -d -p 80:80 --restart unless-stopped ${var.docker_image}
EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-instance"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "web-asg"
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = data.aws_subnets.default.ids
  health_check_type    = "ELB"
  health_check_grace_period = 300
  target_group_arns    = [aws_lb_target_group.web.arn]
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_lb" "web" {
  name_prefix      = "web"
  internal         = false
  load_balancer_type = "network"
  subnets          = data.aws_subnets.default.ids
  tags = {
    Name = "web-nlb"
  }
}

resource "aws_lb_target_group" "web" {
  name_prefix = "web"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.default.id
  health_check {
    protocol = "TCP"
    port     = "80"
  }
  tags = {
    Name = "web-tg"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

data "aws_instances" "web" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.web.name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
  depends_on = [aws_autoscaling_group.web]
}