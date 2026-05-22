####### lb 생성

resource "aws_lb" "web-lb" {
  name               = "web-lb"
  subnets            = [aws_subnet.terraform-pub-subnet-2a.id, aws_subnet.terraform-pub-subnet-2c.id]
  internal           = false
  load_balancer_type = "application"
  tags = {
    "Name" = "web-lb"
  }

  # 확인하신 보안 그룹 리소스 이름과 매칭 완료되었습니다.
  security_groups = [aws_security_group.terraform-sg-alb.id]
}

############## Target Group

resource "aws_lb_target_group" "terraform-prd-tg" {
  name     = "terraform-prd-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id
  health_check {
    port = 80
    path = "/"
  }
  tags = {
    "Name" = "terraform-prd-tg"
  }
}

############Listener 

resource "aws_lb_listener" "terraform-prd-listener" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.terraform-prd-tg.arn
    type             = "forward"
  }
}
