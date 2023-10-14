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
  role_firehose_kinesis_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/speedwell_firehose_role"
  role_firehose_kinesis_id = "speedwell_firehose_role"
  role_ingestion_lambda_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/speedwell_iam_for_lambda"
}

data "aws_caller_identity" "current" {}


# resource "aws_lakeformation_resource" "datalake-dev" {
#   arn = aws_s3_bucket.buckets["speedwell-datalake-dev"].arn
# }
#
resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "${local.tenant}-blog"

  # create_table_default_permission {
  #   permissions = ["SELECT"]
  #
  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "${local.tenant}-blog-table"
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${local.buckets["speedwell-datalake-ingestion-dev"].name}/event-streams/my-stream"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "my-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }
    columns {
      name = "my_string"
      type = "string"
    }
    columns {
      name = "my_double"
      type = "double"
    }
    columns {
      name    = "my_date"
      type    = "date"
      comment = ""
    }
    columns {
      name    = "my_bigint"
      type    = "bigint"
      comment = ""
    }
  }
}

# resource "aws_iam_role" "datalake_admin_role" {
#   name = "speedwell_datalake_admin_role"
#
#   assume_role_policy    = data.aws_iam_policy_document.glue_assume_role.json
#   force_detach_policies = true
#
#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   # assume_role_policy = jsonencode({
#   #   Version = "2012-10-17"
#   #   Statement = [
#   #     {
#   #       Action = "sts:AssumeRole"
#   #       Effect = "Allow"
#   #       Sid    = ""
#   #       Principal = {
#   #         Service = "ec2.amazonaws.com"
#   #       }
#   #     },
#   #   ]
#   # })
#   inline_policy {
#     name = "speedwell_datalake_admin_policy"
#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Action   = ["*"]
#           Effect   = "Allow"
#           Resource = "*"
#         },
#       ]
#     })
#   }
#
#   inline_policy {
#     name = "speedwell_datalake_whisperer_policy"
#     policy = jsonencode({
#       Version   = "2012-10-17"
#       Statement = [
#         {
#           Action   = [
#             "codewhisperer:GenerateRecommendations",
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#           Sid      = "CodeWhispererPermissions"
#         },
#       ]
#     })
#   }
#   tags = local.tags
# }
#
# data "aws_iam_policy_document" "glue_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["glue.amazonaws.com"]
#     }
#   }
# }
#
# data "aws_iam_policy_document" "application" {
#   statement {
#     actions = ["s3:ListObjects", "s3:ListBucket", "s3:HeadObject", "s3:GetObject", "s3:PutObject"]
#     resources = [
#       aws_s3_bucket.buckets["speedwell-datalake-dev"].arn,
#       "${aws_s3_bucket.buckets["speedwell-datalake-dev"].arn}/*"
#      ]
#   }
#   statement {
#     actions = ["s3:ListBucket", "s3:HeadObject", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
#     resources = [
#       aws_s3_bucket.buckets["speedwell-datalake-dev"].arn,
#       "${aws_s3_bucket.buckets["speedwell-datalake-dev"].arn}/*"
#     ]
#   }
#   statement {
#     actions   = ["lakeformation:GetDataAccess"]
#     resources = ["*"]
#   }
#
#   statement {
#     actions   = ["kms:Decrypt"]
#     resources = ["*"]
#   }
# }
#
# resource "aws_iam_role_policy" "application" {
#   name   = aws_iam_role.datalake_admin_role.name
#   role   = aws_iam_role.datalake_admin_role.id
#   policy = data.aws_iam_policy_document.application.json
# }
#
# data "aws_caller_identity" "current" {}
#
# data "aws_iam_session_context" "current" {
#   arn = data.aws_caller_identity.current.arn
# }
#
# resource "aws_lakeformation_data_lake_settings" "main" {
#   admins = [data.aws_iam_session_context.current.issuer_arn]
# }
#
# # resource "aws_lakeformation_data_lake_settings" "example" {
# #   admins = [aws_iam_role.datalake_admin_role.arn, aws_iam_user.datalake_admin_user.arn]
# #
# #   # create_database_default_permissions {
# #   #   # permissions = ["SELECT", "ALTER", "DROP"]
# #   #   permissions = ["ALL"]
# #   #   principal   = aws_iam_role.datalake_admin.arn
# #   # }
# # }
#
# resource "aws_lakeformation_permissions" "test" {
#   principal = aws_iam_role.datalake_admin_role.arn
#   permissions = ["ALL"]
#   # permissions = ["SELECT"]
#   # lf_tag {
#   #   key = "module"
#   #   values = ["blog"]
#   # }
#   lf_tag_policy {
#     resource_type = "DATABASE"
#     expression {
#       key    = "module"
#       values = ["blog"]
#     }
#   }
# }
#
# resource "aws_iam_role_policy_attachment" "datalake_admin_role_attachment" {
#   role       = aws_iam_role.datalake_admin_role.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
# }
#
# resource "aws_iam_user_policy_attachment" "datalake_admin_user_attachment" {
#   user       = aws_iam_user.datalake_admin_user.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
# }
#
# resource "aws_iam_user_policy_attachment" "datalake_de_user_attachment" {
#   user       = aws_iam_user.datalake_de_user.id
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
# }

resource "aws_lakeformation_lf_tag" "datalake_module_tags" {
  key    = "module"
  values = ["blog", "invoices", "mails"]
}

resource "aws_lakeformation_permissions" "firehose_role_glue_permission" {
  permissions = ["ALL"]
  principal   = local.role_firehose_kinesis_arn

  table {
    database_name = aws_glue_catalog_table.aws_glue_catalog_table.database_name
    name          = aws_glue_catalog_table.aws_glue_catalog_table.name
  }
}

