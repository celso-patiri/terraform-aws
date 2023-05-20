# 
provider "aws" {
  region = "us-east-2"
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
