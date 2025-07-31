provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "srs-strapi-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "strapi_cp_srs" {
  cluster_name       = aws_ecs_cluster.strapi_cluster.name
  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/srs-strapi-task"
  retention_in_days = 7
}

# ECS Task Definition (placeholder for dynamic updates)
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "srs-strapi-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-app-ecs-pg:latest"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${var.db_password}@srs-strapi-postgres.cbymg2mgkcu2.us-east-2.rds.amazonaws.com:5432/${var.db_name}"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/srs-strapi-task"
          awslogs-region        = "us-east-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "srs-strapi-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
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

# Security Group for ECS tasks
resource "aws_security_group" "ecs_sg" {
  name        = "srs-strapi-ecs-sg"
  description = "Allow ALB to connect on port 1337"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow ALB traffic"
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "srs-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-024126fd1eb33ec08", "subnet-03e27b60efa8df9f0"]
}

# Blue & Green Target Groups
resource "aws_lb_target_group" "blue_tg" {
  name        = "srs-strapi-blue-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "green_tg" {
  name        = "srs-strapi-green-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_tg.arn
  }
}

# ECS Service (with CodeDeploy controller)
resource "aws_ecs_service" "strapi_service" {
  name            = "srs-strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  load_balancer {
  target_group_arn = aws_lb_target_group.blue_tg.arn
  container_name   = "strapi"
  container_port   = 1337
  }

  network_configuration {
    subnets          = ["subnet-024126fd1eb33ec08", "subnet-03e27b60efa8df9f0"]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.listener,
    aws_ecs_cluster_capacity_providers.strapi_cp_srs
  ]
}

# RDS DB
resource "aws_db_instance" "postgres" {
  identifier              = "srs-strapi-postgres"
  engine                  = "postgres"
  engine_version          = "17.4"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.ecs_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 7
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "srs-strapi-db-subnet-group"
  subnet_ids = ["subnet-024126fd1eb33ec08", "subnet-03e27b60efa8df9f0"]
  tags = {
    Name = "srs-strapi-db-subnet-group"
  }
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# CodeDeploy ECS Application
resource "aws_codedeploy_app" "strapi" {
  name             = "strapi-codedeploy-app"
  compute_platform = "ECS"
}

resource "aws_iam_role" "codedeploy_role" {
  name = "strapi-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
}

# CodeDeploy ECS Deployment Group
resource "aws_codedeploy_deployment_group" "strapi" {
  app_name               = aws_codedeploy_app.strapi.name
  deployment_group_name  = "strapi-deploy-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster.name
    service_name = aws_ecs_service.strapi_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener.arn]
      }
      target_group {
        name = aws_lb_target_group.blue_tg.name
      }
      target_group {
        name = aws_lb_target_group.green_tg.name
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
