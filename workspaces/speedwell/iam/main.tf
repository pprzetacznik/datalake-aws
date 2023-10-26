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
  component   = "iam"
  buckets = {
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
    component   = "iam"
  }
}

resource "aws_iam_user" "speedwell_admin" {
  name = "speedwell_admin"
  path = "/"
  tags = local.tags
}

data "aws_iam_policy_document" "full_access" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "full_access_policy" {
  name   = "speedwell_admin_full_access"
  user   = aws_iam_user.speedwell_admin.name
  policy = data.aws_iam_policy_document.full_access.json
}

resource "aws_iam_user" "datalake_admin_user" {
  name = "speedwell_datalake_admin_user"
  path = "/"
  tags = local.tags
}

resource "aws_iam_user" "datalake_de_user" {
  name = "speedwell_datalake_de_user"
  path = "/"
  tags = local.tags
}

data "aws_iam_policy_document" "speedwell_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datalake_admin_role" {
  name                  = "${local.tenant}_firehose_role"
  assume_role_policy    = data.aws_iam_policy_document.speedwell_instance_assume_role_policy.json
  force_detach_policies = true
  tags                  = local.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ingestion_lambda_role" {
  name               = "${local.tenant}_ingestion_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}


resource "aws_iam_role_policy_attachment" "ingestion_lambda_role_attachment" {
  role       = aws_iam_role.ingestion_lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "speedwell_lambda_ingestion_s3_config_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kinesis:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      "arn:aws:s3:::${local.buckets["speedwell-datalake-ingestion-dev"].name}",
      "arn:aws:s3:::${local.buckets["speedwell-datalake-ingestion-dev"].name}/*"
    ]
  }
}

resource "aws_iam_policy" "speedwell_lambda_ingestion_s3_config_policy" {
  name        = "${local.tenant}_lambda_ingestion_s3_config_policy"
  description = "Policy allowing lambda to fetch config zip from s3"
  policy      = data.aws_iam_policy_document.speedwell_lambda_ingestion_s3_config_policy_document.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_ingestion_s3_attachment" {
  role       = aws_iam_role.ingestion_lambda_role.name
  policy_arn = aws_iam_policy.speedwell_lambda_ingestion_s3_config_policy.arn
}
