###########################################
# 1) Create EC2 Instance (Temporary Baking Instance)
###########################################
resource "aws_instance" "catalogue" {
  ami                    = local.ami_id            # AMI ID taken from locals (base machine image)
  instance_type          = var.instance_type       # Instance size (free-tier friendly)
  vpc_security_group_ids = [local.catalogue_sg_id] # Apply the security group for catalogue service access
  subnet_id              = local.private_subnet_id # Launch instance in private subnet (no direct internet access)

  tags = merge(
    local.common_tags, # Apply common tags (environment, project, etc.)
    {
      Name = "${local.common_name_suffix}-catalogue" # Specific name for this instance
    }
  )
}


###########################################
# 2) Provision & Configure Instance (Copy + Execute Setup Script) terraform_data
###########################################

resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id # Re-run provisioning whenever instance ID changes
  ]

  connection {
    type     = "ssh"                             # Using SSH connection method
    user     = "ec2-user"                        # Default login user for Amazon Linux
    password = "DevOps321"                       # (Not recommended) Password for SSH login
    host     = aws_instance.catalogue.private_ip # Connect using private IP (must be reachable from your system)
  }

  provisioner "file" {
    source      = "catalogue.sh"      # Local script file to copy from Terraform machine
    destination = "/tmp/catalogue.sh" # Path on EC2 instance where script will be stored
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",                            # Make the script executable
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment}" # Execute script with parameters (service name + environment)
    ]
  }
}

###########################################
# 3) Stop EC2 Instance Before Creating AMI   AMI cannot be created while the instance is running.
###########################################
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = aws_instance.catalogue.id  # Target instance to control state
  state       = "stopped"                  # Desired final state
  depends_on  = [terraform_data.catalogue] # Ensure provisioning is finished before stopping instance
}

###########################################
# 4) Create AMI  from Configured Instance
# Creates a reusable Amazon Machine Image (AMI) from the configured EC2 instance. This AMI can be used in auto-scaling groups later.
###########################################
resource "aws_ami_from_instance" "catalogue" {
  name               = "${local.common_name_suffix}-catalogue-ami" # Name AMI with environment prefix
  source_instance_id = aws_instance.catalogue.id                   # Use stopped EC2 instance to create image
  depends_on         = [aws_ec2_instance_state.catalogue]          # Ensure instance is stopped first

  tags = merge(
    local.common_tags, # Apply standard metadata tags
    {
      Name = "${local.common_name_suffix}-catalogue-ami" # Name tag for AMI
    }
  )
}

###########################################
# 5)  Create a Target Group for Load Balancer
###########################################
resource "aws_lb_target_group" "catalogue" {
  name                 = "${local.common_name_suffix}-catalogue" # Example: if local.common_name_suffix = "roboshop-dev", name = "roboshop-dev-catalogue"
  port                 = 8080                                    # Your application listens on port 8080 The port on which targets receive traffic from the load balancer
  protocol             = "HTTP"                                  # The protocol used by the load balancer to communicate with targets
  vpc_id               = local.vpc_id                            # The VPC where the target group is created. All targets must be in this VPC.
  deregistration_delay = 60                                      # Time in seconds to wait before deregistering a target after it is removed from the target group.

  health_check {
    healthy_threshold   = 2         # Number of consecutive successful responses required before considering a target healthy
    interval            = 10        # Interval in seconds between health checks
    matcher             = "200-299" # HTTP status codes to consider as healthy
    path                = "/health" # Path on the target that the load balancer will query for health checks
    port                = 8080      # Port to use for health checks. Can be same as the target port.
    protocol            = "HTTP"    # Protocol used for health check requests
    timeout             = 2         # Timeout in seconds for each health check request
    unhealthy_threshold = 2         # Number of consecutive failed health checks before considering a target unhealthy
  }
}

