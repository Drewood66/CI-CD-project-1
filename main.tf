terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Connects to the S3 bucket and lock table you created with the AWS CLI
  backend "s3" {
    bucket         = "my-resume-tf-state-bucket" 
    key            = "dev/project.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "us-east-1"
}

# Serverless Database
resource "aws_dynamodb_table" "urls" {
  name         = "short-urls"
  billing_mode = "PAY_PER_REQUEST" # Serverless on-demand pricing
  hash_key     = "short_id"
  
  attribute {
    name = "short_id"
    type = "S"
  }
}

# Container Repository (Where GitHub Actions will push your Docker image)
resource "aws_ecr_repository" "app" {
  name                 = "url-shortener-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Serverless Container Cluster (ECS Fargate)
resource "aws_ecs_cluster" "main" {
  name = "resume-project-cluster"
}
