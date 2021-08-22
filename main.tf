terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.42.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
  #Using credentials file
  shared_credentials_file = "credentials"
  profile = "default"
}

#-----VPC-----
resource "aws_vpc" "dev-vpc" {
  cidr_block       = "10.132.120.0/21"
  tags = {
    Name = "prod-vpc"
  }
}

#-----Subnet 1-----
resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.dev-vpc
  cidr_block = "10.132.121.0/24"
  availability_zone = "us-east-1a"

  tags = {
      Name = "Public"

  }
}

#-----Subnet 2-----
resource "aws_subnet" "public-subnet-2" {
  vpc_id = aws_vpc.dev-vpc
  cidr_block = "10.132.122.0/24"
  availability_zone = "us-east-1b"

  tags = {
      Name = "Public"

  }
}

#-----Subnet 3-----
resource "aws_subnet" "private-subnet-1" {
  vpc_id = aws_vpc.dev-vpc
  cidr_block = "10.132.123.0/24"
  availability_zone = "us-east-1a"

  tags = {
      Name = "Private"

  }
}

#-----Subnet 4-----
resource "aws_subnet" "private-subnet-2" {
  vpc_id = "vpc-0a1c55ffe7ed24499"
  cidr_block = "10.132.124.0/24"
  availability_zone = "us-east-1b"

  tags = {
      Name = "Private"

  }
}

#-----Loadbalancer Security Group-----
resource "aws_security_group" "Loadbalancer" {
    name = "Loadbalancer"
    description = "Load balancer SG"
    vpc_id = aws_vpc.dev-vpc

    ingress = [
        {
            cidr_blocks = [ "0.0.0.0/0" ]
            description = "Allow http traffic"
            from_port = 80
            ipv6_cidr_blocks = [ "::/0" ]
            protocol = "tcp"
            to_port = 80
        }
    ]

    egress = [
        {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
        }
    ]
}


#-----Webserver Security Group-----
resource "aws_security_group" "Webserver" {
    name = "Webserver"
    description = "Web Server SG"
    vpc_id = aws_vpc.dev-vpc

    ingress = [
        {
            cidr_blocks = [ "0.0.0.0/0" ]
            description = "Allow traffic from Loadbalancer SG"
            from_port = 80
            ipv6_cidr_blocks = [ "::/0" ]
            prefix_list_ids = [ "value" ]
            protocol = "TCP"
            security_groups = [ "LoadBalancer" ]
            to_port = 80
        }
    ]

    egress = [
        {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
        }
    ]


}
