variable "region" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tenant" {
  type = string
}

variable "component" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "tags" {
  type = map
}

variable "database_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "role_firehose_kinesis_arn" {
  type = string
}

variable "role_firehose_kinesis_id" {
  type = string
}

variable "role_ingestion_lambda_arn" {
  type = string
}

variable "bucket_name_ingestion" {
  type = string
}

variable "bucket_name_raw" {
  type = string
}

