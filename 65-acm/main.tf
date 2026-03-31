
##############################################
# AWS ACM CERTIFICATE AND VALIDATION SETUP
##############################################

# ---------------------------------------------------------------------------
# STEP 1: Request an ACM Certificate
# ---------------------------------------------------------------------------
# - Creates a wildcard SSL certificate for your domain (example: *.venkatesh.fun)
# - The certificate will be used for services like ALB, CloudFront, etc.
# - Validation method is DNS, meaning we’ll prove ownership of the domain
#   by creating DNS records in Route53 
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "roboshop" {

  domain_name       = "*.${var.domain_name}" # Issue a wildcard certificate to cover all subdomains ; Example: *.daws86s.fun will work for catalogue.daws86s.fun, cart.daws86s.fun, etc.
  validation_method = "DNS"                  # ACM will require DNS validation for ownership verification

  tags = merge(
    local.common_tags,
    {
      Name = local.common_name_suffix
    }
  )

  # Ensure Terraform creates the new certificate before destroying the old one (useful when re-creating or rotating certificates)
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# STEP 2: Create Route53 DNS Records for Validation
# ---------------------------------------------------------------------------
# - ACM provides a set of DNS records (CNAME) to prove domain ownership.
# - This resource automatically creates those DNS records in Route53.
# - for_each is used to handle multiple domain validation options
#   (for example, the root domain and wildcard subdomain).
# ---------------------------------------------------------------------------

resource "aws_route53_record" "roboshop" {
  # Create one DNS record for each domain validation option ACM requires
  for_each = {
    for dvo in aws_acm_certificate.roboshop.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name  # DNS record name (provided by ACM)
      record = dvo.resource_record_value # Record value (provided by ACM)
      type   = dvo.resource_record_type  # Record type (usually CNAME)
    }
  }

  # Allow overwriting DNS records if they already exist
  allow_overwrite = true

  # Assign DNS record properties from ACM-provided values
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type

  # Time-to-live in seconds — set to 1 for quick propagation in testing
  ttl = 1

  # Your hosted zone ID in Route53 (passed from variable)
  zone_id = var.zone_id
}

# ---------------------------------------------------------------------------
# STEP 3: Validate the Certificate
# ---------------------------------------------------------------------------
# - After creating the DNS records, ACM will check them automatically.
# - This resource waits until ACM confirms the certificate is validated.
# - The validation_record_fqdns argument references all the Route53 records created.
# ---------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "roboshop" {
  # The ARN of the certificate created above
  certificate_arn = aws_acm_certificate.roboshop.arn

  # List of fully qualified domain names (FQDNs) for validation
  validation_record_fqdns = [
    for record in aws_route53_record.roboshop : record.fqdn
  ]
}












# --------------------------------------------------------------------------------------

# 1️⃣	aws_acm_certificate.roboshop	            Requests a wildcard SSL certificate for your domain
# 2️⃣	aws_route53_record.roboshop	              Creates DNS CNAME records for ACM validation
# 3️⃣	aws_acm_certificate_validation.roboshop	  Waits for ACM to verify DNS and activate the certificate

# After running terraform apply, you’ll see:
# A new certificate in AWS Certificate Manager (ACM)
# DNS validation records automatically created in Route53
# Once validation is complete, the certificate will show “Issued” status in ACM.
