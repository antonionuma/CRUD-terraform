output "table_id" {
  value       = module.dynamodb_table.dynamodb_table_id
  description = "DynamoDB table ID"
}