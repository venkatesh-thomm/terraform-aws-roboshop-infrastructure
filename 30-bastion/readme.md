
# 🛡️ Bastion Host - Terraform Setup

This Terraform module provisions a **Bastion Host** (Jump Server) inside a **public subnet**, allowing secure SSH access to private EC2 instances such as MongoDB, Redis, MySQL, and application servers.

---

## 🏗️ Architecture Overview

```
                ┌────────────────────────┐
                │ Developer / Admin Laptop│
                │ (SSH via Port 22)       │
                └──────────────┬──────────┘
                               │
                               ▼
                      ┌────────────────┐
                      │ Bastion Host   │
                      │ (Public Subnet)│
                      │ SG: bastion_sg │
                      └────────┬───────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
       Private EC2 Instances         Database Servers
       (MongoDB, Redis, MySQL, etc.) (Private Subnets)
```

---

## ⚙️ Terraform Resources Explained

### 1. **EC2 Instance (Bastion Host)**

```hcl
resource "aws_instance" "bastion" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.bastion_sg_id]
  subnet_id              = local.public_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = file("bastion.sh")

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion"
    }
  )
}
```

🔍 **Key Points**
- **AMI**: Defined in `local.ami_id` (usually an Amazon Linux 2 image).
- **Instance Type**: `t3.micro` for cost efficiency.
- **Security Group**: Allows SSH (port 22) from trusted IPs.
- **Subnet**: Deployed in a **public subnet** for accessibility.
- **IAM Role**: Attached via an **instance profile** to give controlled AWS access.
- **User Data**: Runs a `bastion.sh` bootstrap script for initial setup.
- **Root Volume**: 50GB GP3 SSD for stability.

---

### 2. **IAM Instance Profile**

```hcl
resource "aws_iam_instance_profile" "bastion" {
  name = "bastion"
  role = "BastionTerraformAdmin"
}
```

💡 **Purpose**:  
Attaches the IAM Role `BastionTerraformAdmin` to the Bastion Host, enabling limited Terraform and AWS CLI access for automation tasks.

---

## 🔒 Security Best Practices

| Control | Description |
|----------|-------------|
| 🔐 **Restrict SSH** | Limit access to known IPs (your office/home network). |
| 🚫 **No direct SSH to private servers** | All private servers (DB, app) can only be accessed via Bastion. |
| 🧩 **IAM Role Usage** | Avoid storing AWS keys on the Bastion. Use IAM Role for AWS access. |
| 🔄 **Rotate AMI** | Regularly update the AMI to include latest security patches. |
| 🧱 **Disable Root Login** | Recommended in `bastion.sh` for extra security. |

---

## 🧠 Key Learnings

- Bastion hosts act as **secure jump points** to access private AWS instances.
- Using **IAM Instance Profiles** removes the need for long-term credentials.
- Terraform’s **user_data** simplifies bootstrapping scripts like package installs, CloudWatch agents, etc.

---

## 🚀 Deployment Steps

1. Ensure your VPC, subnets, and security groups exist.
2. Place your `bastion.sh` script in the same Terraform directory.
3. Run:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

4. After provisioning:
   ```bash
   ssh ec2-user@<bastion-public-ip>
   ```

---

## 🧾 Example Outputs

| Output | Example Value |
|--------|----------------|
| Bastion Public IP | `13.233.45.67` |
| Instance ID | `i-0f2345abc6789def0` |
| IAM Profile | `bastion` |

---

