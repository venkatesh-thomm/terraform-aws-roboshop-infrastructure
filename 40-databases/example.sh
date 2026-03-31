# ============================================================
# Roboshop Component Bootstrap Script
# ============================================================
# This script automates the configuration of a specific Roboshop component
# (like catalogue, user, cart, payment, etc.) on an EC2 instance.
#
# It performs the following steps:
#   1. Installs Ansible
#   2. Clones the Ansible Roboshop roles repository
#   3. Pulls the latest changes if already cloned
#   4. Executes the Ansible playbook for the given component
# ============================================================
# Capture input arguments
# ------------------------------------------------------------
# $1 → component name (e.g., catalogue, user, cart)
# $2 → environment (e.g., dev, prod)
# ------------------------------------------------------------

#!/bin/bash
component=$1
environment=$2

# ------------------------------------------------------------
# Step 1: Install Ansible
# ------------------------------------------------------------
# Installs Ansible using DNF package manager (RHEL 8/9 systems)
# This is required to run the playbooks later in the script.
# ------------------------------------------------------------
dnf install ansible -y

# ------------------------------------------------------------
# Step 2: Define variables for repository and directories
# ------------------------------------------------------------
# REPO_URL → GitHub URL of the Ansible playbook repository
# REPO_DIR → Directory where the repo will be cloned
# ANSIBLE_DIR → Folder name after cloning the repo
# ------------------------------------------------------------
REPO_URL="https://github.com/venkatesh-thomm/ansible-roboshop-roles-tf.git"
REPO_DIR=/opt/roboshop/ansible
ANSIBLE_DIR=ansible-roboshop-roles-tf

# ------------------------------------------------------------
# Step 3: Prepare required directories and log files
# ------------------------------------------------------------
# - Creates the directory structure for storing Ansible playbooks
# - Creates a log directory to capture execution logs
# - Touch creates an empty file 'ansible.log' for logging output
# ------------------------------------------------------------
mkdir -p $REPO_DIR
mkdir -p /var/log/roboshop/
touch ansible.log

# ------------------------------------------------------------
# Step 4: Navigate to the repository directory
# ------------------------------------------------------------
cd $REPO_DIR

# ------------------------------------------------------------
# Step 5: Check if the Ansible repository already exists
# ------------------------------------------------------------
# - If the repo folder exists, pull the latest changes.
# - If not, clone it fresh from GitHub.
# - This ensures the server always uses the latest Ansible roles.
# ------------------------------------------------------------
if [ -d $ANSIBLE_DIR ]; then
    # Repository already exists → Update it
    cd $ANSIBLE_DIR
    git pull
else
    # Repository not found → Clone it
    git clone $REPO_URL
    cd $ANSIBLE_DIR
fi

# ------------------------------------------------------------
# Step 6: Display environment info for reference
# ------------------------------------------------------------
echo "Environment is: $2"

# ------------------------------------------------------------
# Step 7: Run the Ansible playbook
# ------------------------------------------------------------
# Executes the main playbook (main.yaml) with the provided variables.
# -e component=$component → Tells Ansible which service to configure
# -e env=$environment → Specifies environment type (dev, prod, etc.)
# ------------------------------------------------------------
ansible-playbook -e component=$component -e env=$environment main.yaml

# -----------------------------------------------------------------------------
# Step 7: End message
# -----------------------------------------------------------------------------
echo "✅ Deployment completed for component: $component in environment: $environment"
echo "Logs saved to: /var/log/roboshop/ansible.log"


#✅ To View Logs
#cat /var/log/roboshop/ansible.log

#🔥 To watch logs live while deployment is running
#tail -f /var/log/roboshop/ansible.log

#📜 To view logs page by page (scroll)
#less /var/log/roboshop/ansible.log

#🔍 To search for errors
#grep -i "error" /var/log/roboshop/ansible.log