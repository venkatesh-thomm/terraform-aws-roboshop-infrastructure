###############################################
# CLOUDFRONT DISTRIBUTION
###############################################

resource "aws_cloudfront_distribution" "roboshop" {
  origin {                                                                    # ORIGIN CONFIGURATION
    domain_name = "${var.project_name}-${var.environment}.${var.domain_name}" # Application domain → e.g., roboshop-dev.venkatesh.fun-->this is the ALB DNS name
    origin_id   = "${var.project_name}-${var.environment}.${var.domain_name}" # CloudFront requires an origin_id to reference this origin
    custom_origin_config {                                                    # This sets the behaviour for the origin (ALB/EC2/anything)
      http_port              = 80                                             # Origin HTTP port
      https_port             = 443                                            # Origin HTTPS port
      origin_protocol_policy = "https-only"                                   # Always connect to origin using HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]                                    # Minimum SSL version
    }
  }

  enabled = true # Enable the CloudFront distribution

  # -------------------------
  # CLOUDFRONT ALIASES (CUSTOM DOMAIN)
  # -------------------------

  aliases = ["${var.environment}.${var.domain_name}"] # This tells CloudFront to respond to requests for dev.venkatesh.fun

  # -------------------------
  # DEFAULT CACHE BEHAVIOR
  # -------------------------

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]                                             # Only GET/HEAD are actually cached
    target_origin_id       = "${var.project_name}-${var.environment}.${var.domain_name}" # Attach this behavior to the origin defined above
    viewer_protocol_policy = "https-only"                                                # Force HTTPS for clients
    cache_policy_id        = local.cachingDisabled                                       # Custom cache policy → defined in locals
  }


  #################################################################
  # ORDERED CACHE BEHAVIOR (Higher Priority Than Default)
  #################################################################

  # -------------------------
  # Caching for /media/*
  # -------------------------
  ordered_cache_behavior {
    path_pattern           = "/media/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "${var.project_name}-${var.environment}.${var.domain_name}"
    viewer_protocol_policy = "https-only"
    cache_policy_id        = local.cachingOptimised # Use optimised caching for media resources
  }

  # -------------------------
  # Caching for /images/*
  # -------------------------
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "${var.project_name}-${var.environment}.${var.domain_name}"
    viewer_protocol_policy = "https-only"
    cache_policy_id        = local.cachingOptimised
  }


  # -------------------------
  # USE ALL EDGE LOCATIONS
  # -------------------------
  price_class = "PriceClass_All"


  # -------------------------
  # GEO RESTRICTIONS (WHITELIST)
  # -------------------------
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "IN", "TH", "DE"] # Allow only these countries
    }
  }


  # -------------------------
  # TAGS
  # -------------------------
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}"
    }
  )


  # -------------------------
  # SSL CERTIFICATE FOR HTTPS
  # -------------------------
  viewer_certificate {
    acm_certificate_arn = local.cdn_certificate_arn # ACM Cert in us-east-1 (required by CloudFront)
    ssl_support_method  = "sni-only"                # Standard HTTPS with SNI
  }
}

#######################################################
# ROUTE53 RECORD—POINT DOMAIN TO CLOUDFRONT
#######################################################

resource "aws_route53_record" "cdn" {
  zone_id         = var.zone_id
  name            = "${var.environment}.${var.domain_name}" # e.g., dev.venkatesh.fun
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_cloudfront_distribution.roboshop.domain_name    # CloudFront domain name (NOT your app domain)
    zone_id                = aws_cloudfront_distribution.roboshop.hosted_zone_id # CloudFront hosted zone ID
    evaluate_target_health = true
  }
}
