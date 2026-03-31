data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id" # This specifies which parameter to fetch from SSM. /roboshop/dev/vpc_id
}


/*
Terraform is reading an existing parameter from AWS SSM Parameter Store — it’s not creating one.
data.aws_ssm_parameter.vpc_id.value ----> to use the stored VPC ID , vpc_id is name of parameter .
*/
