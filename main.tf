provider "aws" {
    region = var.region
}

resource "aws_security_group" "ebs_tf_sg" {
    name = "ebs_tf_sg"
    description = "allow all traffic"
    vpc_id = aws_vpc.my_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        name = "EBSTerraformSG"
    }
}

resource "aws_instance" "ebs_tf_instance" {
  ami             = data.aws_ssm_parameter.instance_ami.value
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.ebs_public.id
  security_groups = [aws_security_group.ebs_tf_sg.id]
  key_name        = var.key_name
  user_data       = fileexists("install_apache.sh") ? file("install_apache.sh") : null
  Count           = 2
  tags = {
    name = "EBSTerraformInstance"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"
  tags = {
    name = "ebsVPC"
  }
}

resource "aws_subnet" "ebs_public" {
  vpc_id                  = aws_vpc.my_vpc.id
  map_public_ip_on_launch = "true"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "ebsPublicSubnet"
}
  }

resource "aws_subnet" "ebs_private" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-west-2b"

  tags = {
    Name = "ebsPrivateSubnet"
  }
}

resource "aws_internet_gateway" "ebs_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "ebsIGW"
  }
}

resource "aws_route_table" "ebs_public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ebs_igw.id
  }

  tags = {
    "Name" = "ebsPublicRT"
  }

}

resource "aws_route_table_association" "ebs_subnet_rt_public" {
  subnet_id      = aws_subnet.ebs_public.id
  route_table_id = aws_route_table.ebs_public_rt.id
}

  data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_region" "current" {}