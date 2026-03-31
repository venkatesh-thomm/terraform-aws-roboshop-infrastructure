##############################################
# LOCAL VARIABLES CONFIGURATION
##############################################




locals {
  # Creates a common name suffix using project and environment.
  # Example: if project_name = "roboshop" and environment = "dev", this becomes "roboshop-dev"
  common_name_suffix = "${var.project_name}-${var.environment}"

  # Extracts the first private subnet ID from the comma-separated list from stored  SSM Parameter "private_subnet_ids"
  # Example: if SSM value = "subnet-123,subnet-456", it picks "subnet-123"
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]

  # Converts the comma-separated list of private subnet IDs into a Terraform list
  # Example: ["subnet-123", "subnet-456"]
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  # Fetches the latest Amazon Machine Image (AMI) ID from a data source
  ami_id = data.aws_ami.joindevops.id

  # Retrieves the Catalogue application's Security Group ID from AWS SSM Parameter Store
  catalogue_sg_id = data.aws_ssm_parameter.catalogue_sg_id.value

  # Retrieves the VPC ID (used to ensure resources are created in the correct VPC)
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  # Retrieves the ARN (Amazon Resource Name) of the backend ALB (Application Load Balancer)
  # listener – needed when attaching targets or rules to the ALB
  backend_alb_listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value

  # Defines a reusable set of common tags for all AWS resources
  # These tags help with identification, cost tracking, and management
  common_tags = {
    Project     = var.project_name # Project name tag (e.g., "roboshop")
    Environment = var.environment  # Environment tag (e.g., "d

  }
}

