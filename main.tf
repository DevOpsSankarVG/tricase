

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.41.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "kube_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "kube_subnet" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_security_group" "kube_security_group" {
  name        = "Kube-security-group"
  description = "Kube security group"
  vpc_id      = aws_vpc.vpc-035ab5091ab5f9f3d.id

  ingress {
    from_port   = 6443
    to_port     = 6443  
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6783
    to_port     = 6783
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "kube_keypair" {
  key_name   = "keykube"
}

resource "aws_instance" "example_instance" {
  count         = 3
  ami           = "ami-0c94855ba95c71c99"  # CentOS 7 AMI ID
  instance_type = "t2.medium"
  key_name      = aws_key_pair.kube_keypair.key_name
  subnet_id     = aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.kube_security_group.id]
}

