resource "aws_cloudwatch_log_group" "client_react" {
  name = "/ecs/status-page/client_react"
  retention_in_days = 5

  tags = {
    Name = "status-page_client-react_logs"
  }
}

resource "aws_cloudwatch_log_group" "api_node" {
  name = "/ecs/status-page/api_node"
  retention_in_days = 5

  tags = {
    Name = "status-page_api-node_logs"
  }
}