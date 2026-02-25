resource "aws_security_group" "status-alb" {
  name = "status-alb-sg"
  vpc_id = aws_vpc.status-vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Status-ALB-SG"
  }

}


resource "aws_security_group" "status-ecs" {
  name = "status-ecs-sg"
  vpc_id = aws_vpc.status-vpc.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    security_groups = [aws_security_group.status-alb.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Status-ECS-SG"
  }

}


resource "aws_security_group" "status-rds" {
  name = "status-rds-sg"
  vpc_id = aws_vpc.status-vpc.id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "TCP"
    security_groups = [aws_security_group.status-ecs.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Status-RDS-SG"
  }

}