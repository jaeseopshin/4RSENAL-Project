# 1. Launch Template 생성
resource "aws_launch_template" "as_template" {
  name_prefix   = "terraform-lt-backend-"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "soonge97"

  vpc_security_group_ids = [aws_security_group.terraform-sg-bastion.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
    sudo rm -f /var/www/html/index.html
    sudo cat << 'HTML' > /var/www/html/index.html
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
            <h1>안녕하세요! jaeseop.store 입니다.</h1>
            <p>직접 구성한 테라폼 인프라 위에 내가 만든 HTML 페이지 배포 완료! 🚀</p>
        </div>
    </body>
    </html>
    HTML
    sudo systemctl restart nginx
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

  lifecycle {
    create_before_destroy = true
  }
}
