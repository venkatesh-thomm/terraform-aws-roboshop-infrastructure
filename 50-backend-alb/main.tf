# ------------------------------------------------------------
# Create an INTERNAL (private) Application Load Balancer (ALB)
# ------------------------------------------------------------

resource "aws_lb" "backend_alb" {
  name               = "${local.common_name_suffix}-backend-alb" # ALB name = e.g., roboshop-dev-backend-alb (project-env-backend-alb)
  internal           = true                                      # 'true' means ALB is internal — not exposed to the internet
  load_balancer_type = "application"                             # Type of ALB (Application = Layer 7 HTTP/HTTPS)
  security_groups    = [local.backend_alb_sg_id]                 # Security group controlling ALB inbound/outbound traffic

  # Since it's an INTERNAL ALB, use private subnets (not public ones)
  subnets                    = local.private_subnet_ids # ALB will be created n connected across these private subnets
  enable_deletion_protection = false                    # Disables accidental deletion protection (optional, can set true in prod)
  tags = merge(
    local.common_tags, # Common tags (from locals) — like { Project = roboshop, Environment = dev }
    {
      Name = "${local.common_name_suffix}-backend-alb" # Adds a Name tag for easy identification in AWS console
    }
  )
}

# When you specify multiple subnets:ALB creates nodes in each subnet (one per Availability Zone).
# AWS automatically handles DNS-based load distribution across those AZs


# ------------------------------------------------------------
# Create a Listener for the Backend ALB
# ------------------------------------------------------------

resource "aws_lb_listener" "backend_alb" {
  load_balancer_arn = aws_lb.backend_alb.arn # Connects this listener to the ALB created above
  port              = "80"                   # Listens on port 80 (HTTP)
  protocol          = "HTTP"                 # Protocol type (HTTP)

  # Default action if no specific rules match
  default_action {
    type = "fixed-response" # Returns a fixed response to the client

    fixed_response {
      content_type = "text/plain"                     # MIME type of the response
      message_body = "Hi, I am from backend ALB HTTP" # Response body (useful as a placeholder or health check)
      status_code  = "200"                            # HTTP status code to return
    }
  }
}

# ------------------------------------------------------------
# Create a DNS Record in Route53 for the Backend ALB
# ------------------------------------------------------------

resource "aws_route53_record" "backend_alb" {
  zone_id = var.zone_id                                           # The Route53 hosted zone ID (already existing in your AWS account)
  name    = "*.backend-alb-${var.environment}.${var.domain_name}" # Creates a wildcard subdomain (e.g., *.backend-alb-dev.example.com)
  type    = "A"                                                   # 'A' record maps domain to IPv4 address (ALB uses alias instead of static IP)
  #Since an ALB doesn’t have a static IP, we use the alias block.
  alias {
    # These values are automatically provided by AWS when ALB is created
    name                   = aws_lb.backend_alb.dns_name # ALB's DNS name (system DNS name of your ALB-created default in aws)
    zone_id                = aws_lb.backend_alb.zone_id  # ALB's hosted zone ID (for aliasing in Route53)
    evaluate_target_health = true                        # Route53 checks ALB health before routing traffic
  }
}
