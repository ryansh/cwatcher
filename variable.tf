variable "prefix" {
  type = string
  default = "rs"
}

variable "environment" {
    type = string
    default = "dev"
  }

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "vpc_private_sub" {
  type = list
  default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_sub" {
  type = list
  default = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
}

variable "container_port" {
    type = number
    default = 80
  
}

variable "health_check_path" {
  type = string
  default = "/"
}

variable "alb_tls_cert_arn" {
  type = string
  default = "arn"
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "service_Min" {
  type = number
  default = 1
}

variable "service_Des" {
  type = number
  default = 1
}

variable "service_Max" {
  type = number
  default = 4
}