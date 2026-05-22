# 1. Launch Template 생성
resource "aws_launch_template" "as_template" {
  name_prefix   = "terraform-lt-backend-"
  image_id      = "ami-09c647964e09aae1e" # Amazon Linux 2023
  instance_type = "t3.micro"              # 계정 프리티어 검증 통과 규격
  key_name      = aws_key_pair.soonge97_aws_key.key_name

  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  # User Data 내부에 조 이름과 팀원 정보를 세련된 디자인으로 주입했습니다.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install -y nginx

    # Nginx 서비스를 활성화하고 가동합니다.
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # 기본 index.html 삭제 후 새 팀 소개 HTML 생성
    sudo rm -f /usr/share/nginx/html/index.html
    sudo cat << 'HTML' > /usr/share/nginx/html/index.html
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>4RSENAL - Terraform Project</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background-color: #f0f2f5; 
                display: flex; 
                justify-content: center; 
                align-items: center; 
                min-height: 100vh; 
                margin: 0; 
            }
            .container { 
                text-align: center; 
                background: white; 
                padding: 50px 40px; 
                border-radius: 16px; 
                box-shadow: 0 10px 25px rgba(0,0,0,0.05); 
                max-width: 500px; 
                width: 100%; 
            }
            .team-badge { 
                background-color: #e7f3ff; 
                color: #1877f2; 
                padding: 8px 16px; 
                border-radius: 20px; 
                font-weight: bold; 
                font-size: 14px; 
                display: inline-block; 
                margin-bottom: 15px; 
                letter-spacing: 1px; 
            }
            h1 { 
                color: #1c1e21; 
                margin: 0 0 10px 0; 
                font-size: 28px; 
            }
            .project-name { 
                color: #606770; 
                font-size: 18px; 
                margin-bottom: 30px; 
                font-weight: 500; 
            }
            .divider { 
                height: 1px; 
                background-color: #e4e6eb; 
                margin: 20px 0; 
            }
            .team-title { 
                font-size: 16px; 
                color: #1c1e21; 
                font-weight: 600; 
                margin-bottom: 15px; 
                text-align: left; 
                padding-left: 5px; 
            }
            .member-list { 
                display: grid; 
                grid-template-columns: repeat(2, 1fr); 
                gap: 12px; 
                text-align: left; 
            }
            .member-card { 
                background: #f7f8fa; 
                padding: 12px 15px; 
                border-radius: 8px; 
                font-size: 15px; 
                color: #4b4f56; 
                border-left: 4px solid #ccd0d5; 
            }
            .member-card.leader { 
                background: #e7f3ff; 
                color: #1877f2; 
                border-left: 4px solid #1877f2; 
                font-weight: bold; 
            }
            .status-msg { 
                margin-top: 30px; 
                font-size: 13px; 
                color: #90949c; 
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="team-badge">TEAM 4RSENAL</div>
            <h1>안녕하세요!</h1>
            <div class="project-name">우리들의 인프라 공간, Terraform Project</div>
            
            <div class="divider"></div>
            
            <div class="team-title">👥 팀 구성원</div>
            <div class="member-list">
                <div class="member-card leader">신재섭 (조장)</div>
                <div class="member-card">전병욱</div>
                <div class="member-card">이은석</div>
                <div class="member-card">정태환</div>
            </div>
            
            <div class="status-msg">
                테라폼 코드로 자동 구축된 웹 인프라에서 안정적으로 구동 중입니다. 🚀
            </div>
        </div>
    </body>
    </html>
    HTML

    # 변경된 HTML 파일을 서비스에 최종 새로고침 반영합니다.
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
