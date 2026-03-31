
# 📦 Roboshop Catalogue Service (Terraform)

This Terraform configuration deploys the **Catalogue microservice** of the Roboshop project.  
It includes provisioning of EC2 instances, AMIs, Launch Templates, Auto Scaling Groups, Target Groups, and Load Balancer Listener Rules.

---

## 🏗️ Architecture Overview

```
+--------------------+
|  Backend ALB       |
|  (Internal)        |
|  Port: 80          |
+---------+----------+
          |
          v
+--------------------+
| Target Group       |
| Port: 8080         |
+---------+----------+
          |
          v
+--------------------+
| Auto Scaling Group |
| Launch Template    |
| AMI (Catalogue)    |
| Instance Type: t3.micro |
+--------------------+
```


# Overall Workflow (Simple Visual)
```bash

        Build Phase                               Runtime Phase
---------------------------------------------------------------
EC2 (temp)  --→  Install App  --→  Stop ----→  Create AMI
                                               
                                               ↓
                                          Launch Template
                                               
                                               ↓
                                        AutoScaling Group
                                               
                                               ↓
                           Load Balancer ←→ Multiple Instances
                                               ↑
                                               
                                     AutoScaling Policy (CPU)

```
---


## 🧩 Components

### 1. EC2 Instance
Creates a base EC2 instance used to install the Catalogue application before creating an AMI.

```hcl
resource "aws_instance" "catalogue" {
  ami = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]
  subnet_id = local.private_subnet_id
}
```


### 2.Step 2: Install the Application on the Instance using  `terraform_data` Provisioner
Used to copy and execute the `catalogue.sh` script remotely for app setup.

```hcl
provisioner "file" {
  source      = "catalogue.sh"
  destination = "/tmp/catalogue.sh"
}

provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/catalogue.sh",
    "sudo sh /tmp/catalogue.sh catalogue ${var.environment}"
  ]
}
```
 
### Why `terraform_data` is needed here:

- Terraform **cannot** run scripts by itself.
- Provisioners (`file`, `remote-exec`) **must be attached to a resource**.
- We **do not** attach provisioners to `aws_instance` because the instance may not be ready for SSH immediately.
- Provisioners will not re-run if instance changes.

So we attach them to **terraform_data**, which acts as a **wrapper**.

Example logic:

```hcl
resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.catalogue.private_ip
  }

  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment}"
    ]
  }
}
```

### Key Point

> `triggers_replace` ensures the script runs **whenever the instance changes**.

```bash 
| What happens                                | When it happens                 |
| ------------------------------------------- | ------------------------------- |
| Copy script & install app                   | Only after EC2 is ready         |
| Re-run installation if instance is replaced | Yes (based on triggers_replace) |
```

# What happens here:

  - Copy catalogue.sh to /tmp/ on server.

  - Execute script to install Catalogue application.

  - After installation, the app is now baked into the server.

This is the customization phase.

> 💡 **Note:** Even though you are running Terraform locally, the provisioner runs commands *remotely* on the created EC2 instance via SSH.

# Step 3: Stop the Instance
The instance is stopped and an AMI is created for future scaling.

```hcl
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = aws_instance.catalogue.id
  state       = "stopped"
}

```
```
bash
We stop the EC2 instance because:

  You cannot create a proper AMI from a running instance during provisioning.

  Stopped instance → consistent filesystem → ideal for AMI.

```
# Step 4: Create the AMI 
```hcl
resource "aws_ami_from_instance" "catalogue" {
  name               = "${local.common_name_suffix}-catalogue-ami"
  source_instance_id = aws_instance.catalogue.id
}
```

This creates an AMI that already contains the installed Catalogue application.

**Why AMI?**

 **Because:**

  1. When scaling servers, we want them to already have the app installed.

  2. No scripts → No configuration delay → Faster scaling → Reliable deployments.

  3. This is called Immutable Infrastructure


### Step 5: Create Launch Template
Defines how future EC2 instances (in ASG) are launched.

```hcl
resource "aws_launch_template" "catalogue" {
  name = "${local.common_name_suffix}-catalogue"
  image_id = aws_ami_from_instance.catalogue.id
  instance_type = "t3.micro"
}
```

