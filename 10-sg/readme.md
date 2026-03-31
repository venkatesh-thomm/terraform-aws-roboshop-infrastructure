
# 🧱 AWS Security Group (SG) Architecture - (Terraform)

This document explains the **Security Group architecture** used in the Roboshop AWS infrastructure.  
It defines how network access is controlled between components like **Bastion**, **Backend ALB**, **Catalogue**, **MongoDB**, **Redis**, **RabbitMQ**, and **MySQL**.

---

## 📘 Overview

Security Groups (SGs) act as virtual firewalls controlling inbound and outbound traffic for AWS resources.  
This setup isolates each layer (bastion, app, database) for security and maintainability.

---

## 🖼️ Network Flow Diagram (ASCII)

```
               +---------------------+
               |     Laptop (User)   |
               |  SSH (22)           |
               +----------+----------+
                          |
                          v
               +---------------------+
               |     Bastion SG      |
               |  SSH to all private |
               +----------+----------+
                          |
        ------------------------------------------------
        |          |           |           |           |
        v          v           v           v           v
+--------------+ +--------------+ +--------------+ +--------------+
| MongoDB SG   | | Redis SG     | | RabbitMQ SG  | | MySQL SG     |
| 22 from Bast | | 22 from Bast | | 22 from Bast | | 22 from Bast |
| 27017 from   | |              | |              | |              |
| Catalogue SG | +--------------+ +--------------+ +--------------+
+--------------+
        ^
        |
+--------------+
| Catalogue SG |
| 22 from Bast |
| 8080 from    |
| Backend ALB  |
+--------------+
        ^
        |
+--------------+
| Backend ALB  |
| Port 80 HTTP |
+--------------+
```

---

## 🧩 Terraform Module Example

```hcl
module "sg" {
  count          = length(var.sg_names)
  source         = "git::https://github.com/venkatesh-thomm/terraform-aws-sg.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = var.sg_names[count.index]
  sg_description = "Created for ${var.sg_names[count.index]}"
  vpc_id         = local.vpc_id
}
```

---

## 🔒 Ingress Rules Summary

| Source | Destination | Port | Protocol | Purpose |
|--------|--------------|------|-----------|----------|
| Laptop | Bastion | 22 | TCP | SSH access |
| Bastion | MongoDB | 22 | TCP | SSH to DB |
| Bastion | Redis | 22 | TCP | SSH to cache |
| Bastion | RabbitMQ | 22 | TCP | SSH to message broker |
| Bastion | MySQL | 22 | TCP | SSH to database |
| Bastion | Catalogue | 22 | TCP | SSH to app |
| Backend ALB | Catalogue | 8080 | TCP | App traffic |
| Catalogue | MongoDB | 27017 | TCP | App ↔ DB |
| Backend ALB | Port 80 | 80 | TCP | External HTTP |

---

## 🏷️ Tagging Convention

| Tag Key | Description |
|----------|--------------|
| Name | `<project>-<env>-<component>` |
| Environment | dev, qa, prod |
| ManagedBy | Terraform |
| Project | roboshop |

---

## ⚙️ Best Practices

✅ Use **least privilege** — open only required ports.  
✅ Restrict **SSH access to Bastion only** (never directly to DB or app).  
✅ Use **different SGs for each tier** to maintain clear separation.  
✅ Review rules regularly using **AWS Trusted Advisor** or **Terraform plan**.  
✅ Keep **naming consistent** across all SGs.

---

## 🚀 Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🧠 Key Concepts


###  **Dynamic Resource Creation**
- The `count` meta-argument loops through all items in the variable `var.sg_names`.
- For each item, a new **security group** is created.

Example:
```hcl
var.sg_names = ["bastion", "mongodb", "redis", "rabbitmq", "mysql", "catalogue"]
```

✅ Terraform will create:
- bastion SG  
- mongodb SG  
- redis SG  
- rabbitmq SG  
- mysql SG  
- catalogue SG  

Each will be uniquely tagged and described.

---

### 3. **Inputs Explained**

| Variable | Description | Example |
|-----------|-------------|----------|
| `project_name` | Name of the project | `"roboshop"` |
| `environment` | Deployment environment | `"dev"` |
| `sg_name` | Name of each security group | `"bastion"`, `"mongodb"`, etc. |
| `sg_description` | Description for each SG | `"Created for bastion"` |
| `vpc_id` | The ID of the VPC to associate SGs with | `"vpc-0abc123def456ghi7"` |

---

### 4. **Outputs**
The module likely exports:
- **SG IDs**
- **SG Names**

You can reference them like this:
```hcl
output "sg_ids" {
  value = [for sg in module.sg : sg.security_group_id]
}
```

---

## 🧠 Key Learnings
- Using **modules** encourages **code reusability** and **standardization** across environments.
- `count` or `for_each` is ideal for dynamic resource creation.
- You can maintain all SG logic (inbound/outbound rules, tags) inside a **centralized module**, reducing duplication.

---



## 📘 Example Output

```bash
Outputs:

module.sg[0].security_group_id = "sg-0a123bc456d789e01"
module.sg[1].security_group_id = "sg-0b234cd567e890f12"
module.sg[2].security_group_id = "sg-0c345de678f901g23"
```
