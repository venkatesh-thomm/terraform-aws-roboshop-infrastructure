resource "aws_instance" "bastion" {                              # Defines an EC2 instance named "bastion"
  ami                    = local.ami_id                          # The AMI ID to use for the instance (fetched from a local variable)
  instance_type          = "t3.micro"                            # EC2 instance type (size); t3.micro is a small, low-cost instance
  vpc_security_group_ids = [local.bastion_sg_id]                 # Attach this EC2 instance to a Security Group (from a local variable)
  subnet_id              = local.public_subnet_id                # Deploy the instance in this specific subnet (typically public for a bastion)
  iam_instance_profile   = aws_iam_instance_profile.bastion.name # Attach the IAM instance profile to give EC2 permissions

  # Root block device configuration (disk for OS)
  root_block_device {
    volume_size = 50    # Disk size in GB
    volume_type = "gp3" # Disk type: gp3 is a modern general-purpose SSD; gp2 is the older type
  }

  user_data = file("bastion.sh") # Shell script to run when the instance launches (bootstrap commands)

  tags = merge(        # Attach tags to the EC2 instance
    local.common_tags, # Merge common tags (like Project, Environment) from locals
    {
      Name = "${var.project_name}-${var.environment}-bastion" # Instance Name tag
    }
  )
}

# Attaches the IAM Role BastionTerraformAdmin to the Bastion Host, enabling limited Terraform and AWS CLI access for automation tasks.

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion"
  role = "BastionTerraformAdmin"
}
