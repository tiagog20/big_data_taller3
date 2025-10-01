terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Buscar la AMI más reciente de Ubuntu 22.04
data "aws_ami" "this" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Security Group (solo salida, sin SSH)
resource "aws_security_group" "this" {
  name        = "allow_outbound"
  description = "Allow all outbound traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role para SSM
resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Adjuntar política de SSM al rol
resource "aws_iam_role_policy_attachment" "ssm_role_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile para la EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Instancia EC2 con Python + DuckDB gestionada por SSM
resource "aws_instance" "this" {
  ami                         = data.aws_ami.this.id
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.this.name]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y python3 python3-pip
              python3 -m pip install --upgrade pip setuptools wheel
              pip3 install duckdb
              EOF

  tags = {
    Name = "EC2-SSM-Python-DuckDB"
  }
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.this.public_ip
}

output "instance_public_dns" {
  value = aws_instance.this.public_dns
}

output "instance_id" {
  value = aws_instance.this.id
}