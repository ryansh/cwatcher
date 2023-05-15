# Simple VPC with public private subnets

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "${var.prefix}-vpc"
  cidr = var.vpc_cidr
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.vpc_private_sub
  public_subnets  = var.vpc_public_sub
  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true
  enable_vpn_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  tags =   {
      Name = "${var.prefix}-vpc-${var.environment}"
    }
  
}


# cloud map/discovery

resource "aws_service_discovery_private_dns_namespace" "app" {
  name        = "${var.prefix}.cloud.local"
  description = "${var.prefix}.cloud.local zone"
  vpc         = module.vpc.vpc_id  
}


# security group for load balancer 
resource "aws_security_group" "alb" {
  name   = "${var.prefix}-sg-alb-${var.environment}"
  vpc_id =module.vpc.vpc_id
   tags = {
      Name = "${var.prefix}-sg-alb-${var.environment}"
    }
 
  ingress {
   protocol         = "tcp"
   from_port        = 80
   to_port          = 80
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = 443
   to_port          = 443
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}

# security group for service 
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.prefix}-sg-task-${var.environment}"
  vpc_id =module.vpc.vpc_id
  tags = {
      Name = "${var.prefix}-sg-task-${var.environment}"
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.container_port
   to_port          = var.container_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_lb" "fargateLB" {
  name               = "${var.prefix}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
 
  enable_deletion_protection = false
}
 
resource "aws_alb_target_group" "fargateLB" {
  name        = "${var.prefix}-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
 
  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = var.health_check_path
   unhealthy_threshold = "2"
  }
}


# The following shoudl be done with certificate and prot redirection

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.fargateLB.id
  port              = 80
  protocol          = "HTTP"
 
   default_action {
    target_group_arn = aws_alb_target_group.fargateLB.id
    type             = "forward"
 
}
}

# The following is desired
/*
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.fargateLB.id
  port              = 80
  protocol          = "HTTP"
 
  default_action {
   type = "redirect"
 
   redirect {
     port        = 443
     protocol    = "HTTPS"
     status_code = "HTTP_301"
   }
  }
}

 
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.fargateLB.id
  port              = 443
  protocol          = "HTTPS"
 
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_tls_cert_arn
 
  default_action {
    target_group_arn = aws_alb_target_group.fargateLB.id
    type             = "forward"
  }
}
*/