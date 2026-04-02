##############################################
# MONGODB INSTANCE AND CONFIGURATION
##############################################


resource "aws_instance" "mongodb" {
  ami                    = local.ami_id             # AMI ID (Amazon Machine Image) from locals
  instance_type          = "t3.micro"               # Instance type
  vpc_security_group_ids = [local.mongodb_sg_id]    # Security Group for MongoDB
  subnet_id              = local.database_subnet_id # Launch instance in database subnet

  tags = merge(
    local.common_tags, # Common tags (like project, environment, etc.)
    {
      Name = "${local.common_name_suffix}-mongodb" # Example: roboshop-dev-mongodb
    }
  )
}

# Terraform "provisioner" resource to configure MongoDB instance after creation
# Terraform directly connects to the EC2 instance (via SSH), copies bootstrap.sh to it, and runs it.

resource "terraform_data" "mongodb" {
  triggers_replace = [
    aws_instance.mongodb.id # Re-run provisioners if MongoDB instance is replaced
  ]

  # SSH connection configuration for remote access
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"                     # SSH password
    host     = aws_instance.mongodb.private_ip # Connect using private IP
  }

  # Copy the bootstrap.sh script from local to the instance
  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  # Run the bootstrap script on the remote instance
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",       # Make the script executable
      "sudo sh /tmp/bootstrap.sh mongodb" # Run script to configure MongoDB
    ]
  }
}

##############################################
# REDIS INSTANCE AND CONFIGURATION
##############################################


resource "aws_instance" "redis" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.redis_sg_id]
  subnet_id              = local.database_subnet_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-redis" # Example: roboshop-dev-redis
    }
  )
}

# Provision Redis after instance creation
resource "terraform_data" "redis" {
  triggers_replace = [
    aws_instance.redis.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.redis.private_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh redis" # Run script to configure Redis
    ]
  }
}

##############################################
# RABBITMQ INSTANCE AND CONFIGURATION
##############################################

resource "aws_instance" "rabbitmq" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.rabbitmq_sg_id]
  subnet_id              = local.database_subnet_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-rabbitmq" # Example: roboshop-dev-rabbitmq
    }
  )
}

# Provision RabbitMQ after instance creation
resource "terraform_data" "rabbitmq" {
  triggers_replace = [
    aws_instance.rabbitmq.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.rabbitmq.private_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh rabbitmq" # Run script to configure RabbitMQ
    ]
  }
}

##############################################
# MYSQL INSTANCE AND CONFIGURATION
##############################################

# Create EC2 instance for MySQL
resource "aws_instance" "mysql" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.mysql_sg_id]
  subnet_id              = local.database_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.mysql.name # Attach IAM role for SSM Parameter read access

  tags = merge(
    local.common_tags,
    {
      Name = "${local.common_name_suffix}-mysql" # Example: roboshop-dev-mysql
    }
  )
}

# IAM role attachment (to read SSM parameters, used by MySQL setup)
resource "aws_iam_instance_profile" "mysql" {
  name = "mysql"
  role = "EC2SSMParameterRead" # Pre-created IAM role with SSM read permissions.Please ensure this role exists in your AWS account before applying the Terraform configuration.
}

# Provision MySQL after instance creation
resource "terraform_data" "mysql" {
  triggers_replace = [
    aws_instance.mysql.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.mysql.private_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh mysql dev" # Run script with MySQL and environment arguments
    ]
  }
}

##############################################
# ROUTE53 RECORDS (DNS)
##############################################

# Create DNS record for MongoDB
resource "aws_route53_record" "mongodb" {
  zone_id         = var.zone_id
  name            = "mongodb-${var.environment}.${var.domain_name}" # mongodb-dev.venkatesh.fun
  type            = "A"                                             # IPv4 address record
  ttl             = 1                                               # Low TTL for fast updates
  records         = [aws_instance.mongodb.private_ip]               # Map to MongoDB private IP
  allow_overwrite = true                                            # Allow updates if IP changes
}

# Create DNS record for Redis
resource "aws_route53_record" "redis" {
  zone_id         = var.zone_id
  name            = "redis-${var.environment}.${var.domain_name}" # redis-dev.venkatesh.fun
  type            = "A"
  ttl             = 1
  records         = [aws_instance.redis.private_ip]
  allow_overwrite = true
}

# Create DNS record for MySQL
resource "aws_route53_record" "mysql" {
  zone_id         = var.zone_id
  name            = "mysql-${var.environment}.${var.domain_name}" # mysql-dev.venkatesh.fun
  type            = "A"
  ttl             = 1
  records         = [aws_instance.mysql.private_ip]
  allow_overwrite = true
}

# Create DNS record for RabbitMQ
resource "aws_route53_record" "rabbitmq" {
  zone_id         = var.zone_id
  name            = "rabbitmq-${var.environment}.${var.domain_name}" # rabbitmq-dev.venkatesh.fun
  type            = "A"
  ttl             = 1
  records         = [aws_instance.rabbitmq.private_ip]
  allow_overwrite = true
}
