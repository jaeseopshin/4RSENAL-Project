resource "tls_private_key" "soonge97_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "soonge97_aws_key" {
  key_name   = "soonge97"
  public_key = tls_private_key.soonge97_key.public_key_openssh
}

resource "local_file" "soonge97_private_key" {
  content  = tls_private_key.soonge97_key.private_key_pem
  filename = "soonge97.pem"
}