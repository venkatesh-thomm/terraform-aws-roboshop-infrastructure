##############################################
# FRONTEND APPLICATION LOAD BALANCER (ALB)
##############################################

# ---------------------------------------------------------------------------
# STEP 1: Create the Frontend Application Load Balancer
# ---------------------------------------------------------------------------
# - Creates an **internet-facing** (public) ALB.
# - Used to serve incoming HTTPS traffic for the frontend app.
# - Placed in public subnets so it’s accessible from the internet.
# - Associated with a security group that allows HTTPS (443) access.
# ---------------------------------------------------------------------------

resource "aws_lb" "frontend_alb" {
  name                       = "${local.common_name_suffix}-frontend-alb" # roboshop-dev-frontend-alb
  internal                   = false                                      # Internet-facing ALB (public access)
  load_balancer_type         = "application"                              # ALB type - Application Load Balancer (Layer 7)
  security_groups            = [local.frontend_alb_sg_id]                 # SG that controls access to the ALB (should allow port 443)
  subnets                    = local.public_subnet_ids                    # ALB must be in public subnets to allow internet access
  enable_deletion_protection = false                                      # Disable deletion protection (useful for testing/demo environments)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-frontend-alb"
    }
  )
}

# ---------------------------------------------------------------------------
# STEP 2: Create an HTTPS Listener for the ALB
# ---------------------------------------------------------------------------
# - Listens on port 443 (HTTPS).
# - Uses the provided ACM certificate for SSL/TLS termination.
# - For now, returns a static HTML message as a test response.
#   (Later, we’ll add listener rules to forward traffic to Target Groups.)
# ---------------------------------------------------------------------------

resource "aws_lb_listener" "frontend_alb" {
  load_balancer_arn = aws_lb.frontend_alb.arn # Attach listener to the ALB created above
  port              = "443"                   # HTTPS port and protocol
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  certificate_arn   = local.frontend_alb_certificate_arn # Use an existing ACM certificate ARN (stored in locals)
  default_action {                                       # Default listener action (executed when no listener rules match)
    type = "fixed-response"

    fixed_response {
      # Simple HTML message for testing
      content_type = "text/html"
      message_body = "<h1>Hi, I am from HTTPS frontend ALB</h1>"
      status_code  = "200"
    }
  }
}

# ---------------------------------------------------------------------------
# STEP 3: Create Route53 Record for the Frontend ALB
# ---------------------------------------------------------------------------
# - Creates an **A record (Alias)** in Route53 to point your domain
#   (like roboshop-dev.venkatesh.fun) to the ALB DNS name.
# - Uses the ALB’s DNS name and hosted zone ID automatically.
# ---------------------------------------------------------------------------

resource "aws_route53_record" "frontend_alb" {
  zone_id         = var.zone_id                                      # Hosted Zone ID where your domain is managed
  name            = "roboshop-${var.environment}.${var.domain_name}" # Record name (final domain will be: roboshop-dev.jansi1.site)
  type            = "A"
  allow_overwrite = true                                  # Allow Terraform to overwrite existing records if necessary
  alias {                                                 # Alias configuration - points to ALB DNS
    name                   = aws_lb.frontend_alb.dns_name # The ALB’s DNS name (e.g., roboshop-dev-frontend-alb-123456.us-east-1.elb.amazonaws.com)
    zone_id                = aws_lb.frontend_alb.zone_id  # The ALB’s zone ID (automatically provided by AWS)
    evaluate_target_health = true                         # Use target health checks for Route53 failover logic
  }
}






# ---------------------------------------------------------
# 1️⃣	aws_lb.frontend_alb	Creates a public-facing Application Load Balancer in public subnets
# 2️⃣	aws_lb_listener.frontend_alb	Configures HTTPS listener on port 443 with ACM SSL certificate
# 3️⃣	aws_route53_record.frontend_alb	Creates a DNS record (A alias) in Route53 that maps domain to ALB

# After running terraform apply:
# You get a public HTTPS ALB.
# Accessing https://roboshop-dev.venkatesh.fun shows:
# Hi, I am from HTTPS frontend ALB
# The ALB is now ready to attach listener rules or Target Groups for your frontend app (like React or Nginx service).
