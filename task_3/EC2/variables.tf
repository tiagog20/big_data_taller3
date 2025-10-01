variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "public_ssh_key" {
  description = "Public key to be able to connect to the instance using ssh"
}

variable "ssh_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"] # You should restrict this for production
}

variable "user_data" {
    description = "Startup script to execute when creating an instance"
}