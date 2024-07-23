terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-mysql-2024"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lock-state-mysql-2024"
  }
}

provider "aws" {
  region = var.aws_region
}


