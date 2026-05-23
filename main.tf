# creating vpc
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

# creating subnets
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "192.168.2.0/24" 
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

# creating IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

# creating Route table
resource "aws_route_table" "public_rt_1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-1"
  }
}

resource "aws_route_table" "public_rt_2" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-2"
  }
}

# subnet associations
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.public_rt_1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.public_rt_2.id
}

# security group
resource "aws_security_group" "websg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WEBsg"
  }
}

# S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "tf-s3-test-sl-proj-9121"
}

# EC2 instances
resource "aws_instance" "webserver1" {
  ami                         = var.ami_id
  instance_type               = var.instance_typ
  vpc_security_group_ids      = [aws_security_group.websg.id]
  subnet_id                   = aws_subnet.sub1.id
  user_data                   = file("user_data.sh")
}

resource "aws_instance" "webserver2" {
  ami                         = var.ami_id
  instance_type               = var.instance_typ
  vpc_security_group_ids      = [aws_security_group.websg.id]
  subnet_id                   = aws_subnet.sub2.id
  user_data                   = file("user_data1.sh")
}

# ALB
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "web"
  }
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Attach EC2 to Target Group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

# Output
output "loadbalancer_dns" {
  value = aws_lb.myalb.dns_name
}