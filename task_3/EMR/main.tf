terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "random_id" "suffix" {
  byte_length = 3
}

# 🔍 VPC y Subnets default
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 📦 Bucket S3 para logs
resource "aws_s3_bucket" "emr_logs" {
  bucket        = "emr-logs-${random_id.suffix.hex}"
  force_destroy = true
}

# 🔐 IAM Roles
resource "aws_iam_role" "emr_service_role" {
  name = "emr-service-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "elasticmapreduce.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr_service_role_attach" {
  role       = aws_iam_role.emr_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "emr_ec2_role" {
  name = "emr-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr_ec2_role_attach" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

# 📌 Habilitar SSM en los nodos EC2
resource "aws_iam_role_policy_attachment" "emr_ec2_ssm_attach" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "emr_ec2_profile" {
  name = "emr-ec2-profile-${random_id.suffix.hex}"
  role = aws_iam_role.emr_ec2_role.name
}

# 🔒 Security Groups
resource "aws_security_group" "emr_master" {
  name        = "emr-master-sg-${random_id.suffix.hex}"
  description = "Allow SSH to EMR master"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ en producción restringe a tu IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "emr_slave" {
  name        = "emr-slave-sg-${random_id.suffix.hex}"
  description = "Allow all outbound from slaves"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ⚡ Cluster EMR
resource "aws_emr_cluster" "spark_cluster" {
  name          = "spark-emr-cluster"
  release_label = "emr-6.15.0"   # Spark 3.4 incluido
  applications  = ["Hadoop", "Spark"]
  service_role  = aws_iam_role.emr_service_role.name
  log_uri       = "s3://${aws_s3_bucket.emr_logs.bucket}/logs/"

  ec2_attributes {
    key_name                          = "emr-key"   # 🔑 asegúrate de tener este KeyPair en AWS
    instance_profile                  = aws_iam_instance_profile.emr_ec2_profile.arn
    subnet_id                         = data.aws_subnets.default.ids[0]
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_slave.id
  }

  master_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 1
  }

  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
  }

  keep_job_flow_alive_when_no_steps = true   # 👈 mantiene el cluster en estado WAITING

  tags = {
    Name = "EMR-Spark-Cluster"
  }
}

# 📤 Outputs
output "emr_master_dns" {
  value = aws_emr_cluster.spark_cluster.master_public_dns
}
