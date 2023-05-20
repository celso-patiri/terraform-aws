#
output "public_ip" {
    description = "The public IP of the web server"
    value = aws_instance.ubuntu-EC2.public_ip
    sensitive = false
}
