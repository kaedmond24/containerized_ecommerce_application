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

resource "aws_cloudwatch_log_group" "log-group" {
  name = "/ecs/ecommerce-logs"

  tags = {
    Application = "ecommerce-app"
    "Project"   = "deployment 8"
  }
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
          "awslogs-group": "/ecs/eccomerce-logs",
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
  cluster              = aws_ecs_cluster.eccomerce-d8-cluster.id
  task_definition      = aws_ecs_task_definition.ecommerce-frontend-task.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  force_new_deployment = true

  network_configuration {
    subnets = [
      aws_subnet.public_a,
      aws_subnet.public_b
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ingress_app_frontend.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecommerce-app-tg.arn
    container_name   = "ecommerce-frontend-container"
    container_port   = 3000
  }

}
