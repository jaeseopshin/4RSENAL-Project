resource "aws_instance" "terraform-pub-ec2-bastion-2a" {
  # [수정] 서울 리전 전용 Amazon Linux 2023 공식 AMI ID로 고정
  ami                         = "ami-09c647964e09aae1e"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.terraform-sg-bastion.id]
  subnet_id                   = aws_subnet.terraform-pub-subnet-2a.id
  key_name                    = "soonge97"
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
