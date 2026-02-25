resource "aws_ecr_repository" "client_react" {
  name                 = "status_page/client_react"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "status_page-client_react"
  }
}


resource "aws_ecr_repository" "api_node" {
  name                 = "status_page/api_node"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "status_page-api_node"
  }
}


resource "aws_ecr_lifecycle_policy" "client_react" {
  repository = aws_ecr_repository.client_react.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}


resource "aws_ecr_lifecycle_policy" "api_node" {
  repository = aws_ecr_repository.api_node.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