**This defines:**

 1. Which AMI to use 
  
 2. Instance type

 3. Security groups

 4. Tags

**Think of launch template as "Server Blueprint" for Auto Scaling.**

### Step 6: Create Auto Scaling Group (ASG)

Automatically manages EC2 instances for high availability and load balancing.

```hcl
resource "aws_autoscaling_group" "catalogue" {
  desired_capacity = 1
  max_size = 10
  min_size = 1
  launch_template {
    id = aws_launch_template.catalogue.id
    version = aws_launch_template.catalogue.latest_version
  }
}

instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 # atleast 50% of the instances should be up and running
    }
    triggers = ["launch_template"]
  }

```

**ASG ensures:**

 1. Minimum 1 instance always running

 2. Can scale up to 10 when load increases

 3. Instances are launched using the AMI

 4. Instances are registered with the Load Balancer target group

 5. So, if a server crashes → ASG replaces it automatically.



### Step 7: Apply Auto Scaling Policy
```hcl
resource "aws_autoscaling_policy" "catalogue" { ... }
```
```bash
| Metric          | Action                  |
| --------------- | ----------------------- |
| CPU > 75%       | Add new server(s)       |
| CPU < threshold | Remove unused server(s) |

This ensures performance + cost optimization.
```



### Step 8: Route Traffic Through Load Balancer and Target Group and Listener Rule
The ALB forwards requests to the target group.

```hcl
resource "aws_lb_target_group" "catalogue" {
  port = 8080
  protocol = "HTTP"
  health_check {
    path = "/health"
  }
}
```

```hcl
resource "aws_lb_listener_rule" "catalogue" {
  priority = 10
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }
  condition {
    host_header {
      values = ["catalogue.backend-alb-${var.environment}.${var.domain_name}"]
    }
  }
}
```
### ✅ Step 9 — Terminate Temporary Server
```hcl
resource "terraform_data" "catalogue_local" { ... }

terraform_data.catalogue_local
```

``` bash
| Condition                            | Action                          |
| ------------------------------------ | ------------------------------- |
| Auto-scaling infrastructure is ready | **Terminate the temporary EC2** |
```
**So that only ASG instances remain running.

Final environment is:
✅ Load Balancer
✅ Auto Scaling Group
✅ Instances from AMI
**
---

## 🔒 Security Considerations

- Security Groups allow traffic from **Backend ALB** on port `8080`.
- SSH access should be limited to the **Bastion Host**.
- Always use **private subnets** for application EC2 instances.
- Avoid using hardcoded passwords; prefer AWS SSM Parameter Store or Secrets Manager.

---

## 🧠 Key Learnings

- `terraform_data` can be used for **remote provisioning** without creating new resources.
- Creating AMIs programmatically ensures **consistency** across deployments.
- Using Launch Templates with ASG provides **scalability and reliability**.

---

## 🚀 Deployment Steps

1. Place your `catalogue.sh` script in the same directory.
2. Run the following commands:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

3. Verify the ALB target health in AWS Console.
4. Access the application using:

```
http://catalogue.backend-alb-<environment>.<domain>
```

---

## 🧩 Dependencies

- Backend ALB setup must exist.
- Security groups, subnets, and VPC are pre-created.
- Proper IAM roles should be attached for provisioning and AMI creation.

---

## ✅ Outputs

- EC2 instance private IP
- AMI ID for Catalogue service
- ASG name and target group ARN

---

## 🧱 Example Output

```bash
aws_ami_from_instance.catalogue.id = "ami-08ab12cd34ef56gh7"
aws_autoscaling_group.catalogue.name = "roboshop-dev-catalogue"
aws_lb_target_group.catalogue.arn = "arn:aws:elasticloadbalancing:..."
```
## 🧠 File Breakdown

