provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

# Cluster
# resource "aws_ecs_cluster" "ecommerce-d8-cluster" {
#   name = "ecommerce-d8-cluster"
#   tags = {
#     Name      = "ecommerce-ecs"
#     "Project" = "deployment 8"
#   }
# }

# module "app_vpc" {
#   source            = ".."
#   subnet_be         = var.aws_subnet.private_a.id
#   security_group_be = var.aws_security_group.ingress_app_backend.id
#   tg_arn =            aws_lb_target_group.ecommerce-app-tg.arn
# }

data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["App VPC D8"]
  }

  filter {
    name   = "Project"
    values = ["deployment 8"]
  }
}

data "aws_subnet" "my_public_subnet_A" {
  filter {
    name   = "tag:Name"
    values = ["public | us-east-1a"]

  }

  filter {
    name   = "Projects"
    values = ["deployment 8"]
  }

}

data "aws_subnet" "my_public_subnet_B" {
  filter {
    name   = "tag:Name"
    values = ["public | us-east-1b"]

  }

  filter {
    name   = "Projects"
    values = ["deployment 8"]
  }

}

data "aws_ecs_cluster" "my_ecs_cluster" {
  cluster_name = "ecommerce-d8-cluster"
}

data "aws_lb_target_group" "my_tg" {
  name = "ecommerce-app-tg"
}


resource "aws_cloudwatch_log_group" "log-group" {
  name = "/ecs/ecommerce-logs"
  tags = {
    Application = "ecommerce-app"
    "Project"   = "deployment 8"
  }
}

data "aws_security_group" "my_security_group" {
  vpc_id = data.aws_vpc.my_vpc.id

  filter {
    name   = "tag:Name"
    values = "ingress-app_frontend"
  }
}

data "aws_lb_target_group" "my_alb_tg" {

}

# Task Definition

resource "aws_ecs_task_definition" "ecommerce-frontend-task" {
  family = "ecommerce-frontend-task"

  container_definitions = <<EOF
  [
  {
      "name": "ecommerce-frontend-container",
      "image": "lani23/app8fe:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecommerce-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "portMappings": [
        {
          "containerPort": 3000
        }
      ]
    }
  ]
  EOF

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "512"
  execution_role_arn       = "arn:aws:iam::988716448983:role/ECSTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::988716448983:role/ECSTaskExecutionRole"

}

# ECS Service
resource "aws_ecs_service" "ecommerce-frontend-service" {
  name                 = "ecommerce-frontend-service"
  cluster              = data.aws_ecs_cluster.my_ecs_cluster.id
  task_definition      = aws_ecs_task_definition.ecommerce-frontend-task.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  force_new_deployment = true

  network_configuration {
    subnets = [
      data.aws_subnet.my_public_subnet_A.id,
      data.aws_subnet.my_public_subnet_B.id
    ]
    assign_public_ip = false
    security_groups  = [data.aws_security_group.my_security_group.id]
  }

  load_balancer {
    target_group_arn = data.aws_lb_target_group.my_alb_tg.arn
    container_name   = "ecommerce-frontend-container"
    container_port   = 3000
  }

}
