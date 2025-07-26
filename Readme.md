# 🚀 Strapi Deployment on AWS ECS using Terraform & GitHub Actions

This project automates the deployment of a Dockerized Strapi CMS backend to AWS ECS Fargate. It uses:

- **Terraform** for Infrastructure as Code (IaC)
- **GitHub Actions** for CI/CD pipeline
- **AWS ECR** for container registry
- **AWS ECS (Fargate)** for container orchestration
- **PostgreSQL** as the backend database

---

## 📁 Project Structure

```
.
├── .github
│   └── workflows
│       ├── dockerize.yml       # Builds & pushes Docker image to ECR
│       ├── deploy.yml          # Terraform init, plan & apply
│       └── destroy.yml         # Terraform destroy
├── strapiecs-gha               # Strapi source code
├── terraform                   # Terraform configs (ECS, RDS, etc.)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── README.md
```

---

## ✅ Features

- Infrastructure provisioned using Terraform Cloud
- GitHub Actions pipeline for Docker image build, push, deploy & destroy
- ECS Fargate deployment using `latest` tag from ECR
- PostgreSQL database via RDS
- Remote Terraform backend configuration (Terraform Cloud)

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/strapi-ecs-pipeline.git
cd strapi-ecs-pipeline
```

### 2. Configure Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**, and add the following secrets:

| Name                   | Description                      |
|------------------------|----------------------------------|
| `AWS_ACCESS_KEY_ID`    | AWS access key                   |
| `AWS_SECRET_ACCESS_KEY`| AWS secret access key            |
| `TF_API_TOKEN`         | Terraform Cloud API token        |
| `DB_USERNAME`          | PostgreSQL DB username           |
| `DB_PASSWORD`          | PostgreSQL DB password           |
| `DB_NAME`              | PostgreSQL DB name               |

### 3. Setup Terraform Cloud Workspace

- Go to [Terraform Cloud](https://app.terraform.io)
- Create a new workspace (e.g., `strapi-ecs`)
- Connect it to your GitHub repository or leave it CLI-driven
- Under **Variables**, add these as **Terraform variables** (not environment variables):

| Key             | Value                     |
|------------------|---------------------------|
| `aws_access_key` | same as AWS secret key ID |
| `aws_secret_key` | same as AWS secret        |

> ✅ **Do NOT enable HCL** — leave it unchecked.

---

## 🚀 GitHub Actions Workflows

| Workflow         | Trigger           | Description                            |
|------------------|-------------------|----------------------------------------|
| `dockerize.yml`  | On push to `main` | Builds Docker image and pushes to ECR  |
| `deploy.yml`     | Manual dispatch   | Initializes and applies Terraform code |
| `destroy.yml`    | Manual dispatch   | Tears down infrastructure              |

---

## 🧹 Destroy Infrastructure

To destroy the deployed infrastructure:

1. Go to **Actions** tab in your GitHub repository
2. Select the **"Destroy Strapi Infra"** workflow
3. Click **"Run workflow"**

---

## 👨‍💻 Author

**Sourav Ranjan Sahoo**  

---

## 📄 License

This project is licensed under the **MIT License**.