provider "aws" {
  region     = var.aws_region
  access_key = ""  
  secret_key = ""  
  token      = ""  
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "sg_frontend" {
  name   = "frontend-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_backend" {
  name   = "backend-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_data" {
  name   = "data-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "lt_innovatech" {
  name_prefix   = "lt-innovatech-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              until curl -s --head http://www.google.com | head -n 1 | grep "200 OK" > /dev/null; do
                echo "Esperando conexión a internet..."
                sleep 5
              done
              yum update -y
              yum install -y git docker mariadb105-server nmap-ncat
              systemctl start docker
              systemctl enable docker
              
              systemctl start mariadb
              systemctl enable mariadb
              
              usermod -aG docker ec2-user
              mysql -e "CREATE DATABASE IF NOT EXISTS innovatechdb;"
              EOF
  )
}

resource "aws_instance" "frontend" {
  launch_template {
    id      = aws_launch_template.lt_innovatech.id
    version = "$Latest"
  }
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_frontend.id]
  tags                   = { Name = "EC2-Frontend" }
}

resource "aws_instance" "backend" {
  launch_template {
    id      = aws_launch_template.lt_innovatech.id
    version = "$Latest"
  }
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_backend.id]
  tags                   = { Name = "EC2-Backend" }
}

resource "aws_instance" "data" {
  launch_template {
    id      = aws_launch_template.lt_innovatech.id
    version = "$Latest"
  }
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_data.id]
  tags                   = { Name = "EC2-Data" }
}