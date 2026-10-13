# CI-CD-project-1
## 🏗️ Architectural Highlights & Security Design

Hiring managers can review the technical breakdown of the infrastructure footprint below:

```text
       [ GitHub Actions CI/CD ]
                  │
                  ▼ (Push Docker Image & Scan)
         [ Amazon ECR ]
                  │
                  ▼ (Pull Image)
 ┌───────────────── AWS Fargate (ECS) ─────────────────┐
 │                                                     │
 │  ┌───────────────────────────────────────────────┐  │
 │  │             ECS Task Execution Role           │  │
 │  │  - Pulls image from ECR                       │  │
 │  │  - Ships container logs to CloudWatch         │  │
 │  └───────────────────────────────────────────────┘  │
 │                                                     │
 │  ┌───────────────────────────────────────────────┐  │
 │  │                 ECS Task Role                 │  │
 │  │  - App code runtime permissions               │  │
 │  │  - Least-Privilege access to DynamoDB tables  │  │
 │  └───────────────────────┬───────────────────────┘  │
 └──────────────────────────┼──────────────────────────┘
                            │
                            ▼ (CRUD Operations Only)
                     [ Amazon DynamoDB ]
```

### 🔐 Strict Isolation via Decoupled IAM Roles
Rather than utilizing a single generic identity for the application runtime, the infrastructure strictly decouples operational permissions into two distinct AWS IAM roles:
*   **ECS Task Execution Role:** Used exclusively by the AWS ECS container agent. It limits permissions strictly to infrastructure bootstrap requirements, such as downloading container images from **Amazon ECR** and creating network interfaces.
*   **ECS Task Role (The Application Layer):** Used exclusively by the running application code inside the container. It implements the **Principle of Least Privilege** by stripping away infrastructure access and granting fine-grained, secure access (`GetItem`, `PutItem`, `UpdateItem`, `DeleteItem`) restricted solely to the target DynamoDB ARN.

### 🛡️ Container Vulnerability Guardrails
To prevent supply chain attacks and vulnerable dependencies from reaching production, the **Amazon ECR** registry is provisioned with automated `scan_on_push` capabilities. Every new container build is systematically parsed for CVEs before deployment orchestration can begin.

### 💾 Concurrency-Safe State Management
To support distributed engineering teams, the infrastructure includes a highly available remote state configuration:
*   **Amazon S3:** Serves as a single source of truth for the encryption-at-rest Terraform state (`.tfstate`) file.
*   **DynamoDB State Locking:** Uses a dedicated distributed locking table to gracefully block overlapping execution threads, eliminating the risk of concurrent state corruption.
