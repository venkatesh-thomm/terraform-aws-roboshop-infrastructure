# ------------------------------------------------------------
# Store the Backend ALB Listener ARN in AWS SSM Parameter Store
# ------------------------------------------------------------

resource "aws_ssm_parameter" "backend_alb_listener_arn" {
  # The name under which this parameter will be stored in SSM Parameter Store  # /roboshop/dev/backend_alb_listener_arn
  name = "/${var.project_name}/${var.environment}/backend_alb_listener_arn"

  # Type of the parameter — "String" means it stores a plain text value
  # (Other types can be "SecureString" for encrypted values or "StringList" for comma-separated lists)
  type = "String"

  # The actual value being stored — here is ARN (Amazon Resource Name)  of the ALB listener created earlier: aws_lb_listener.backend_alb This ARN uniquely identifies the listener in AWS
  value     = aws_lb_listener.backend_alb.arn
  overwrite = true
}

