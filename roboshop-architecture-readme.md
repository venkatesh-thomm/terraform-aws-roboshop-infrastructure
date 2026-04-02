# RoboShop Dev Environment - Architecture & Setup

## Overview

This document describes the architecture and request flow for:

👉 https://roboshop-dev.venkatesh.fun

------------------------------------------------------------------------

## Architecture Components

### 1. Route53 (DNS)

-   Domain: `roboshop-dev.venkatesh.fun`
-   Points to: **Frontend ALB (FALB)**

------------------------------------------------------------------------

### 2. Frontend ALB (FALB)

-   Listener: **HTTPS (443)**
-   Rule:
    -   `roboshop-dev.venkatesh.fun` → **Frontend Target Group**

#### Health Check

-   Configured on Frontend service

------------------------------------------------------------------------

### 3. Frontend Service (NGINX)

-   Handles UI requests
-   API requests are proxied to backend services

Example API:

    https://roboshop-dev.venkatesh.fun/api/catalogue/categories

#### NGINX Configuration Behavior

-   Routes `/api/catalogue/*` → Backend ALB

-   Backend Endpoint:

        catalogue.backend-alb-dev.venkatesh.fun

------------------------------------------------------------------------

### 4. Backend DNS (Route53)

-   Record:

        *.backend-alb-dev.venkatesh.fun

-   Points to: **Backend ALB**

------------------------------------------------------------------------

### 5. Backend ALB

-   Listener: **HTTP (80)**

#### Routing Rules

-   `catalogue.*` → **Catalogue Target Group**

#### Health Check

-   Configured on Catalogue service

------------------------------------------------------------------------

### 6. Catalogue Service

-   Handles catalogue-related APIs
-   Connects to **MongoDB**

------------------------------------------------------------------------

### 7. Database Layer

-   MongoDB
-   Used by Catalogue service for data retrieval

------------------------------------------------------------------------

## End-to-End Request Flow

1.  User hits:

        https://roboshop-dev.venkatesh.fun

2.  Route53 resolves → Frontend ALB

3.  Frontend ALB routes → Frontend (NGINX)

4.  NGINX forwards API request:

        /api/catalogue/categories

    to:

        catalogue.backend-alb-dev.venkatesh.fun

5.  Route53 resolves backend domain → Backend ALB

6.  Backend ALB routes request:

        catalogue.*

    → Catalogue Target Group

7.  Catalogue service processes request

8.  Catalogue queries MongoDB

9.  Response flows back:

        MongoDB → Catalogue → Backend ALB → NGINX → Frontend ALB → User

------------------------------------------------------------------------

## Key Highlights ✔️

-   Secure frontend using HTTPS (443)
-   Internal service routing via backend ALB
-   Wildcard DNS for backend services
-   Microservice-based routing via ALB rules
-   Decoupled frontend and backend layers

------------------------------------------------------------------------

## Diagram (Logical Flow)

    User
      |
      v
    Route53
      |
      v
    Frontend ALB (HTTPS 443)
      |
      v
    Frontend (NGINX)
      |
      v
    Backend ALB (HTTP 80)
      |
      v
    Catalogue Service
      |
      v
    MongoDB

------------------------------------------------------------------------

## Notes 💡

-   Ensure health checks are properly configured for all target groups
-   Validate SSL certificates on Frontend ALB
-   Confirm DNS propagation for both domains
-   Monitor ALB logs for debugging

# Flow:

  for i in 00-vpc/ 10-sg/20-sg-rules/ 30-bastion/40-databases/50-backend-alb/65-acm/70-frontend-alb/80-components; do cd $i; terraform apply -auto-approve; cd .. ;done
  80-components optional

-----------------------------------------------------------