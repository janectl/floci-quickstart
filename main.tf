terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Override AWS endpoints to point to localhost:4566
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Force path-style addressing for local S3
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = "my-floci-test-bucket"
}

resource "aws_sqs_queue" "demo_queue" {
  name = "my-floci-test-queue"
}

output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "queue_url" {
  value = aws_sqs_queue.demo_queue.id
}