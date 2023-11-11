############
# Provider #
############
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

##############
# Create VPC #
##############
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name"    = "App VPC D8"
    "Project" = "deployment 8"
  }
}

##################
# Create Subnets #
##################
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    "Name"    = "public | us-east-1a"
    "Project" = "deployment 8"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name"    = "private | us-east-1a"
    "Project" = "deployment 8"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    "Name"    = "public | us-east-1b"
    "Project" = "deployment 8"
  }
}

###########################
# Route Table Association #
###########################
resource "aws_route_table_association" "public_a_subnet" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a_subnet" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_b_subnet" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

######################
# Elastic IP Address #
######################
resource "aws_eip" "elastic-ip" {
  domain = "vpc"
}

#####################
# Internet Gateways #
#####################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.elastic-ip.id
}

################
# Route Tables #
################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app_vpc.id
}

#############
# RT Routes #
#############
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_ngw" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

###################
# Security Groups #
###################
resource "aws_security_group" "httpalb" {
  name        = "httpalb"
  description = "HTTP ALB traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_app_backend" {
  name        = "ingress-app_backend"
  description = "Allow ingress to APP Backend"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_app_frontend" {
  name        = "ingress-app_frontend"
  description = "Allow ingress to APP Front-End"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


####################################
# Create Application Load Balancer #
####################################

# Configure Target Group Provider
resource "aws_lb_target_group" "ecommerce-app-tg" {
  name        = "ecommerce-app-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled = true
    path    = "/health"
  }

  depends_on = [aws_alb.ecommerce_app]
}

# Application Load Balancer
resource "aws_alb" "ecommerce_app" {
  name               = "ecommerce-lb-d8"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]

  security_groups = [
    aws_security_group.httpalb.id,
  ]

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_alb_listener" "ecommerce_app_listener" {
  load_balancer_arn = aws_alb.ecommerce_app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecommerce-app-tg.arn
  }
}

###############
# Output Data #
###############
output "alb_url" {
  value = "http://${aws_alb.ecommerce_app.dns_name}"
}

# output "my_vpc_id" {
#   value = aws_vpc.app_vpc.id
# }
# output "my_public_subnet_A_id" {
#   value = aws_subnet.public_a.id
# }

# output "my_public_subnet_B_id" {
#   value = aws_subnet.public_b.id
# }

# output "my_private_subnet_A_id" {
#   value = aws_subnet.private_a.id
# }
