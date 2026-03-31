# VPC Module - Terraform

## Overview
This module provisions a **Virtual Private Cloud (VPC)** in AWS with **public**, **private**, and **database** subnets.  
It is designed for modular and reusable infrastructure deployments following best DevOps and networking practices.

---

## 📘 Architecture Diagram (Text-Based)

```
                    +-----------------------------------+
                    |            AWS VPC                |
                    |    CIDR: 10.0.0.0/16              |
                    +-----------------------------------+
                      |           |             |
         --------------           |             --------------
        |                         |                          |
        v                         v                          v
+----------------+       +----------------+        +----------------+
| Public Subnets |       | Private Subnets|        | Database Subnets|
| (10.0.1.0/24)  |       | (10.0.2.0/24)  |        | (10.0.3.0/24)   |
|  IGW attached  |       |  NAT Gateway   |        |  No Internet     |
|  Bastion, ALB  |       |  App Servers   |        |  DB Instances    |
+----------------+       +----------------+        +----------------+

                        +--------------------+
                        |   VPC Peering      |
                        | (If enabled)       |
                        +--------------------+
```

---

## 🧩 Module Source

```hcl
module "vpc" {
  source       = "git::https://github.com/venkatesh-thomm/Terraform-vpc-module.git?ref=dev"
  cidr_block   = var.cidr_block
  project_name = var.project_name
  environment  = var.environment
  vpc_tags     = var.vpc_tags

  # Public Subnets
  public_subnet_cidrs = var.public_subnet_cidrs

  # Private Subnets
  private_subnet_cidrs = var.private_subnet_cidrs

  # Database Subnets
  database_subnet_cidrs = var.database_subnet_cidrs

  is_peering_required = true
}
```

---

## 🌐 Components Created

| Component               | Description |
|--------------------------|-------------|
| **VPC**                  | Main network container |
| **Internet Gateway (IGW)** | Enables internet access for public subnets |
| **Public Subnets**        | Hosts Bastion and ALB |
| **Private Subnets**       | Hosts internal app services |
| **Database Subnets**      | Used for RDS / MongoDB instances |
| **Route Tables**          | Separate routes for public and private subnets |
| **NAT Gateway**           | Provides outbound access for private subnets |
| **VPC Peering (optional)**| Enables connectivity with another VPC |

---

## 🧠 Key Variables

| Variable | Description | Example |
|-----------|--------------|----------|
| `cidr_block` | Main VPC CIDR block | `10.0.0.0/16` |
| `public_subnet_cidrs` | CIDRs for public subnets | `["10.0.1.0/24", "10.0.4.0/24"]` |
| `private_subnet_cidrs` | CIDRs for private subnets | `["10.0.2.0/24", "10.0.5.0/24"]` |
| `database_subnet_cidrs` | CIDRs for DB subnets | `["10.0.3.0/24", "10.0.6.0/24"]` |
| `is_peering_required` | Boolean flag for enabling VPC peering | `true` |

---

## 🔒 Best Practices

- Use separate route tables for each subnet type.
- Avoid public access to private/database subnets.
- Enable flow logs for traffic monitoring.
- Use Terraform workspaces to manage multiple environments (dev, stage, prod).
- Maintain consistent CIDR ranges to prevent overlap during peering.

---

## 🧾 Outputs

| Output | Description |
|---------|--------------|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | IDs of public subnets |
| `private_subnet_ids` | IDs of private subnets |
| `database_subnet_ids` | IDs of database subnets |
| `igw_id` | ID of the Internet Gateway |

---

## ✅ Example Usage

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}
```

---

