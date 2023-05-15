# Fargate with Terraform

This Terraform code will create:
- VPC with private and public subnets
- Required IAM roles and policy for the Fargate service
- Fargate in private subnet exposed via ALB 
- Autoscaling for the service and container registry and service discovery.
- note: comment out the loadbalancer https and port redirection if you have public cert.

## More improvement

Use VPC Endpoints
