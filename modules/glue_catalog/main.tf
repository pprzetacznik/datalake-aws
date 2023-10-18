resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "${var.tenant}-blog"
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = "${var.tenant}-blog-table"
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${var.table_bucket_name}/event-streams/my-stream"
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
