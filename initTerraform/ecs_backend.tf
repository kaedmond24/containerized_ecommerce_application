############
# Provider #
############
# provider "aws" {
#   access_key = var.aws_access_key
#   secret_key = var.aws_secret_key
#   region     = "us-east-1"

# }'

##################
# Create Cluster #
##################

# Cluster
resource "aws_ecs_cluster" "ecommerce-d8-cluster" {
  name = "ecommerce-d8-cluster"
  tags = {
    Name      = "ecommerce-ecs"
    "Project" = "deployment 8"
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "/ecs/ecommerce-logs"

  tags = {
    Application = "ecommerce-app"
    "Project"   = "deployment 8"
  }
}

###################
# Task Definition #
###################

resource "aws_ecs_task_definition" "ecommerce-backend-task" {
  family = "ecommerce-backend-task"

  container_definitions = <<EOF
  [
  {
      "name": "ecommerce-backend-container",
      "image": "lani23/app8be:latest",
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
          "containerPort": 8000
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

######################
# Create ECS Service #
######################

# ECS Service
resource "aws_ecs_service" "ecommerce-backend-service" {
  name                 = "ecommerce-backend-service"
  cluster              = aws_ecs_cluster.ecommerce-d8-cluster.id
  task_definition      = aws_ecs_task_definition.ecommerce-backend-task.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets = [
     module.app_vpc.my_private_subnet_A_id
    ]
    assign_public_ip = false
    security_groups  = [aws_security_group.ingress_app_backend.id]
  }
}
