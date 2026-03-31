#!/bin/bash



# ------------------------------------------------------------
# 1. Grow the /home volume to increase available space
# ------------------------------------------------------------


growpart /dev/nvme0n1 4                      # Extend the 4th partition on the main NVMe disk (/dev/nvme0n1p4) # Used when EC2 uses LVM and /home is running out of space
lvextend -L +30G /dev/mapper/RootVG-homeVol  # Extend the logical volume (homeVol) inside the RootVG volume group by 30 GB
xfs_growfs /home                             # Resize the XFS filesystem to use the newly allocated space

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform

# sudo lvreduce -r -L 6G /dev/mapper/RootVG-rootVol
# ------------------------------------------------------------
# Clone roboshop-dev-infra repo and set permissions
# ------------------------------------------------------------


cd /home/ec2-user  # Move to ec2-user’s home directory

git clone https://github.com/venkatesh-thomm/roboshop-dev-infra.git     # Clone the infrastructure repository containing Terraform code

chown ec2-user:ec2-user -R roboshop-dev-infra                        # Ensure the cloned repo and all its files are owned by ec2-user and  # (-R = recursive, applies to all subfolders and files)


# ------------------------------------------------------------
# Initialize and apply Terraform for database setup
# ------------------------------------------------------------


cd roboshop-dev-infra/40-databases    # Navigate to the "40-databases" Terraform folder inside the repo


terraform init                        # Initialize Terraform (downloads providers, sets up backend)


terraform apply -auto-approve         # Apply Terraform configuration automatically without asking for confirmation


# ------------------------------------------------------------
# End of script
# ------------------------------------------------------------


# creating databases
# cd /home/ec2-user
# git clone https://github.com/venkatesh-thomm/roboshop-dev-infra.git
# chown ec2-user:ec2-user -R roboshop-dev-infra
# cd roboshop-dev-infra/40-databases
# terraform init
# terraform apply -auto-approve
