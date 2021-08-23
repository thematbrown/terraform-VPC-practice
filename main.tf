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
  vpc_id = "aws_vpc.dev-vpc"
  cidr_block = "10.132.121.0/24"
  availability_zone = "us-east-1a"

  tags = {
      Name = "Public"

  }
}

#-----Subnet 2-----
resource "aws_subnet" "public-subnet-2" {
  vpc_id = "aws_vpc.dev-vpc"
  cidr_block = "10.132.122.0/24"
  availability_zone = "us-east-1b"

  tags = {
      Name = "Public"

  }
}

#-----Subnet 3-----
resource "aws_subnet" "private-subnet-1" {
  vpc_id = "aws_vpc.dev-vpc"
  cidr_block = "10.132.123.0/24"
  availability_zone = "us-east-1a"

  tags = {
      Name = "Private"

  }
}

#-----Subnet 4-----
resource "aws_subnet" "private-subnet-2" {
  vpc_id = "aws_vpc.dev-vpc"
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
    vpc_id = "aws_vpc.dev-vpc"

    ingress = [
        {
            description = "Allow http traffic"
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = [ "0.0.0.0/0" ]
            ipv6_cidr_blocks = [ "::/0" ]
            prefix_list_ids = null
            security_groups = null
            self = null
        }
    ]

    egress = [
        {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
            prefix_list_ids = null
            security_groups = null
            self = null
            description = null
        }
    ]
}


#-----Webserver Security Group-----
resource "aws_security_group" "Webserver" {
    name = "Webserver"
    description = "Web Server SG"
    vpc_id = "aws_vpc.dev-vpc"

    ingress = [
        {

            description = "Allow traffic from Loadbalancer SG"
            from_port = 80
            to_port = 80
            security_groups = [ "LoadBalancer" ]
            protocol = "TCP"
            cidr_blocks = [ "0.0.0.0/0" ]
            ipv6_cidr_blocks = [ "::/0" ]
            prefix_list_ids = null
            security_groups = null
            self = null
        }
    ]

    egress = [
        {
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
            prefix_list_ids = null
            security_groups = null
            self = null
            description = null
        }
    ]


}


#-----Load balancer-----



#-----Lauch Template-----
resource "aws_launch_template" "TOP-Template-1" {
  name = "TOP-Template-1"
  image_id = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "WebServer" ]
  key_name = "TOP-keys"
  user_data = <<-EOF
  #!/bin/sh
  yum update -y
  yum install -y httpd
  systemctl start httpd
  echo "hello world from $(hostname)" > /var/www/html/index.html
  EOF
}

#-----Autoscaling Group-----
resource "aws_autoscaling_group" "asg-1" {
    availability_zones = [ "us-east-1a, us-east-1b" ]
    desired_capacity = 2
    min_size = 2
    max_size = 2

    launch_template {
      id = aws_launch_template.TOP-Template-1.id
      version = "$Latest"
    }
}
