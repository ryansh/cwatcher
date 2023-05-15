output "nginx_local" {
  value = "curl http://${aws_ecs_service.app.name}.${aws_service_discovery_private_dns_namespace.app.name}"
}

output "alb_dns_name" {
  value = "curl http://${aws_lb.fargateLB.dns_name}"
}

