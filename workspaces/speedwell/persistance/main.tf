terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  prefix      = "speedwell"
  region      = "eu-central-1"
  tenant      = "speedwell"
  environment = "dev"
  component   = "datalake"
  buckets = {
    speedwell-datalake-config-dev = {
      name = "speedwell-speedwell-datalake-config-dev"
    }
    speedwell-datalake-dev = {
      name = "speedwell-speedwell-datalake-storage-dev"
    }
    speedwell-datalake-ingestion-dev = {
      name = "speedwell-speedwell-datalake-ingestion-dev"
    }
    speedwell-datalake-raw-dev = {
      name = "speedwell-speedwell-datalake-raw-dev"
    }
  }
  tags = {
    tenant      = "speedwell"
    environment = "dev"
    component   = "datalake"
  }
}

resource "aws_s3_bucket" "buckets" {
  for_each = local.buckets
  bucket   = each.value.name
  tags     = local.tags
}

resource "aws_s3_object" "object" {
  bucket  = aws_s3_bucket.buckets["speedwell-datalake-ingestion-dev"].bucket
  key     = "records/1.txt"
  content = "1,2,3,4,5"
}


output "bucket_name" {
  value = aws_s3_bucket.buckets["speedwell-datalake-dev"].bucket
}
