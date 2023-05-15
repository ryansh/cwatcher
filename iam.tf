data "aws_iam_policy_document" "fargate-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "fargate_execution" {
  name   = "fargate_execution_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetAuthorizationToken",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:GetParameters",
            "secretsmanager:GetSecretValue",
            "kms:Decrypt"
        ],
        "Resource": [
            "*"
        ]
    }
  ]
}
EOF
}
resource "aws_iam_policy" "fargate_task" {
  name   = "fargate_task_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "servicediscovery:ListServices",
            "servicediscovery:ListInstances"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role" "fargate_execution" {
  name               = "${local.service_name}-fargate-execution-role"
  assume_role_policy = data.aws_iam_policy_document.fargate-role-policy.json
}
resource "aws_iam_role" "fargate_task" {
  name               = "${local.service_name}-fargate-task-role"
  assume_role_policy = data.aws_iam_policy_document.fargate-role-policy.json
}
resource "aws_iam_role_policy_attachment" "fargate-execution" {
  role       = aws_iam_role.fargate_execution.name
  policy_arn = aws_iam_policy.fargate_execution.arn
}
resource "aws_iam_role_policy_attachment" "fargate-task" {
  role       = aws_iam_role.fargate_task.name
  policy_arn = aws_iam_policy.fargate_task.arn
}