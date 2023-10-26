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
  role_firehose_kinesis_id  = "speedwell_firehose_role"
  role_firehose_kinesis_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/speedwell_firehose_role"
  role_ingestion_lambda_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/speedwell_ingestion_lambda"
}

data "aws_caller_identity" "current" {}

module "glue_catalog" {
  source                  = "../../../modules/glue_catalog"
  aws_caller_identity_arn = data.aws_caller_identity.current.arn
  prefix                  = local.prefix
  tenant                  = local.tenant
  component               = local.component
  environment             = local.environment
  table_bucket_name       = local.buckets["speedwell-datalake-ingestion-dev"].name
}

module "etl_csv_parquet" {
  source                    = "../../../modules/etl_csv_parquet"
  aws_account_id            = data.aws_caller_identity.current.account_id
  region                    = "eu-central-1"
  prefix                    = local.prefix
  tenant                    = local.tenant
  component                 = local.component
  environment               = local.environment
  tags                      = local.tags
  database_name             = module.glue_catalog.database_name
  table_name                = module.glue_catalog.table_name
  role_firehose_kinesis_arn = local.role_firehose_kinesis_arn
  role_firehose_kinesis_id  = local.role_firehose_kinesis_id
  role_ingestion_lambda_arn = local.role_ingestion_lambda_arn
  bucket_name_ingestion     = local.buckets["speedwell-datalake-ingestion-dev"].name
  bucket_name_raw           = local.buckets["speedwell-datalake-raw-dev"].name
}

resource "aws_lakeformation_lf_tag" "datalake_module_tags" {
  key    = "module"
  values = ["blog", "invoices", "mails"]
}

resource "aws_lakeformation_permissions" "firehose_role_glue_permission" {
  permissions = ["ALL"]
  principal   = local.role_firehose_kinesis_arn

  table {
    database_name = module.glue_catalog.database_name
    name          = module.glue_catalog.table_name
  }
}

resource "aws_lakeformation_resource_lf_tags" "datalake_blog" {
  table {
    database_name = module.glue_catalog.database_name
    name          = module.glue_catalog.table_name
  }
  lf_tag {
    key   = "module"
    value = "blog"
  }
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
