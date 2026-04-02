# 🧩 Roboshop Database Infrastructure (Terraform)

This Terraform configuration automates provisioning of **database layer components** for the Roboshop application — MongoDB, Redis, RabbitMQ, and MySQL — in AWS.

---

## 🗂️ Components

### 1. EC2 Instances
Creates one EC2 instance per database:
- **MongoDB**
- **Redis**
- **RabbitMQ**
- **MySQL**

Each instance:
- Uses AMI defined in `locals.tf`
- Deployed in a **database subnet** (private)
- Attached to its respective **security group**
- Tagged with common tags + environment name

---

### 2. Terraform Data Blocks (Provisioners)

Each instance has a corresponding `terraform_data` resource that:

- Connects via SSH (`ec2-user` / password: `DevOps321`)
- Uploads `bootstrap.sh` script to `/tmp/`
- Executes the script with a component-specific argument:
  ```bash
  sudo sh /tmp/bootstrap.sh <component> [environment]
  ```

This installs and configures each database automatically after instance creation.

---

### 3. IAM Instance Profile (for MySQL)
  MySQL instance attaches an **IAM Instance Profile** with the role `EC2SSMParameterRead`  Pre-created IAM role with SSM read permissions.Please ensure this role exists in your AWS account before applying the Terraform configuration. 

  → allows it to securely read credentials (like DB passwords) from AWS Systems Manager Parameter Store.

---

### 4. Route53 DNS Records
Creates private DNS records for internal communication between app services:
| Service | Record Example |
|----------|----------------|
| MongoDB  | mongodb-dev.venkatesh.fun |
| Redis    | redis-dev.venkatesh.fun   |
| MySQL    | mysql-dev.venkatesh.fun   |
| RabbitMQ | rabbitmq-dev.venkatesh.fun |

Each record points to the **private IP** of the corresponding EC2 instance.

---

## ⚙️ File Summary

| File | Description |
|------|--------------|
| `main.tf` | Main Terraform configuration for DB layer |
| `bootstrap.sh` | Script copied & executed on each instance for setup |
| `locals.tf` | Contains common values like AMI IDs, tags, subnets |
| `variables.tf` | Environment variables (zone ID, domain name, environment) |

---

## 🚀 Deployment Steps

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Validate configuration:
   ```bash
   terraform validate
   ```

3. Preview plan:
   ```bash
   terraform plan
   ```

4. Apply changes:
   ```bash
   terraform apply -auto-approve
   ```

---

## 🧹 Cleanup
To destroy all created resources:
```bash
terraform destroy -auto-approve
```

---

## 🛠️ Notes

- Ensure SSH access to private subnets (through a bastion host or session manager).
- Provisioners run **locally**, so the local machine must reach the instance IP.
- Update `locals.tf` if subnet IDs, security groups, or AMIs change.
- `bootstrap.sh` should handle installation of MongoDB, Redis, RabbitMQ, and MySQL respectively.

---

