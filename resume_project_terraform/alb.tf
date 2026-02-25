resource "aws_lb" "status-alb" {
  name               = "status-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.status-alb.id]
  subnets            = aws_subnet.status-public_subnets[*].id


  tags = {
    Name = "status-alb"
  }
}

resource "aws_lb_target_group" "status-alb-tg" {
  name     = "status-alb-tg"
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.status-vpc.id

  health_check {
  path                = "/ping"
  protocol            = "HTTP"
  healthy_threshold   = 2
  unhealthy_threshold = 3
  interval            = 30
  timeout             = 5
  matcher             = "200"
  }


  tags = {
    Name = "status-alb-tg"
  }
}

resource "aws_lb_listener" "status_listener" {
  load_balancer_arn = aws_lb.status-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.status-alb-tg.arn
  }
}

