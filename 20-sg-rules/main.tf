##############################################
# Allows Bastion host to connect to MongoDB via SSH (port 22) for administration.
##############################################

resource "aws_security_group_rule" "mongodb_bastion" {
  type                     = "ingress"
  security_group_id        = local.mongodb_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Catalogue service to connect to MongoDB on port 27017 for data access.
##############################################

resource "aws_security_group_rule" "mongodb_catalogue" {
  type                     = "ingress"
  security_group_id        = local.mongodb_sg_id
  source_security_group_id = local.catalogue_sg_id
  from_port                = 27017
  protocol                 = "tcp"
  to_port                  = 27017
}

##############################################
# Allows User service to connect to MongoDB on port 27017 for user data access.to mongodb
##############################################

resource "aws_security_group_rule" "mongodb_user" {
  type                     = "ingress"
  security_group_id        = local.mongodb_sg_id
  source_security_group_id = local.user_sg_id
  from_port                = 27017
  protocol                 = "tcp"
  to_port                  = 27017
}

##############################################
# Allows Bastion host to connect to Redis via SSH (port 22) for maintenance.
##############################################


resource "aws_security_group_rule" "redis_bastion" {
  type                     = "ingress"
  security_group_id        = local.redis_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows User service to connect to Redis on port 6379 for caching operations.
##############################################

resource "aws_security_group_rule" "redis_user" {
  type                     = "ingress"
  security_group_id        = local.redis_sg_id
  source_security_group_id = local.user_sg_id
  from_port                = 6379
  protocol                 = "tcp"
  to_port                  = 6379
}

##############################################
# Allows Cart service to connect to Redis on port 6379 for session and cache access.
##############################################

resource "aws_security_group_rule" "redis_cart" {
  type                     = "ingress"
  security_group_id        = local.redis_sg_id
  source_security_group_id = local.cart_sg_id
  from_port                = 6379
  protocol                 = "tcp"
  to_port                  = 6379
}

##############################################
# Allows Bastion host to connect to MySQL via SSH (port 22) for troubleshooting.
##############################################

resource "aws_security_group_rule" "mysql_bastion" {
  type                     = "ingress"
  security_group_id        = local.mysql_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}


##############################################
# Allows Shipping service to connect to MySQL on port 3306 for database access.
##############################################

resource "aws_security_group_rule" "mysql_shipping" {
  type                     = "ingress"
  security_group_id        = local.mysql_sg_id
  source_security_group_id = local.shipping_sg_id
  from_port                = 3306
  protocol                 = "tcp"
  to_port                  = 3306
}

##############################################
# Allows Bastion host to connect to RabbitMQ via SSH (port 22) for management.
##############################################

resource "aws_security_group_rule" "rabbitmq_bastion" {
  type                     = "ingress"
  security_group_id        = local.rabbitmq_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Payment service to connect to RabbitMQ on port 5672 for message queuing.
##############################################

resource "aws_security_group_rule" "rabbitmq_payment" {
  type                     = "ingress"
  security_group_id        = local.rabbitmq_sg_id
  source_security_group_id = local.payment_sg_id
  from_port                = 5672
  protocol                 = "tcp"
  to_port                  = 5672
}

##############################################
###### Catalogue SG Rules ######
# Allows Bastion host to connect to Catalogue service via SSH (port 22).
##############################################


resource "aws_security_group_rule" "catalogue_bastion" {
  type                     = "ingress"
  security_group_id        = local.catalogue_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Backend ALB to forward traffic to Catalogue service on port 8080.
##############################################

resource "aws_security_group_rule" "catalogue_backend_alb" {
  type                     = "ingress"
  security_group_id        = local.catalogue_sg_id
  source_security_group_id = local.backend_alb_sg_id
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
}

# This is the mistake we did, cart can't access catalogue directly, it should be through backend ALB
/* resource "aws_security_group_rule" "catalogue_cart" {
  type              = "ingress"
  security_group_id = local.catalogue_sg_id
  source_security_group_id = local.cart_sg_id
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
} */

##############################################
##### User SG Rules #####
# Allows Bastion host to connect to User service via SSH (port 22).
##############################################

resource "aws_security_group_rule" "user_bastion" {
  type                     = "ingress"
  security_group_id        = local.user_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}


##############################################
# Allows Backend ALB to send traffic to User service on port 8080.
##############################################

resource "aws_security_group_rule" "user_backend_alb" {
  type                     = "ingress"
  security_group_id        = local.user_sg_id
  source_security_group_id = local.backend_alb_sg_id
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
}

##############################################
##### Cart SG Rules #####
# Allows Bastion host to connect to Cart service via SSH (port 22).
##############################################

resource "aws_security_group_rule" "cart_bastion" {
  type                     = "ingress"
  security_group_id        = local.cart_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Backend ALB to send traffic to Cart service on port 8080.
##############################################

resource "aws_security_group_rule" "cart_backend_alb" {
  type                     = "ingress"
  security_group_id        = local.cart_sg_id
  source_security_group_id = local.backend_alb_sg_id
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
}

##############################################
##### Shipping SG Rules #####
# Allows Bastion host to connect to Shipping service via SSH (port 22).
##############################################

resource "aws_security_group_rule" "shipping_bastion" {
  type                     = "ingress"
  security_group_id        = local.shipping_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Backend ALB to send traffic to Shipping service on port 8080.
##############################################

resource "aws_security_group_rule" "shipping_backend_alb" {
  type                     = "ingress"
  security_group_id        = local.shipping_sg_id
  source_security_group_id = local.backend_alb_sg_id
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
}


##############################################
##### Payment SG Rules #####
# Allows Bastion host to connect to Payment service via SSH (port 22).
##############################################

resource "aws_security_group_rule" "payment_bastion" {
  type                     = "ingress"
  security_group_id        = local.payment_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Backend ALB to send traffic to Payment service on port 8080.
##############################################

resource "aws_security_group_rule" "payment_backend_alb" {
  type                     = "ingress"
  security_group_id        = local.payment_sg_id
  source_security_group_id = local.backend_alb_sg_id
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
}

##############################################
# Allows Shipping service to connect to Payment on port 8080 (for internal API calls).
##############################################

resource "aws_security_group_rule" "payment_shipping" {
  type                     = "ingress"
  security_group_id        = local.payment_sg_id
  source_security_group_id = local.shipping_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
##### Backend ALB SG Rules #####
# Allows Bastion host to connect to Backend ALB over HTTP (port 80) for verification/testing.
##############################################

resource "aws_security_group_rule" "backend_alb_bastion" {
  type                     = "ingress"
  security_group_id        = local.backend_alb_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
# Allows Frontend service to connect to Backend ALB on port 80.
##############################################

resource "aws_security_group_rule" "backend_alb_frontend" {
  type                     = "ingress"
  security_group_id        = local.backend_alb_sg_id
  source_security_group_id = local.frontend_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
# Allows Cart service to connect to Backend ALB on port 80.
##############################################

resource "aws_security_group_rule" "backend_alb_cart" {
  type                     = "ingress"
  security_group_id        = local.backend_alb_sg_id
  source_security_group_id = local.cart_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
# Allows Shipping service to connect to Backend ALB on port 80.
##############################################

resource "aws_security_group_rule" "backend_alb_shipping" {
  type                     = "ingress"
  security_group_id        = local.backend_alb_sg_id
  source_security_group_id = local.shipping_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
# Allows Payment service to connect to Backend ALB on port 80.
##############################################

resource "aws_security_group_rule" "backend_alb_payment" {
  type                     = "ingress"
  security_group_id        = local.backend_alb_sg_id
  source_security_group_id = local.payment_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
##### Frontend SG Rules #####
# Allows Bastion host to connect to Frontend instance via SSH (port 22).
##############################################

resource "aws_security_group_rule" "frontend_bastion" {
  type                     = "ingress"
  security_group_id        = local.frontend_sg_id
  source_security_group_id = local.bastion_sg_id
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
}

##############################################
# Allows Frontend ALB to forward HTTP traffic (port 80) to Frontend instances.
##############################################

resource "aws_security_group_rule" "frontend_frontend_alb" {
  type                     = "ingress"
  security_group_id        = local.frontend_sg_id
  source_security_group_id = local.frontend_alb_sg_id
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
}

##############################################
# Allows public users to access Frontend ALB via HTTPS (port 443) from anywhere.
##############################################

resource "aws_security_group_rule" "frontend_alb_public" {
  type              = "ingress"
  security_group_id = local.frontend_alb_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
}

##############################################
##### Bastion SG Rules #####
# Allows engineers to SSH into Bastion from any IP (for access to private instances).
##############################################

resource "aws_security_group_rule" "bastion_laptop" {
  type              = "ingress"
  security_group_id = local.bastion_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
}

resource "aws_security_group_rule" "open_vpn_public" {
  type              = "ingress"
  security_group_id = local.open_vpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
}

resource "aws_security_group_rule" "open_vpn_943" {
  type              = "ingress"
  security_group_id = local.open_vpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 943
  protocol          = "tcp"
  to_port           = 943
}

resource "aws_security_group_rule" "open_vpn_443" {
  type              = "ingress"
  security_group_id = local.open_vpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
}

resource "aws_security_group_rule" "open_vpn_1194" {
  type              = "ingress"
  security_group_id = local.open_vpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 1194
  protocol          = "tcp"
  to_port           = 1194
}

# resource "aws_security_group_rule" "catalogue_vpn" {
#   type              = "ingress"
#   security_group_id = local.catalogue_sg_id
#   source_security_group_id = local.open_vpn_sg_id
#   from_port         = 22
#   protocol          = "tcp"
#   to_port           = 22
# }

# resource "aws_security_group_rule" "catalogue_vpn_8080" {
#   type              = "ingress"
#   security_group_id = local.catalogue_sg_id
#   source_security_group_id = local.open_vpn_sg_id
#   from_port         = 8080
#   protocol          = "tcp"
#   to_port           = 8080
# }

resource "aws_security_group_rule" "components_vpn" {
  for_each                 = local.vpn_ingress_rules
  type                     = "ingress"
  security_group_id        = each.value.sg_id
  source_security_group_id = local.open_vpn_sg_id
  from_port                = each.value.port
  protocol                 = "tcp"
  to_port                  = each.value.port
}



#This is the mistake we did, cart can't access components directly from one component to another component. they should be communicated through backend ALB
/* resource "aws_security_group_rule" "cart_shipping" {
  type              = "ingress"
  security_group_id = local.cart_sg_id
  source_security_group_id = local.shipping_sg_id
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
}

resource "aws_security_group_rule" "user_payment" {
  type              = "ingress"
  security_group_id = local.user_sg_id
  source_security_group_id = local.payment_sg_id
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
}

resource "aws_security_group_rule" "cart_payment" {
  type              = "ingress"
  security_group_id = local.cart_sg_id
  source_security_group_id = local.payment_sg_id
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
} */
