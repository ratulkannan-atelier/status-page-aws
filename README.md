# Status Page - Uptime Monitor

A full-stack uptime monitoring application deployed on AWS using Terraform infrastructure-as-code. Add websites to monitor, and the app automatically checks their availability at configurable intervals, displaying real-time status and 24-hour uptime history.

## Architecture

![AWS Architecture](AWS_Architecture_Status.png)

### Design Decisions

- **awsvpc network mode:** Each ECS task gets its own ENI for better security isolation. Containers within a task communicate via localhost.
- **NAT Gateway:** Required for ECS tasks in private subnets to make outbound HTTP requests (uptime checks) to the internet.
- **EC2 launch type over Fargate:** Demonstrates deeper understanding of ECS infrastructure (capacity providers, auto scaling groups, launch templates).
- **Separate nginx configs:** `nginx.conf` for local Docker Compose (uses Docker DNS) and `nginx.ecs.conf` for ECS (uses localhost since containers share a network namespace).
- **SSL connection to RDS:** PostgreSQL 15 requires encrypted connections. `sslmode=no-verify` enables encryption while trusting the AWS-managed certificate within the VPC.

### Security Groups

| Resource | Inbound Rule |
|----------|-------------|
| ALB | Port 80 from internet |
| ECS | All ports from ALB security group only |
| RDS | Port 5432 from ECS security group only |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React (Vite) served by Nginx |
| Backend | Node.js / Express REST API |
| Database | PostgreSQL |
| Containerization | Docker, Docker Compose (local dev) |
| Networking | VPC, Public/Private Subnets, Internet Gateway, NAT Gateway |
| Compute | ECS on EC2 with Capacity Providers, Auto Scaling Group |
| Load Balancing | Application Load Balancer with health checks |
| Database (AWS) | RDS PostgreSQL (private subnet) |
| Container Registry | ECR with lifecycle policies |
| Monitoring | CloudWatch Logs |
| Security | Security Groups (ALB → ECS → RDS), IAM Roles |
| IaC | Terraform (10 config files, 35+ resources) |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/ping` | Health check for ALB |
| `GET` | `/monitors` | List all monitors with latest status |
| `POST` | `/monitors` | Add a new monitor (name, url, interval) |
| `DELETE` | `/monitors/:id` | Remove a monitor |
| `GET` | `/checks/:monitorId` | Get check history and 24h uptime percentage |

## Project Structure

```
.
├── api-node/                          # Backend API
│   ├── Dockerfile
│   └── src/
│       ├── index.js                   # Express server
│       ├── db.js                      # PostgreSQL connection
│       ├── scheduler.js               # Uptime check scheduler
│       └── routes/
│           ├── monitors.js            # CRUD for monitors
│           └── checks.js              # Health check results
├── client-react/                      # Frontend
│   ├── Dockerfile
│   ├── nginx.conf                     # Nginx config (local)
│   ├── nginx.ecs.conf                 # Nginx config (ECS)
│   └── src/
│       ├── App.jsx                    # Main app
│       └── components/
│           ├── AddMonitorForm.jsx     # Add monitor form
│           ├── MonitorCard.jsx        # Monitor status card
│           └── MonitorDetail.jsx      # Uptime history view
├── resume_project_terraform/          # Infrastructure as Code
│   ├── main.tf                        # Provider config
│   ├── variables.tf                   # Input variables
│   ├── vpc.tf                         # VPC, subnets, IGW, NAT GW
│   ├── sg.tf                          # Security groups
│   ├── alb.tf                         # Load balancer
│   ├── rds.tf                         # PostgreSQL database
│   ├── ecr.tf                         # Container registries
│   ├── ecs.tf                         # ECS cluster, task, service
│   ├── cloudwatch.tf                  # Log groups
│   ├── ecs_userdata.sh                # EC2 bootstrap script
│   └── outputs.tf                     # Output values
├── docker-compose.yml                 # Production local setup
└── docker-compose.dev.yml             # Development with hot reload
```

## Local Development

**Prerequisites:** Docker and Docker Compose

```bash
# Development mode (hot reload)
docker compose -f docker-compose.dev.yml up --build

# Production mode
docker compose up --build
```

The app will be available at `http://localhost:8080`

## AWS Deployment

**Prerequisites:** AWS CLI, Terraform, Docker

### 1. Deploy Infrastructure

```bash
cd resume_project_terraform
terraform init
terraform apply -var="db_password=YourSecurePassword"
```

### 2. Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push api-node
docker build -t <ecr-api-url>:latest ./api-node
docker push <ecr-api-url>:latest

# Swap nginx config for ECS, build and push client-react
cd client-react
cp nginx.conf nginx.conf.backup
cp nginx.ecs.conf nginx.conf
docker build -t <ecr-client-url>:latest .
docker push <ecr-client-url>:latest
cp nginx.conf.backup nginx.conf
```

### 3. Force New Deployment

```bash
aws ecs update-service --cluster status_page-cluster --service status_ecs-service --force-new-deployment --region us-east-1
```

### 4. Tear Down

```bash
terraform destroy -var="db_password=YourSecurePassword"
```
