terraform {
  required_version = ">= 1.7.0"

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

  cloud {
    organization = "platform-engineering-demo-ojaswi"

    workspaces {
      name = "cnc-logging-dev"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "PlatformTeam"
      Environment = var.environment
      Project     = "CloudNative-Commerce-infra"
    }
  }
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}

# Random suffix to avoid bucket name conflict
resource "random_id" "suffix" {
  byte_length = 2
}

# ---------------- VARIABLES ----------------

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_prefix" {
  type    = string
  default = "cnc-logs"
}

variable "owner_email" {
  type    = string
  default = "ojaswi1903@gmail.com"
}

# ---------------- S3 BUCKET ----------------

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.environment}-${random_id.suffix.hex}"

  tags = {
    Owner = var.owner_email
  }
}

# Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_sse" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning enabled
resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "logs_public_block" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output
output "bucket_arn" {
  value = aws_s3_bucket.logs.arn
}
