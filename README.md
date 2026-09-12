````markdown
# Tech Challenge 2 — AWS Cloud / DevOps CI/CD Project

## Overview

This project deploys a containerized Flask web application to Amazon EKS using:

- AWS
- Terraform
- Docker
- Amazon ECR
- Amazon EKS
- Kubernetes
- Helm
- Jenkins
- GitHub
- AWS Load Balancer Controller
- Horizontal Pod Autoscaler
- Cluster Autoscaler

The application is a simple Flask web server that returns:

```text
Hello, World!
````

The project demonstrates:

* Infrastructure as Code
* AWS networking
* Containerization
* Container image management
* Kubernetes deployments
* Kubernetes services
* Kubernetes ingress
* Application Load Balancers
* Horizontal Pod Autoscaling
* Cluster Autoscaling
* Helm deployments
* Jenkins CI/CD
* GitHub webhooks
* AWS IAM
* EKS access management
* Troubleshooting and deployment validation

---

# Architecture

```text
                         GitHub
                           |
                           | Push
                           v
                    GitHub Webhook
                           |
                           v
                       Jenkins
                           |
             +-------------+-------------+
             |                           |
             v                           v
       Docker Build                  AWS ECR
             |                           |
             |                           |
             +-------------+-------------+
                           |
                           v
                         Helm
                           |
                           v
                    Amazon EKS Cluster
                           |
              +------------+------------+
              |                         |
              v                         v
        Kubernetes               Autoscaling
        Deployment              HPA / Cluster
              |                  Autoscaler
              v
        Kubernetes Service
              |
              v
       AWS Application
       Load Balancer
              |
              v
       Flask Application
         Hello, World!
```

---

# AWS Infrastructure

Terraform creates the AWS infrastructure.

## Region

```text
us-east-1
```

## VPC

VPC CIDR:

```text
10.0.0.0/16
```

## Subnets

### Public Subnet 1

```text
CIDR: 10.0.1.0/24
AZ:   us-east-1a
```

### Private Subnet 1

```text
CIDR: 10.0.2.0/24
AZ:   us-east-1a
```

### Public Subnet 2

```text
CIDR: 10.0.3.0/24
AZ:   us-east-1b
```

### Private Subnet 2

```text
CIDR: 10.0.4.0/24
AZ:   us-east-1b
```

---

# AWS Networking

The architecture uses:

* Internet Gateway for public subnet internet access
* NAT Gateway for private subnet outbound internet access
* Public route table
* Private route table
* Route table associations
* Elastic IP for the NAT Gateway

Traffic architecture:

```text
Internet
   |
   v
Internet Gateway
   |
   +--------------------+
   |                    |
Public Subnet A     Public Subnet B
   |
   +--> NAT Gateway
          |
          v
      Private Subnets
```

---

# Terraform

Terraform is used to provision the AWS infrastructure.

## Terraform Files

```text
terraform/
├── main.tf
├── eks.tf
├── nodes.tf
├── jenkins.tf
├── providers.tf
├── outputs.tf
├── terraform.tfstate
└── terraform.tfstate.backup
```

Terraform state files are intentionally excluded from Git using `.gitignore`.

---

# Initialize Terraform

From the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

This downloads the required AWS provider and initializes the Terraform working directory.

---

# Validate Terraform

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

# Review Infrastructure Changes

```bash
terraform plan
```

This compares the Terraform configuration with the infrastructure currently running in AWS.

A clean deployment should report:

```text
No changes.
Your infrastructure matches the configuration.
```

---

# Deploy Infrastructure

To create or update the AWS infrastructure:

```bash
terraform apply
```

Review the proposed changes and confirm with:

```text
yes
```

Terraform provisions:

* VPC
* Subnets
* Route tables
* Internet Gateway
* NAT Gateway
* Security groups
* EKS cluster
* EKS worker node group
* Jenkins EC2 instance
* IAM roles
* IAM policies
* EKS access configuration

---

# EKS Cluster

Cluster name:

```text
tech2-eks-cluster
```

Check the cluster:

```bash
aws eks describe-cluster \
  --region us-east-1 \
  --name tech2-eks-cluster \
  --query "cluster.status"
