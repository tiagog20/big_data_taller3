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

# 🔹 Rol IAM para las instancias de EMR con soporte SSM
resource "aws_iam_role" "emr_ec2_role" {
  name = "emr-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 🔹 Adjuntar políticas necesarias
resource "aws_iam_role_policy_attachment" "emr_ssm_core" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "emr_default" {
  role       = aws_iam_role.emr_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

# 🔹 Instance Profile para EMR
resource "aws_iam_instance_profile" "emr_instance_profile" {
  name = "emr-ec2-ssm-profile"
  role = aws_iam_role.emr_ec2_role.name
}

# 🔹 Cluster EMR con Spark
resource "aws_emr_cluster" "spark_cluster" {
  name          = "spark-distributed-cluster"
  release_label = "emr-6.15.0"
  applications  = ["Hadoop", "Spark"]

  service_role = "EMR_DefaultRole"

  ec2_attributes {
    instance_profile = aws_iam_instance_profile.emr_instance_profile.name
    subnet_id        = "subnet-07f6a944113d15747" # 👈 pon aquí tu subnet válida
  }

  master_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 1
  }

  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
  }

  visible_to_all_users = true

  tags = {
    Name = "EMR-Spark-SSM"
  }
}

# 🔹 Outputs
output "emr_cluster_id" {
  value = aws_emr_cluster.spark_cluster.id
}

output "emr_master_dns" {
  value = aws_emr_cluster.spark_cluster.master_public_dns
}
