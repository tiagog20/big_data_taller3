terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    ## homework:start
    bucket = ...
    key = ...
    region = ...
    ## homework:end
    # use_lockfile = true
    profile    = "ExpertiseBuilding"
    encrypt    = true
    kms_key_id = "a706e211-659a-4c40-b368-88033573f8f7"
  }
}

provider "aws" {
  ## homework:start
  profile = ...
  ## homework:end
  region = "us-east-1"

  default_tags {
    tags = {
      Topic = "terraform"
      ## homework:start
      Owner = ...
      ## homework:end
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  ## homework:start
  
  ## homework:end
}