| File | Description |
|------|--------------|
| **provider.tf** | Configures AWS provider and S3 backend for remote Terraform state |
| **variables.tf** | Defines project-level variables (project name, environment, domain) |
| **data.tf** | Fetches required infrastructure data (AMI, VPC, subnets, SGs, ALB listener ARN) from AWS SSM |
| **locals.tf** | Defines reusable local variables like name suffix, common tags, and IDs |
| **main.tf** | Main Terraform file that creates resources — EC2, AMI, Launch Template, ASG, ALB TG, scaling policies, and cleanup tasks |
| **catalogue.sh** | Bash script executed on EC2 to install Ansible, clone playbook repo, and run configuration for the Catalogue component |

---


# ✅ Phase 1: Launch Temporary EC2 → Install App → Convert to AMI


| Resource                           | What it does                                                                      |
| ---------------------------------- | --------------------------------------------------------------------------------- |
| `aws_instance.catalogue`           | Launches a temporary EC2 server.                                                  |
| `terraform_data.catalogue`         | SSH into that EC2 using **remote-exec** → Runs `catalogue.sh` to install the app. |
| `aws_ec2_instance_state.catalogue` | Stops the instance after installation.                                            |
| `aws_ami_from_instance.catalogue`  | Creates an **AMI** (image) from that instance.                                    |



**Flow:

 - Create EC2 instance.

 - Copy catalogue.sh script to it.

 - Run the script (this installs the catalogue service).

 - Stop the instance.

 - Create AMI of that customized instance.

This AMI now has your application pre-installed → this is how you ensure autoscaling works without manual deployment scripts.
**


# ✅ Phase 2: Create Launch Template + Auto Scaling + Load Balancer Setup


| Resource                           | Purpose                                                         |
| ---------------------------------- | --------------------------------------------------------------- |
| `aws_lb_target_group.catalogue`    | Target group for your backend load balancer.                    |
| `aws_launch_template.catalogue`    | Uses the **AMI** to launch identical catalogue instances later. |
| `aws_autoscaling_group.catalogue`  | Automatically scales number of EC2 instances.                   |
| `aws_autoscaling_policy.catalogue` | Scale up/down based on **CPU utilization**.                     |
| `aws_lb_listener_rule.catalogue`   | Routes requests coming to LB → to catalogue target group.       |


### What Happens Here

1. Launch Template uses the AMI to create future instances.
2. Auto Scaling Group creates & replaces instances automatically.
3. Load Balancer routes traffic to ASG instances.
4. Auto Scaling Policy keeps CPU at target % by adding/removing instances.

---



# ✅ Phase 3: Terminate the Temporary Build Instance

| Resource                         | What happens                                                     |
| -------------------------------- | ---------------------------------------------------------------- |
| `terraform_data.catalogue_local` | Terminates the temporary EC2 instance (used only for AMI build). |

```bash
This resource depends on the autoscaling policy to ensure:
Scaling infra is ready → THEN we delete the old instance.

So this command runs:
aws ec2 terminate-instances --instance-ids <catalogue-instance-id>
```

##  The Key Idea to Remember

| Component | Role |
|---------|------|
| **terraform_data** | Controls *when* provisioning happens |
| **remote-exec / file** | Perform the actual installation steps |
| **AMI + ASG** | Ensure scalable and repeatable deployments |

---

##  One-Line Summary

 **`terraform_data` decides when to apply configuration, and ASG ensures your application scales automatically using the AMI you built.**

---

## 🔥 Think of it like Cooking a Meal (Easy Analogy)

| Step | What Happens                                     | Analogy                                                 |
| ---- | ------------------------------------------------ | ------------------------------------------------------- |
| 1    | Start a temporary EC2 instance                   | You take raw ingredients out of the fridge              |
| 2    | Run `catalogue.sh` to install app & dependencies | You cook the food                                       |
| 3    | Stop the instance                                | Let the food cool                                       |
| 4    | Create AMI                                       | Pack and seal the food container                        |
| 5    | Launch Template uses that AMI                    | Set the packed meal as your *standard* recipe           |
| 6    | Auto Scaling Group deploys multiple instances    | Restaurant serves multiple plates from same packed meal |
| 7    | Attach to Load Balancer Target Group             | Customers get access to the meal via waiter (LB)        |
| 8    | Terminate the original EC2                       | Clean up kitchen — keep only the packaged meals         |
