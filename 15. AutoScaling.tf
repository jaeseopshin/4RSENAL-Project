# [자동화] AWS로부터 현재 사용 가능한 최신 Amazon Linux 2023 이미지 ID를 실시간으로 조회합니다.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 1. Launch Template 생성
resource "aws_launch_template" "as_template" {
  # 캐시 꼬임을 완전히 파괴하기 위해 이름 접두사를 신규 버전으로 변경합니다.
  name_prefix = "terraform-lt-v3-"

  # 실시간으로 찾아온 최신 살아있는 ID를 자동으로 꽂아줍니다.
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro" # 서울 리전 가용 영역 자원 부족 우회용 규격
  key_name      = aws_key_pair.soonge97_aws_key.key_name

  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  # 조장님이 작성하신 4RSENAL 팀 정보 HTML을 완벽히 이식했습니다.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install -y nginx

    # Nginx 서비스를 먼저 활성화하고 켭니다.
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # 기존 기본 화면을 지우고 내가 만든 HTML을 넣습니다.
    sudo rm -f /usr/share/nginx/html/index.html
    sudo cat << 'HTML' > /usr/share/nginx/html/index.html
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>jaeseop.store</title>
        <style>
            body { font-family: 'Arial', sans-serif; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            .container { text-align: center; background: white; padding: 50px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            h1 { color: #1877f2; }
            p { color: #666; font-size: 18px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>4RSENAL - Terraform project</h1>
            <p> 신재섭(조장), 전병욱, 이은석, 정태환 🚀</p>
        </div>
    </body>
    </html>
    HTML

    # 변경된 HTML을 적용하기 위해 Nginx를 안전하게 리로드합니다.
    sudo systemctl reload nginx
  EOF
  )

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

# 2. Auto-Scaling 그룹 생성
resource "aws_autoscaling_group" "terraform-prd-asg" {
  name                      = "terraform-prd-asg"
  vpc_zone_identifier       = [aws_subnet.terraform-pub-subnet-2a.id, aws_subnet.terraform-pub-subnet-2c.id]
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 3
  health_check_grace_period = 120
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.terraform-prd-tg.arn]

  launch_template {
    id      = aws_launch_template.as_template.id
    version = "$Latest"
  }

  depends_on = [
    aws_lb.web-lb,
    aws_lb_target_group.terraform-prd-tg
  ]

  lifecycle {
    create_before_destroy = true
  }
}
