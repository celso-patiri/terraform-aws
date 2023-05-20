variable "server_port" {
  description = "The port the server will use to handle HTTP requests"
  default     = 8080
  type        = number

  validation {
    condition = var.server_port > 0 && var.server_port < 65536
    error_message = "The server port must be between 1 and 65536"
  }

  sensitive = true # hide variable on output of certain commands, like plan
}