```

Expected result:

```text
"ACTIVE"
```

---

# Configure kubectl

Connect kubectl to EKS:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name tech2-eks-cluster
```

Verify the connection:

```bash
kubectl get nodes
```

Expected output will show the EKS worker nodes.

---

# EKS Worker Nodes

The worker node group uses:

```text
Instance type: t3.small
Minimum nodes: 1
Desired nodes: 1
Maximum nodes: 4
```

The node group starts with one node to reduce cost while allowing scaling to four nodes.

Check the nodes:

```bash
kubectl get nodes
```

Check additional node information:

```bash
kubectl get nodes -o wide
```

---

# Docker Application

The application is located in:

```text
app/
```

Application files:

```text
app/
├── app.py
└── requirements.txt
```

The Flask application listens on port:

```text
5000
```

---

# Run Flask Locally

Install dependencies:

```bash
pip install -r app/requirements.txt
```

Start the application:

```bash
python app/app.py
```

Test the application:

```bash
curl http://localhost:5000
```

Expected:

```text
Hello, World!
```

---

# Dockerfile

The Dockerfile:

1. Uses Python 3.12
2. Creates `/app`
3. Copies the Python requirements
4. Installs dependencies
5. Copies the Flask application
6. Exposes port 5000
7. Starts the Flask application

---

# Build Docker Image

From the project root:

```bash
docker build -t tech2-app .
```

Verify the image:

```bash
docker images
```

---

# Run Docker Container

```bash
docker run -d \
  -p 5000:5000 \
  --name tech2-container \
  tech2-app
```

Check the running container:

```bash
docker ps
```

Test the application:

```bash
curl http://localhost:5000
```

Expected:

```text
Hello, World!
```

Stop the container:

```bash
docker stop tech2-container
```

Remove the container:

```bash
docker rm tech2-container
```

---

# Amazon ECR

The Docker image is stored in Amazon Elastic Container Registry.

Repository:

```text
701559402152.dkr.ecr.us-east-1.amazonaws.com/tech2-app
```

---

# Authenticate Docker to ECR

```bash
aws ecr get-login-password \
  --region us-east-1 | \
  docker login \
  --username AWS \
  --password-stdin \
  701559402152.dkr.ecr.us-east-1.amazonaws.com/tech2-app
```

---

# Tag Docker Image

```bash
docker tag tech2-app:latest \
  701559402152.dkr.ecr.us-east-1.amazonaws.com/tech2-app:latest
```

---

# Push Image to ECR

```bash
docker push \
  701559402152.dkr.ecr.us-east-1.amazonaws.com/tech2-app:latest
```

Verify the repository:

```bash
aws ecr describe-repositories \
  --repository-names tech2-app \
  --region us-east-1
```

---

# Kubernetes

Kubernetes resources are located in:

```text
kubernetes/
```

The application uses:

* Deployment
* Service
* HPA
* Ingress

---

# Kubernetes Deployment

The Deployment runs the Flask application.

The container uses:

```text
Port: 5000
```

Resource requests:

```text
CPU:    100m
Memory: 128Mi
```

The resource requests are important because the HPA uses them to calculate utilization.

---

# Apply Kubernetes Deployment

```bash
kubectl apply -f kubernetes/deployment.yaml
```

Verify:

```bash
kubectl get deployment
```

Check Pods:

```bash
kubectl get pods
```

Detailed Pod information:

```bash
kubectl describe pod <pod-name>
```

---

# Kubernetes Service

The Service exposes the application internally inside the cluster.

Configuration:

```text
Service port: 80
Container port: 5000
Service type: ClusterIP
```

Traffic:

```text
ALB
 |
 v
Service:80
 |
 v
Pod:5000
```

Apply the Service:

```bash
kubectl apply -f kubernetes/service.yaml
```

Check the Service:

```bash
kubectl get service
```

---

# Horizontal Pod Autoscaler

The HPA automatically increases or decreases the number of application Pods based on resource utilization.

Configuration:

