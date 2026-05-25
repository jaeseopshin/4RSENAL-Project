####### lb 생성
resource "aws_lb" "web-lb" {
  name               = "web-lb"
  subnets            = [aws_subnet.terraform-pub-subnet-2a.id, aws_subnet.terraform-pub-subnet-2c.id]
  internal           = false
  load_balancer_type = "application"
  tags = {
    "Name" = "web-lb"
  }

  # ALB 전용 보안 그룹으로 올바르게 매칭되어 있습니다.
  security_groups = [aws_security_group.terraform-sg-alb.id]
}

############## Target Group
resource "aws_lb_target_group" "terraform-prd-tg" {
  name     = "terraform-prd-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id

  # [수정] Nginx 웹 서버가 HTML 파일을 확실하게 응답하는지 체크하도록 경로를 명시했습니다.
  health_check {
    port = 80
    path = "/index.html"
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