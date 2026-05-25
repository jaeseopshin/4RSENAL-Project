# 1. AWS로부터 최신 Amazon Linux 2023 이미지 ID를 실시간으로 조회
data "aws_ami" "bastion_amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Bastion EC2 생성
resource "aws_instance" "terraform-pub-ec2-bastion-2a" {
  ami                         = data.aws_ami.bastion_amazon_linux_2023.id # 자동 조회된 최신 ID 매칭
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.terraform-sg-bastion.id]
  subnet_id                   = aws_subnet.terraform-pub-subnet-2a.id
  key_name                    = aws_key_pair.soonge97_aws_key.key_name # 리소스 참조로 순서 보장
  associate_public_ip_address = true

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    tags = {
      "Name" = "terraform-pub-ec2-bastion-2a"
    }
  }

  tags = {
    "Name" = "terraform-pub-ec2-bastion-2a"
  }
}