```text
Minimum replicas: 1
Maximum replicas: 12
CPU target:       50%
Memory target:    50%
```

Apply the HPA:

```bash
kubectl apply -f kubernetes/hpa.yaml
```

Check the HPA:

```bash
kubectl get hpa
```

Example:

```text
NAME            REFERENCE              TARGETS
tech2-app-hpa   Deployment/tech2-app   cpu: 1%/50%, memory: 16%/50%
```

---

# Why Maximum 12 Pods?

The assignment requires up to three Pods per node.

The EKS node group supports up to four nodes.

Therefore:

```text
4 nodes × 3 Pods per node = 12 Pods
```

The HPA maximum is therefore:

```text
12 Pods
```

HPA controls **Pods**.

Cluster Autoscaler controls **nodes**.

These are separate components.

---

# Metrics Server

The Kubernetes Metrics Server provides CPU and memory metrics to the HPA.

Install:

```bash
kubectl apply \
  -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Check the Metrics Server:

```bash
kubectl get deployment metrics-server -n kube-system
```

Check Pod metrics:

```bash
kubectl top pods
```

Check node metrics:

```bash
kubectl top nodes
```

---

# Cluster Autoscaler

Cluster Autoscaler adjusts the number of EKS worker nodes when additional capacity is required.

Node group:

```text
Minimum: 1
Maximum: 4
```

The autoscaler uses AWS Auto Scaling Group tags to discover the EKS node group.

Check the autoscaler:

```bash
kubectl get pods -n kube-system
```

---

# AWS Load Balancer Controller

The AWS Load Balancer Controller manages AWS Application Load Balancers for Kubernetes Ingress resources.

Check the controller:

```bash
kubectl get pods -n kube-system
```

The controller should show two healthy Pods:

```text
1/1 Running
1/1 Running
```

---

# Kubernetes Ingress

The Ingress creates an internet-facing AWS Application Load Balancer.

Configuration:

```text
Scheme: internet-facing
Target type: IP
```

Apply the Ingress:

```bash
kubectl apply -f kubernetes/ingress.yaml
```

Check the Ingress:

```bash
kubectl get ingress
```

The ADDRESS field contains the public ALB DNS name.

---

# Test the Public Application

Retrieve the ALB address:

```bash
kubectl get ingress tech2-app-ingress
```

Test the application:

```bash
curl http://<ALB-DNS-NAME>
```

Expected:

```text
Hello, World!
```

---

# Helm

The Kubernetes application is packaged as a Helm chart.

Chart structure:

```text
helm/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml
    └── ingress.yaml
```

Helm manages:

* Deployment
* Service
* HPA
* Ingress

---

# Helm Values

Important Helm configuration:

```yaml
replicaCount: 1

service:
  type: ClusterIP
  port: 80
  targetPort: 5000

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"

autoscaling:
  minReplicas: 1
  maxReplicas: 12
  cpuUtilization: 50
  memoryUtilization: 50
```

---

# Install Helm Release

```bash
helm upgrade --install tech2-app ./helm
```

Check Helm releases:

```bash
helm list -A
```

Check the application release:

```bash
helm status tech2-app
```

---

# Jenkins

Jenkins runs on an EC2 instance inside the AWS VPC.

Jenkins is responsible for:

1. Checking out the GitHub repository
2. Building the Docker image
3. Pushing the image to ECR
4. Connecting to EKS
5. Deploying with Helm

---

# Jenkins Pipeline

The pipeline is defined in:

```text
Jenkinsfile
```

Pipeline stages:

```text
Build Docker Image
        |
        v
Push to ECR
        |
        v
Deploy to EKS
```

---

# Jenkins Build Stage

Jenkins builds the image:

```bash
docker build -t tech2-app .
```

---

# Jenkins ECR Stage

Jenkins authenticates to ECR:

```bash
aws ecr get-login-password --region us-east-1 |
docker login --username AWS --password-stdin $ECR_REPO
```

The image is tagged:

```bash
docker tag tech2-app:latest $ECR_REPO:latest
```

Then pushed:

```bash
docker push $ECR_REPO:latest
```

---

# Jenkins EKS Deployment Stage

Jenkins updates its Kubernetes configuration:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name tech2-eks-cluster
```

