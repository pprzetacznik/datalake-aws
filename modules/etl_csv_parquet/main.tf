resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name_ingestion}"
}

data "archive_file" "python_lambda_ingestion_package" {
  type        = "zip"
  source_file = "${path.root}/lambda_ingestion/lambda_function.py"
  output_path = "lambda_ingestion.zip"
}

resource "aws_lambda_function" "ingestion_lambda_function" {
  function_name    = "lambda_ingestion"
  filename         = "lambda_ingestion.zip"
  source_code_hash = data.archive_file.python_lambda_ingestion_package.output_base64sha256
  layers = [
    "arn:aws:lambda:eu-central-1:336392948345:layer:AWSSDKPandas-Python311:2",
  ]
  role    = var.role_ingestion_lambda_arn
  runtime = "python3.11"
  handler = "lambda_function.lambda_handler"
  timeout = 10
  environment {
    variables = {
      "LAMBDA_INGESTION_STREAM_NAME" = aws_kinesis_stream.ingestion_raw_stream.name
      "LAMBDA_INGESTION_STREAM_ARN" = aws_kinesis_stream.ingestion_raw_stream.arn
    }
  }
  tags    = var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name_ingestion
  lambda_function {
    lambda_function_arn = aws_lambda_function.ingestion_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".csv"
  }
  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_kinesis_stream" "ingestion_raw_stream" {
  name             = "${var.prefix}-${var.tenant}-kinesis-ingestion"
  shard_count      = 1
  retention_period = 48
  tags             = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${var.prefix}-kinesis-firehose-extended-s3-test-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.ingestion_raw_stream.arn
    role_arn           = var.role_firehose_kinesis_arn
  }

  extended_s3_configuration {
    role_arn   = var.role_firehose_kinesis_arn
    bucket_arn = "arn:aws:s3:::${var.bucket_name_raw}"

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
        database_name = var.database_name
        table_name    = var.table_name
        role_arn      = var.role_firehose_kinesis_arn
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
  tags = var.tags
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

resource "aws_iam_role_policy" "firehose_role_policy" {
  name = "${var.prefix}_${var.tenant}_firehose_role_policy"
  role = var.role_firehose_kinesis_id
  policy = templatefile("kinesis_firehose_role.json",
    {
      kinesis_stream_arn    = aws_kinesis_stream.ingestion_raw_stream.arn,
      kinesis_target_bucket = var.bucket_name_raw,
      aws_account_id        = var.aws_account_id,
      region                = var.region,
      database_name         = var.database_name,
      table_name            = var.table_name,
      kinesis_stream_name   = aws_kinesis_stream.ingestion_raw_stream.name
    }
  )
}
