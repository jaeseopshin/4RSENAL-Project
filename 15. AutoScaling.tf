# 1. Launch Configuration 대신 Launch Template 사용
resource "aws_launch_template" "as_template" {
  name_prefix   = "terraform-lt-backend-"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "soonge97"

  # Launch Template에서는 security_groups 대신 vpc_security_group_ids를 사용합니다.
  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  # User Data는 base64encode 처리를 해주는 것이 안전합니다.
  # EOF/EOT 불일치 오류와 중괄호 위치를 수정했습니다.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
  EOF
  )

  # Launch Template의 태그 지정 방식
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "jeff-userdata"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Auto-Scaling 그룹 생성 (수정된 Launch Template 참조)
resource "aws_autoscaling_group" "terraform-prd-asg" {
  name                      = "terraform-prd-asg"
  vpc_zone_identifier       = [aws_subnet.terraform-pub-subnet-2a.id, aws_subnet.terraform-pub-subnet-2c.id]
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 3
  health_check_grace_period = 120
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.terraform-prd-tg.arn]

  # 기존 launch_configuration 지우고 launch_template 추가
  launch_template {
    id      = aws_launch_template.as_template.id
    version = "$Latest" # 언제나 최신 버전의 템플릿 적용
  }

  lifecycle {
    create_before_destroy = true
  }
}
