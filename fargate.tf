resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-fargate-cluster"
  tags = {
      Name = "${var.prefix}-fargate-cluster"
    }
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  service_name = "nginx"
  #task_image = "${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${var.prefix}-${local.service_name}:latest"
  task_image = "nginx"
  service_port = 80
  service_namespace_id = aws_service_discovery_private_dns_namespace.app.id
  container_definition = [{
    cpu         = 256
    image       = local.task_image
    memory      = 512
    name        = local.service_name
    networkMode = "awsvpc"
    environment = [
      {
        "name": "SERVICE_DISCOVERY_NAMESPACE_ID", "value": local.service_namespace_id
      }
    ]
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = local.service_port
        hostPort      = local.service_port
      }
    ]
    logConfiguration = {
      logdriver = "awslogs"
      options = {
        "awslogs-group"         = local.cw_log_group
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "stdout"
      }
    }
  }]
  cw_log_group = "/ecs/${local.service_name}"
}


# AWS Fargate Security Group
resource "aws_security_group" "fargate_task" {
  name   = "${local.service_name}-fargate-task"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = local.service_port
    to_port     = local.service_port
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = local.service_name
  }
}

# Fargate Container
resource "aws_cloudwatch_log_group" "app" {
  name = local.cw_log_group
  tags = {
      Name = local.service_name
    }
}
resource "aws_ecs_task_definition" "app" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  cpu                      = local.container_definition.0.cpu
  memory                   = local.container_definition.0.memory
  requires_compatibilities = ["FARGATE"]
  container_definitions    = jsonencode(local.container_definition)
  execution_role_arn       = aws_iam_role.fargate_execution.arn
  task_role_arn            = aws_iam_role.fargate_task.arn
  tags =  {
      Name = local.service_name
    }
}
resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.name
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = "1"
  launch_type     = "FARGATE"
  
  service_registries {
    registry_arn = aws_service_discovery_service.app_service.arn
    container_name = local.service_name
    container_port = local.service_port
  }

   load_balancer {
   target_group_arn = aws_alb_target_group.fargateLB.arn
   container_name   = local.service_name
   container_port   = var.container_port
 }
  
  network_configuration {
    security_groups = [aws_security_group.fargate_task.id]
    subnets         = module.vpc.private_subnets
  }
}
resource "aws_service_discovery_service" "app_service" {
  name = local.service_name
  dns_config {
    namespace_id = local.service_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
    dns_records {
      ttl  = 10
      type = "SRV"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecr_repository" "fargateREG" {
  name                 = "${var.prefix}nginx"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}