Jenkins then deploys the application:

```bash
helm upgrade --install tech2-app ./helm
```

---

# GitHub Webhook

GitHub is configured to notify Jenkins when code is pushed.

Flow:

```text
Git push
   |
   v
GitHub
   |
   | Webhook
   v
Jenkins
   |
   v
Pipeline starts automatically
```

This allows a code change to automatically trigger the CI/CD pipeline.

---

# Jenkins AWS Authentication

Jenkins uses an IAM role attached to the EC2 instance.

The EC2 instance does not need hard-coded AWS access keys.

The IAM configuration provides Jenkins with access to:

* Amazon ECR
* Amazon EKS

The Jenkins IAM role is also configured as an EKS access entry.

---

# Git

The project uses Git for source control.

Initialize a repository:

```bash
git init
```

Check repository status:

```bash
git status
```

Stage changes:

```bash
git add .
```

Commit changes:

```bash
git commit -m "Commit message"
```

Push to GitHub:

```bash
git push
```

---

# Complete CI/CD Workflow

The complete workflow is:

```text
Developer
   |
   | git push
   v
GitHub
   |
   | webhook
   v
Jenkins
   |
   | checkout
   v
Source Code
   |
   | docker build
   v
Docker Image
   |
   | docker push
   v
Amazon ECR
   |
   | helm upgrade
   v
Amazon EKS
   |
   v
Kubernetes Deployment
   |
   v
Kubernetes Service
   |
   v
AWS Application Load Balancer
   |
   v
Flask Application
```

---

# Verification Commands

## Check EKS nodes

```bash
kubectl get nodes
```

## Check Pods

```bash
kubectl get pods
```

## Check Services

```bash
kubectl get services
```

## Check Ingress

```bash
kubectl get ingress
```

## Check HPA

```bash
kubectl get hpa
```

## Check Helm releases

```bash
helm list -A
```

## Check CPU and memory

```bash
kubectl top pods
```

```bash
kubectl top nodes
```

## Check everything at once

```bash
kubectl get pods,svc,ingress,hpa
```

---

# Troubleshooting

## Docker build failed because requirements.txt was missing

The Dockerfile expected:

```text
app/requirements.txt
```

The Docker build context initially did not contain the expected file.

The Dockerfile was corrected to copy:

```text
app/requirements.txt
```

The image then built successfully.

---

## HPA metrics initially showed unknown

The HPA requires resource requests to calculate utilization.

The Deployment was updated with:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
```

After the resource requests were added, the HPA reported CPU and memory utilization.

---

## Cluster Autoscaler initially failed

The Cluster Autoscaler initially lacked the required AWS permissions.

The EKS cluster was configured with the required IAM/OIDC integration and AWS permissions.

The Auto Scaling Group was also configured with the required discovery tags.

The autoscaler could then discover the EKS node group.

---

## AWS Load Balancer Controller could not create the ALB

The initial EKS configuration did not have enough public subnet coverage for the ALB.

A second public subnet was added in:

```text
us-east-1b
```

The ALB was then successfully created.

---

## Jenkins could connect to EKS but could not access Kubernetes resources

Jenkins initially reached the EKS API but received an authorization error.

The Jenkins IAM role was added as an EKS access entry and associated with an EKS access policy.

After the change:

```bash
kubectl get nodes
```

successfully returned the EKS worker node.

---

## Helm could not adopt existing Kubernetes resources

The application resources had originally been created directly with:

```bash
kubectl apply
```

When Helm attempted to install the application, Helm detected that the resources already existed but did not contain Helm ownership metadata.

The existing resources were migrated to Helm management by adding the required Helm annotations and labels.

The resources included:

* Deployment
* Service
* HPA
* Ingress

Helm was then able to successfully manage the existing resources without deleting the working application or ALB.

---

# Final Verification

The final Kubernetes status was verified using:

```bash
kubectl get pods,svc,ingress,hpa
```

The application Pod was:

```text
1/1 Running
```

The HPA reported:

```text
CPU:    1% / 50%
Memory: 16% / 50%
```

The HPA configuration was:

```text
Minimum replicas: 1
Maximum replicas: 12
```

The Ingress reported a public AWS ALB address.

The public application was tested with:

```bash
curl http://<ALB-DNS-NAME>
```

Result:

```text
Hello, World!
```

---

# Final Jenkins Verification

The Jenkins pipeline successfully completed:

```text
Build Docker Image
        |
        v
