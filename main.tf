# See https://confluence.dell.com/display/DD/TF+DDC+Resource+-+Library+VM for reference.
provider "aws" {
  region     = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-024e6efaf93d85776" # specifies EC2 image
  instance_type = "t2.micro"              # specifies EC2 instance type

  tags = {
    Name = "ubuntu-1"
  }
}
