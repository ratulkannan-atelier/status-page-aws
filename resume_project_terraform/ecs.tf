resource "aws_iam_role" "ecs_instance_role" {
  name = "status_page-ecs_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "status_page-ecs_instance_profile"
  role = aws_iam_role.ecs_instance_role.name
}



resource "aws_iam_role" "ecs_task_execution_role" {
  name = "status_page-ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}


resource "aws_launch_template" "ecs_lt" {
  name_prefix = "status_page-ecs_lt"
  image_id = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }


  instance_initiated_shutdown_behavior = "terminate"

  vpc_security_group_ids = [aws_security_group.status-ecs.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "status_page-ecs_instance"
    }
  }

  user_data = base64encode(templatefile("${path.module}/ecs_userdata.sh", {
  cluster_name = aws_ecs_cluster.status_cluster.name
 }))
}


resource "aws_autoscaling_group" "ecs_asg" {
  name = "status_page-ecs_asg"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  vpc_zone_identifier = aws_subnet.status-public_subnets[*].id

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}


resource "aws_ecs_cluster" "status_cluster" {
  name = "status_page-cluster"
}


resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "status_page-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}


resource "aws_ecs_cluster_capacity_providers" "ecs_ccp" {
  cluster_name = aws_ecs_cluster.status_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
  }
}


resource "aws_ecs_task_definition" "status_td" {
  family                   = "status_page-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "512"
  memory                   = "900"

  container_definitions = jsonencode([
    {
      name      = "api-node"
      image     = "${aws_ecr_repository.api_node.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 3000, protocol = "tcp" }
      ]
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.status-RDS.address}:5432/myDB?sslmode=no-verify"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api_node.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "client-react"
      image     = "${aws_ecr_repository.client_react.repository_url}:latest"
      essential = true
      portMappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      dependsOn = [
        { containerName = "api-node", condition = "START" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.client_react.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "status_ecs-service" {
  name            = "status_ecs-service"
  cluster         = aws_ecs_cluster.status_cluster.id
  task_definition = aws_ecs_task_definition.status_td.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight = 100
  }

  network_configuration {
    subnets = aws_subnet.status-private_subnets[*].id
    security_groups = [aws_security_group.status-ecs.id]
  }
  

  load_balancer {
    target_group_arn = aws_lb_target_group.status-alb-tg.arn
    container_name   = "client-react"
    container_port   = 8080
  }

  depends_on      = [aws_lb_listener.status_listener, aws_iam_role_policy_attachment.ecs_task_execution_policy]

}