output "alb_dns_name" {
  description = "URL to access the application"
  value       = aws_lb.status-alb.dns_name
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.status-RDS.endpoint
}

output "ecr_api_node_url" {
  description = "ECR repository URL for api-node"
  value       = aws_ecr_repository.api_node.repository_url
}

output "ecr_client_react_url" {
  description = "ECR repository URL for client-react"
  value       = aws_ecr_repository.client_react.repository_url
}
