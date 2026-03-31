#####################################
# EC2 INSTANCE FOR OPENVPN
#####################################

resource "aws_instance" "openvpn" {
  ami                    = local.ami_id                  # AMI ID for the EC2 instance, pulled from a local variable
  instance_type          = "t3.micro"                    # EC2 instance size/type
  #key_name               = aws_key_pair.openvpn.key_name # Using the key pair created above dynamically
  vpc_security_group_ids = [local.openvpn_sg_id]         # Attach the OpenVPN security group
  subnet_id              = local.public_subnet_id        # Launch in a public subnet so it gets a public IP
  user_data              = file("vpn.sh")                # This script will run at boot on the instance to install/configure VPN


  tags = merge(        # Tagging the EC2 instance
    local.common_tags, # Add shared/common tags like Project, Env, Owner
    {
      Name = "${var.project_name}-${var.environment}-openvpn" # Results in: <project>-<env>-openvpn   # Example: daws86s-dev-openvpn
    }
  )
}
# 👉 This creates the EC2 instance that will host your OpenVPN server.
# Terraform injects your SSH key, applies security groups, runs your setup script (user_data),and assigns tags for organization.



#####################################
# ROUTE53 DNS RECORD FOR OPENVPN
#####################################

resource "aws_route53_record" "openvpn" {
  zone_id         = var.zone_id                      # Hosted Zone ID where the record will be created
  name            = "openvpn.${var.domain_name}"     # DNS record name (subdomain) # Example output: openvpn.jansi1.site
  type            = "A"                              # We are creating an A record (IPv4 address mapping)
  ttl             = 1                                # Keep TTL low (1 sec) so DNS updates propagate fast
  records         = [aws_instance.openvpn.public_ip] # The public IP assigned to the EC2 instance above
  allow_overwrite = true                             # Allows Terraform to update the same record if it already exists
}
# 👉 This automatically creates a DNS record in Route53 pointing to your VPN instance’s public IP.
# After creation, you can connect via:
#   openvpn.venkatesh.fun
