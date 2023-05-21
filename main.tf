# 
provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id] # uses the ID of the default VPC
  }
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-024e6efaf93d85776" # specifies EC2 image
  instance_type   = "t2.micro"              # specifies EC2 instance type
  security_groups = [aws_security_group.ubuntu.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "ubuntu-EC2" {
  ami           = "ami-024e6efaf93d85776" # specifies EC2 image
  instance_type = "t2.micro"              # specifies EC2 instance type

  vpc_security_group_ids = [aws_security_group.ubuntu.id] # reference expression to security group resource

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "ubuntu-1"
  }
}

resource "aws_security_group" "ubuntu" {
  name = "web"

  ingress {
    description = "allow-traffice-from-port-8080"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows any IP address to access port 8080
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids # instruct ASG to use subnets in the default VPC

  # direct integration between ASG and ELB
  # default healthcheck is EC2, only considers unhealthy if AWS hypervisor reports that VM is down or unreachable
  # the ELB healthcheck if more thoroughh, as it instructs ASG to use lb_target_group health check to check if instance is healthy
  target_group_arns = [aws_alb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 10

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name               = "web"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id] # use alb security group
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "web-alb"

  # Allow inbopund HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound HTTP requests, so that load balancer can conduct health checsk
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_alb_target_group" "asg" {
  name     = "web-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.asg.arn
  }

}
