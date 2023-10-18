output "database_name" {
  value = aws_glue_catalog_table.aws_glue_catalog_table.database_name
}

output "table_name" {
  value = aws_glue_catalog_table.aws_glue_catalog_table.name
}
