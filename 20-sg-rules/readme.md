# 🛡️ Roboshop Security Group Rules (Terraform)

This module defines **Security Group ingress rules** for the Roboshop application in AWS.  
It manages secure communication between infrastructure components such as the **Bastion host**, **Application Load Balancer (ALB)**, **Catalogue service**, and **Database layer**.

---

## 🗂️ Overview

The purpose of these rules is to:

- 🔒 Restrict SSH access only through the **Bastion host**
- 🌐 Allow internal communication between **application services**
- 🚫 Block any unnecessary public access
- 🧠 Ensure least privilege for all connections

---

## ⚙️ Security Group Rules Breakdown

### 1️⃣ Backend ALB ← Bastion
```hcl
resource "aws_security_group_rule" "backend_alb_bastion" { ... }
```
- **Source:** Bastion SG  
- **Destination:** Backend ALB SG  
- **Port:** 80 (HTTP)  
✅ Allows Bastion to test or monitor the ALB internally.

---

### 2️⃣ Bastion ← Laptop (Admin Access)
```hcl
resource "aws_security_group_rule" "bastion_laptop" { ... }
```
- **Source:** `0.0.0.0/0` (all IPs)  
- **Destination:** Bastion SG  
- **Port:** 22 (SSH)  
✅ Allows administrators to SSH into the Bastion host.

⚠️ **Important:** In production, replace `0.0.0.0/0` with your **public IP** for security.

---

### 3️⃣ Database Servers ← Bastion
```hcl
resource "aws_security_group_rule" "mongodb_bastion" { ... }
resource "aws_security_group_rule" "redis_bastion" { ... }
resource "aws_security_group_rule" "rabbitmq_bastion" { ... }
resource "aws_security_group_rule" "mysql_bastion" { ... }
```
- **Source:** Bastion SG  
- **Destination:** Each DB SG  
- **Port:** 22 (SSH)  
✅ Enables secure SSH access from Bastion to database servers.  
❌ Prevents direct SSH from the internet.

---

### 4️⃣ Catalogue ← Bastion
```hcl
resource "aws_security_group_rule" "catalogue_bastion" { ... }
```
- **Source:** Bastion SG  
- **Destination:** Catalogue SG  
- **Port:** 22 (SSH)  
✅ Allows developers to connect from Bastion to the Catalogue instance.

---

### 5️⃣ MongoDB ← Catalogue
```hcl
resource "aws_security_group_rule" "mongodb_catalogue" { ... }
```
- **Source:** Catalogue SG  
- **Destination:** MongoDB SG  
- **Port:** 27017 (MongoDB Default)  
✅ Enables Catalogue microservice to communicate with MongoDB for data storage.

---

### 6️⃣ Catalogue ← Backend ALB
```hcl
resource "aws_security_group_rule" "catalogue_backend_alb" { ... }
```
- **Source:** Backend ALB SG  
- **Destination:** Catalogue SG  
- **Port:** 8080 (HTTP)  
✅ ALB forwards user requests to the Catalogue backend service.

---

## 🧱 Security Flow Summary

| Rule Name | Source | Destination | Port | Purpose |
|------------|---------|--------------|-------|----------|
| backend_alb_bastion | Bastion | Backend ALB | 80 | Allow internal ALB access |
| bastion_laptop | Laptop | Bastion | 22 | SSH access for admin |
| mongodb_bastion | Bastion | MongoDB | 22 | SSH to DB via Bastion |
| redis_bastion | Bastion | Redis | 22 | SSH to DB via Bastion |
| rabbitmq_bastion | Bastion | RabbitMQ | 22 | SSH to DB via Bastion |
| mysql_bastion | Bastion | MySQL | 22 | SSH to DB via Bastion |
| catalogue_bastion | Bastion | Catalogue | 22 | SSH to app via Bastion |
| mongodb_catalogue | Catalogue | MongoDB | 27017 | App DB access |
| catalogue_backend_alb | Backend ALB | Catalogue | 8080 | App traffic from ALB |

---

## 🧠 Network Flow Diagram

```
Laptop (Admin)
   ↓ (SSH 22)
Bastion Host
   ↓ (SSH 22)
 ┌────────────────────────────────┐
 │        Private Subnet          │
 │                                │
 │  [MongoDB] ← [Catalogue] ← [Backend ALB]
 │      ↑             ↑
 │    (22,27017)     (8080)
 └────────────────────────────────┘
```

---

## 🔑 Best Practices & Important Notes

- ⚠️ **Do not use `0.0.0.0/0` in production** for SSH — restrict it to your IP.
- ✅ Use **bastion host** as the single SSH entry point for all private servers.
- 🧱 Keep database servers in **private subnets** with no public IP.
- 🔄 Regularly **rotate passwords and keys** used for SSH.
- 🧩 Keep security group rules modular (per service) for better maintenance.
- 🕵️‍♂️ Enable **VPC Flow Logs** and **CloudTrail** for auditing connections.

---

## 📜 File Summary

| File | Description |
|------|--------------|
| `security-groups.tf` | Defines all ingress rules for Bastion, ALB, DBs, and app servers |
| `locals.tf` | Stores Security Group IDs used as variables |
| `variables.tf` | Holds environment and region settings |
| `README.md` | Explains network rules, flow, and best practices |

---