###########################################
# 6) Create Launch Template (Use AMI in ASG)
# Launch Template for Auto Scaling Group
# Launch Templates are reusable configurations for EC2 instances, often used with Auto Scaling Groups.
###########################################
resource "aws_launch_template" "catalogue" {
  name     = "${local.common_name_suffix}-catalogue" # Launch template name
  image_id = aws_ami_from_instance.catalogue.id      # Use the created AMI

  instance_initiated_shutdown_behavior = "terminate"       # If instance shuts itself down -> terminate
  instance_type                        = var.instance_type # Instance type for ASG nodes

  vpc_security_group_ids = [local.catalogue_sg_id] # Apply service security group

  # when we run terraform apply again, a new version will be created with new AMI ID
  update_default_version = true

  # Tag instance
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      { Name = "${local.common_name_suffix}-catalogue" }
    )
  }

  # Tag EBS volume
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.common_tags,
      { Name = "${local.common_name_suffix}-catalogue" }
    )
  }

  # Tag launch template itself
  tags = merge(
    local.common_tags,
    { Name = "${local.common_name_suffix}-catalogue" }
  )
}
###########################################
# 7) Auto Scaling Group for Catalogue
###########################################
resource "aws_autoscaling_group" "catalogue" {
  name                      = "${local.common_name_suffix}-catalogue" # ASG Name
  max_size                  = 10                                      # Maximum number of instances allowed
  min_size                  = 1                                       # Always ensure at least 1 instance is running
  health_check_grace_period = 100                                     # Allow warm-up time before health check failures count
  health_check_type         = "ELB"                                   # Type of health check for instances in the ASG: "ELB" means it uses the Load Balancer health check
  desired_capacity          = 1                                       # Default number of instances
  force_delete              = false                                   # Prevent forced deletion (protect resources)

  launch_template {
    id      = aws_launch_template.catalogue.id             # Use launch template
    version = aws_launch_template.catalogue.latest_version # Always use latest template version
  }

  vpc_zone_identifier = local.private_subnet_ids            # Subnets in which the ASG will launch EC2 instances (private subnets in this case)
  target_group_arns   = [aws_lb_target_group.catalogue.arn] # Attach the ASG to a Load Balancer Target Group(Load Balancer can send traffic toevery EC2 instance launched by the ASG automatically as it becomes part of that Target Group.)

  instance_refresh {
    strategy = "Rolling" # "Rolling" means instances are updated in batches — not all at once.
    preferences {
      min_healthy_percentage = 50 # atleast 50% of the instances should be up and running , other can be replaced
    }
    triggers = ["launch_template"] # The refresh process is automatically triggered when the launch template changes (for example, a new AMI version).
  }

  dynamic "tag" {                                                                           # A dynamic block lets you loop over a map or list and create multiple tag blocks automatically.For each key-value pair, Terraform creates a separate tag {} block.
    for_each = merge(local.common_tags, { Name = "${local.common_name_suffix}-catalogue" }) # Iterates over all tags from local.common_tags plus a custom Name tag
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true # Ensures this tag is applied to EC2 instances launched by the ASG
    }
  }

  timeouts { # Timeouts block defines how long Terraform waits for operations
    # Timeout for deleting the ASG (e.g., if Terraform destroys this resource)
    delete = "15m"
  }
}

###########################################
# 8) Auto Scaling Policy (Scale based on CPU Load)
# Keep the ASG’s CPU around 75%. Add servers if CPU is too high, remove servers if CPU is too low.
###########################################
resource "aws_autoscaling_policy" "catalogue" {
  autoscaling_group_name = aws_autoscaling_group.catalogue.name    # Apply policy to this ASG
  name                   = "${local.common_name_suffix}-catalogue" # Policy name
  policy_type            = "TargetTrackingScaling"                 # Dynamic scaling based on target metric

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization" # Scale based on avg CPU across ASG
    }
    target_value = 75.0 # Target CPU usage threshold (75%)
  }
}

###########################################
# 9) RULE - ATTACH TO LISTENER 
# ALB Listener Rule for the "catalogue" service
# This resource creates a rule for the ALB listener.
# The rule forwards incoming requests to the target group based on a host header condition.
###########################################
resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = local.backend_alb_listener_arn # ARN of the ALB listener to which this rule will be attached
  priority     = 10                             # Lower numbers have higher precedence. If multiple rules match, the one with the lowest priority is applied.
  action {                                      # Action block defines what happens when a request matches the condition
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn # ARN of the target group to forward requests to. requests are forwarded to the "catalogue" target group.
  }
  condition {                                                                  # Condition block defines the criteria that must be met for the action to trigger
    host_header {                                                              # Host header condition: this rule triggers if the request's host header matches one of the specified values
      values = ["catalogue.backend-alb-${var.environment}.${var.domain_name}"] # Values is a list of hostnames. The rule will match if the request's "Host" header matches this value.
      # This dynamically constructs the hostname based on environment and domain name variables ; Example: "catalogue.backend-alb.dev.example.com"
    }
  }
}

###########################################
# 10) Terminate Temporary Baking Instance (Cleanup)
###########################################
resource "terraform_data" "catalogue_local" {
  triggers_replace = [aws_instance.catalogue.id]        # Run when instance ID changes
  depends_on       = [aws_autoscaling_policy.catalogue] # Ensure ASG is ready before deleting

  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.catalogue.id}" # Delete initial build instance
  }
}