# resource "aws_lakeformation_permissions" "application" {
#   principal   = aws_iam_role.datalake_admin_role.arn
#   permissions = ["ALL"]
#
#   lf_tag_policy {
#     resource_type = "DATABASE"
#
#     expression {
#       key    = aws_lakeformation_lf_tag.datalake_module_tags.key
#       values = ["blog"]
#     }
#   }
# }
#
# resource "aws_lakeformation_permissions" "datalake_permissions" {
#   principal = aws_iam_user.datalake_admin_user.arn
#   permissions = ["ALL"]
#   # permissions = ["ASSOCIATE"]
#   # permissions = ["SELECT"]
#   # lf_tag {
#   #   key = "module"
#   #   values = ["blog"]
#   # }
#
#   catalog_id = aws_glue_catalog_database.aws_glue_catalog_database.catalog_id
#
#   lf_tag_policy {
#     catalog_id = aws_glue_catalog_database.aws_glue_catalog_database.catalog_id
#     resource_type = "DATABASE"
#     expression {
#       key    = aws_lakeformation_lf_tag.datalake_module_tags.key
#       values = ["blog"]
#     }
#   }
# }
#
# resource "aws_lakeformation_permissions" "datalake_permissions2" {
#   principal = aws_iam_user.datalake_de_user.arn
#   permissions = ["ALL"]
#   # permissions = ["ASSOCIATE"]
#   # permissions = ["SELECT"]
#   # lf_tag {
#   #   key = "module"
#   #   values = ["blog"]
#   # }
#
#   catalog_id = aws_glue_catalog_database.aws_glue_catalog_database.catalog_id
#
#   lf_tag_policy {
#     resource_type = "TABLE"
#     expression {
#       key    = aws_lakeformation_lf_tag.datalake_module_tags.key
#       values = ["blog"]
#     }
#   }
# }
#
# resource "aws_lakeformation_permissions" "raw" {
#   principal   = aws_iam_user.datalake_admin_user.arn
#   permissions = ["DATA_LOCATION_ACCESS"]
#
#   data_location {
#     arn = aws_lakeformation_resource.datalake-dev.arn
#   }
# }

resource "aws_lakeformation_resource_lf_tags" "datalake_blog" {
  table {
    database_name = aws_glue_catalog_table.aws_glue_catalog_table.database_name
    name          = aws_glue_catalog_table.aws_glue_catalog_table.name
  }
  lf_tag {
    key   = "module"
    value = "blog"
  }
}

resource "aws_kinesis_stream" "ingestion_raw_stream" {
  name             = "speedwell-kinesis-ingestion"
  shard_count      = 1
  retention_period = 48
  tags             = local.tags
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "speedwell-kinesis-firehose-extended-s3-test-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.ingestion_raw_stream.arn
    role_arn           = local.role_firehose_kinesis_arn
    # "arn:aws:iam::264507407490:role/service-role/KinesisFirehoseServiceRole-KDS-S3-64E-eu-central-1-1696495098694"
  }

  extended_s3_configuration {
    role_arn   = local.role_firehose_kinesis_arn
    # role_arn   = aws_iam_role.firehose_role.arn
    # role_arn   = "arn:aws:iam::264507407490:role/service-role/KinesisFirehoseServiceRole-KDS-S3-64E-eu-central-1-1696495098694"
    bucket_arn = "arn:aws:s3:::${local.buckets["speedwell-datalake-raw-dev"].name}"

    buffering_size = 64

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "data/my_string=!{partitionKeyFromQuery:my_string}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"


    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.aws_glue_catalog_table.database_name
        table_name    = aws_glue_catalog_table.aws_glue_catalog_table.name
        role_arn      = local.role_firehose_kinesis_arn
      }
    }

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{my_string:.my_string}"
        }
      }
    }
  }
  tags = local.tags
}






resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${local.buckets["speedwell-datalake-ingestion-dev"].name}"
}

data "archive_file" "python_lambda_ingestion_package" {
  type        = "zip"
  source_file = "${path.root}/lambda_ingestion/lambda_function.py"
  output_path = "lambda_ingestion.zip"
}

resource "aws_lambda_function" "ingestion_lambda_function" {
  function_name = "lambda_ingestion"
  filename      = "lambda_ingestion.zip"
  source_code_hash = data.archive_file.python_lambda_ingestion_package.output_base64sha256
  layers = [
    "arn:aws:lambda:eu-central-1:336392948345:layer:AWSSDKPandas-Python311:2",
  ]
  role    = local.role_ingestion_lambda_arn
  runtime = "python3.11"
  handler = "lambda_function.lambda_handler"
  timeout = 10
  tags    = local.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = local.buckets["speedwell-datalake-ingestion-dev"].name
  lambda_function {
    lambda_function_arn = aws_lambda_function.ingestion_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".csv"
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_cloudwatch_event_rule" "test-lambda" {
  name                = "run-lambda-function"
  description         = "Schedule lambda function"
  schedule_expression = "rate(60 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda-function-target" {
  target_id = "lambda-function-target"
  rule      = aws_cloudwatch_event_rule.test-lambda.name
  arn       = aws_lambda_function.ingestion_lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.test-lambda.arn
}

resource "aws_iam_role_policy" "speedwell_firehose_role_policy" {
  name = "speedwell_firehose_role_policy"
  role = local.role_firehose_kinesis_id
  policy = templatefile("kinesis_firehose_role.json",
    {
      account_number_list   = ["123", "456", "789"],
      kinesis_stream_arn    = aws_kinesis_stream.ingestion_raw_stream.arn,
      kinesis_target_bucket = local.buckets["speedwell-datalake-raw-dev"].name
    }
  )
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

# TODO LakeFormation permissions for speedwell-table
