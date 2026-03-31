
# ⚙️ Roboshop Backend ALB (Terraform)

This Terraform configuration creates and manages the **Backend Application Load Balancer (ALB)** for the **Roboshop microservices architecture** in AWS.  
The Backend ALB routes internal HTTP traffic between backend microservices like **Catalogue**, **User**, **Cart**, etc.

---

## 🗂️ Overview

The Backend ALB is a **private** Application Load Balancer used for:
- Distributing traffic among backend microservices.
- Handling health checks.
- Providing a stable internal endpoint for services to communicate.
- Supporting Route53 DNS-based service discovery.

---

## 🧩 Components Explained

### 1️⃣ **Application Load Balancer**
```hcl
resource "aws_lb" "backend_alb" {
  name               = "${local.common_name_suffix}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.backend_alb_sg_id]
  subnets            = local.private_subnet_ids
}
```
- **Type:** Application Load Balancer (Layer 7)
- **Internal:** True → accessible only within the VPC (not public)
- **Security Group:** `backend_alb_sg_id`
- **Subnets:** Private subnets from `locals.tf`
- **Deletion Protection:** Disabled for testing/dev environments
- **Tags:** Uses environment-based tagging for identification

✅ **Purpose:**  
Balances traffic between backend services (like `catalogue`, `user`, `cart`, etc.) while remaining private to the network.

---

### 2️⃣ **Listener (Port 80)**
```hcl
resource "aws_lb_listener" "backend_alb" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"
}
```
- ALB listens for **HTTP (port 80)** requests.
- The **default action** is a fixed text response — useful as a health check or fallback.

✅ **Purpose:**  
Ensures that the ALB is active and reachable, even if no listener rules are configured yet.

---

### 3️⃣ **Route53 DNS Record**
```hcl
resource "aws_route53_record" "backend_alb" {
  zone_id = var.zone_id
  name    = "*.backend-alb-${var.environment}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.backend_alb.dns_name
    zone_id                = aws_lb.backend_alb.zone_id
    evaluate_target_health = true
  }
}
```
- Creates a **wildcard DNS record** in Route53:
  ```
  *.backend-alb-dev.venkatesh.fun
  ```
- This means:
  - `catalogue.backend-alb-dev.venkatesh.fun`
  - `user.backend-alb-dev.venkatesh.fun`
  - `cart.backend-alb-dev.venkatesh.fun`  
    all point to this backend ALB.
- Uses **Alias Record** → automatically resolves to the ALB DNS without hardcoding IPs.

✅ **Purpose:**  
Provides consistent internal domain-based routing for all backend services.

---

## 🧠 Network Flow Diagram

```
                 ┌───────────────────────────┐
                 │  Backend Application LB   │
                 │ (Internal, Port 80, HTTP) │
                 └──────────┬────────────────┘
                            │
          ┌────────────────────────────────────────┐
          │              Private Subnet             │
          │                                          │
          │   ┌──────────────┬──────────────┬────┐   │
          │   │ Catalogue    │ User Service │ Cart│   │
          │   │ (8080)       │ (8080)       │ ...│   │
          │   └──────────────┴──────────────┴────┘   │
          └──────────────────────────────────────────┘
```

---

## 🔑 Important Points & Best Practices

1. **Internal ALB** — Accessible only within the VPC (not public internet).  
2. **Private Subnets** — Ensures isolation of backend communication.  
3. **Security Group Rules**  
   - Allow inbound traffic from **Bastion host** (for debugging).  
   - Allow communication with backend services like `catalogue`.  
4. **Route53 Wildcard Record** — Enables service-specific subdomains under one ALB.  
5. **Health Checks** — Configured at the target group level (e.g., `/health` endpoint).  
6. **Scalability** — Integrates with **Auto Scaling Groups** for dynamic capacity management.  
7. **Tagging** — Consistent tagging across resources helps cost tracking and management.  
8. **Logging (Optional)** — Can enable ALB access logs in S3 for request monitoring.  

---

## 🧾 File Summary

| File | Description |
|------|--------------|
| `alb-backend.tf` | Contains all Backend ALB Terraform resources |
| `variables.tf` | Holds environment, domain, and Route53 variables |
| `locals.tf` | Contains reusable IDs for security groups and subnets |
| `README.md` | Documentation for understanding ALB setup and flow |

---

## 🚀 Deployment Steps

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

---

## 🧹 Destroy Resources

```bash
terraform destroy -auto-approve
```

---

## 🧩 Example Output

After deployment, Terraform will output:
```bash
backend_alb_dns_name = "internal-roboshop-dev-backend-alb-123456789.ap-south-1.elb.amazonaws.com"
backend_alb_url = "catalogue.backend-alb-dev.venkatesh.fun"
```

---