Push to ECR
        |
        v
Deploy to EKS
```

Final Jenkins result:

```text
Finished: SUCCESS
```

The Helm release was successfully upgraded:

```text
STATUS: deployed
REVISION: 2
```

---

# Final Terraform Verification

Terraform was run after the infrastructure was completed:

```bash
terraform plan
```

Final result:

```text
No changes.
Your infrastructure matches the configuration.
```

This confirms that the AWS infrastructure matches the Terraform configuration.

---

# Project Requirements

| Requirement                  | Status   |
| ---------------------------- | -------- |
| Dockerized Flask application | Complete |
| Hello World application      | Complete |
| AWS VPC                      | Complete |
| Public subnet                | Complete |
| Private subnet               | Complete |
| Internet Gateway             | Complete |
| NAT Gateway                  | Complete |
| Terraform infrastructure     | Complete |
| Amazon EKS                   | Complete |
| t3.small worker nodes        | Complete |
| Minimum 1 worker node        | Complete |
| Maximum 4 worker nodes       | Complete |
| Kubernetes Deployment        | Complete |
| Initial 1 Pod                | Complete |
| HPA                          | Complete |
| 50% CPU target               | Complete |
| 50% memory target            | Complete |
| Maximum 12 Pods              | Complete |
| Cluster Autoscaler           | Complete |
| AWS Load Balancer Controller | Complete |
| Application Load Balancer    | Complete |
| Amazon ECR                   | Complete |
| Jenkins                      | Complete |
| GitHub webhook               | Complete |
| Jenkins Docker build         | Complete |
| Jenkins ECR push             | Complete |
| Jenkins EKS deployment       | Complete |
| Helm deployment              | Complete |
| Public application access    | Complete |

---

# Key Lessons Learned

## Terraform

Terraform allows infrastructure to be defined as code and compared against the real AWS environment.

Important commands:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## Docker

Docker packages the application and its dependencies into a portable image.

```text
Dockerfile
    |
    v
Docker Image
    |
    v
Docker Container
```

---

## Kubernetes

Kubernetes manages the running application.

```text
Deployment
    |
    v
Pods
    |
    v
Service
```

---

## HPA

HPA manages the number of application Pods based on resource utilization.

```text
CPU / Memory
     |
     v
    HPA
     |
     v
Number of Pods
```

---

## Cluster Autoscaler

Cluster Autoscaler manages worker node capacity.

```text
Unschedulable Pods
       |
       v
Cluster Autoscaler
       |
       v
Additional EC2 Worker Nodes
```

---

## Helm

Helm packages Kubernetes resources into a reusable deployment.

```text
Helm Chart
    |
    +--> Deployment
    +--> Service
    +--> HPA
    +--> Ingress
```

---

## Jenkins

Jenkins automates the software delivery process.

```text
Code
 |
 v
Build
 |
 v
Container
 |
 v
ECR
 |
 v
EKS
```

---

# Final Result

The completed project provides an automated AWS CI/CD deployment platform.

A developer can push code to GitHub and trigger the following automated process:

```text
GitHub
   ↓
Jenkins
   ↓
Docker Build
   ↓
Amazon ECR
   ↓
Helm
   ↓
Amazon EKS
   ↓
Kubernetes
   ↓
Autoscaling
   ↓
AWS Application Load Balancer
   ↓
Flask Application
```
App URL:
http://k8s-default-tech2app-e0908ec3e7-310219193.us-east-1.elb.amazonaws.com

The deployed application returns:

```text
Hello, World!
```

and is publicly accessible through the AWS Application Load Balancer.

---
# GitOps pipeline test
