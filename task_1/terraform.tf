terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  ## homework:start
  
  ## homework:end
  region = "us-east-1"

  default_tags {
    tags = {
      Topic = "terraform"
      ## homework:start
      Owner = "Santiago"
      ## homework:end
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  ## homework:start
  bucket = "miprimeracana"
  ## homework:end
}
