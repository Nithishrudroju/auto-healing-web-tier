# Auto-Healing Web Tier on AWS

## Solution Overview
- **Cloud Provider**: AWS (us-east-1 region)
- **IaC Tool**: Terraform
- **Architecture**: Auto Scaling Group + Elastic IP + Containerized NGINX
- **Container Registry**: Docker Hub (free tier)
- **Monthly Cost**: **< $20 AUD** ✅

## Architecture

```
Internet
    ↓
Elastic IP (Static)
    ↓
Auto Scaling Group (1 instance)
    ↓
EC2 t2.micro (Docker + NGINX Container)
```

### Key Features
- ✅ Self-healing via ASG health checks
- ✅ Static IP address (Elastic IP)
- ✅ Containerized application
- ✅ Automatic container deployment via user-data
- ✅ **Cost-optimized: $7.50 AUD/month** (Free Tier eligible)

## Prerequisites
- AWS Account with credentials configured
- Terraform >= 1.0
- Docker (for building image)
- Docker Hub account (free)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t your-dockerhub-username/auto-healing-web:latest .

# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/auto-healing-web:latest
```

**Alternative: GitHub Container Registry**
```bash
docker build -t ghcr.io/your-github-username/auto-healing-web:latest .
echo $GITHUB_TOKEN | docker login ghcr.io -u your-github-username --password-stdin
docker push ghcr.io/your-github-username/auto-healing-web:latest
```

### 2. Update Terraform Variables

Edit `variables.tf` and update the `docker_image` variable:
```hcl
variable "docker_image" {
  default = "your-dockerhub-username/auto-healing-web:latest"
}
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan (review changes)
terraform plan

# Apply (optional - deploy to AWS)
terraform apply
```

### 4. Access Application

After deployment, get the Elastic IP:
```bash
terraform output elastic_ip
```

Visit `http://<elastic-ip>` in your browser.

## Cost Estimation (AUD)

| Resource | Monthly Cost (AUD) |
|----------|-------------------|
| 1x t2.micro EC2 (Free Tier) | $0.00 |
| 1x Elastic IP (attached) | $0.00 |
| Data Transfer (1GB) | $1.40 |
| **Total (with Free Tier)** | **$1.40** |
| **Total (without Free Tier)** | **$7.50** |

### Cost Breakdown:
- **With AWS Free Tier** (first 12 months): ~$1.40/month
- **After Free Tier**: ~$7.50/month
- **Well under $20 AUD/month** ✅

### AWS Free Tier Includes:
- 750 hours/month of t2.micro EC2 (12 months)
- 1 Elastic IP (when attached to running instance)
- 15 GB data transfer out

## Project Structure

```
.
├── main.tf              # Main infrastructure resources
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── Dockerfile           # Container definition
├── index.html           # Static web page
├── .gitignore           # Git ignore rules
├── .dockerignore        # Docker ignore rules
└── README.md            # This file
```

## Terraform Resources

- `aws_launch_template` - EC2 launch configuration with Docker user-data
- `aws_autoscaling_group` - Self-healing ASG (1 instance)
- `aws_eip` - Elastic IP for static address
- `aws_eip_association` - Associates EIP with EC2 instance
- `aws_security_group` - Security group for EC2

## Self-Healing Mechanism

- ASG monitors instance health (EC2 status checks)
- If instance fails, ASG terminates and launches new instance
- Elastic IP automatically reassociates to new instance
- Downtime: ~3-5 minutes during replacement
- No manual intervention required

## Naming Conventions

- Resources: `web-<resource-type>`
- Example: `web-asg`, `web-eip`, `web-sg`
- Tags: All resources tagged with `Name`

## CI/CD Pipeline (Optional)

Create `.github/workflows/terraform.yml`:

```yaml
name: Terraform CI
on: [push, pull_request]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init
      - run: terraform fmt -check
      - run: terraform validate
      - run: terraform plan
```

## Cleanup

```bash
terraform destroy
```

## Assumptions

1. Using AWS default VPC and subnets
2. Public Docker Hub registry (no authentication required)
3. Amazon Linux 2023 AMI
4. Single region deployment (us-east-1)
5. HTTP only (no HTTPS/SSL)
6. Single instance (no load balancing)
7. AWS Free Tier eligible account

## Troubleshooting

**Issue**: Container not starting
- Check user-data logs: `sudo cat /var/log/cloud-init-output.log`
- Verify Docker is running: `sudo systemctl status docker`

**Issue**: Health checks failing
- Ensure container exposes port 80
- Check security group allows port 80

**Issue**: Elastic IP not associating
- Wait 2-3 minutes after instance launch
- Check ASG has running instance
- Verify EIP association in AWS console

**Issue**: Cannot access application
- Verify security group allows inbound port 80
- Check instance is running: `aws ec2 describe-instances`
- Test locally: `curl http://<elastic-ip>`

## Testing Self-Healing

```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=web-asg" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Watch ASG launch replacement (3-5 minutes)
watch -n 10 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query "AutoScalingGroups[0].Instances[]"'
```

## Advantages of This Architecture

✅ **Cost-effective**: $1.40-$7.50/month (vs $34+ with NLB)
✅ **Self-healing**: Automatic instance replacement
✅ **Static IP**: Elastic IP doesn't change
✅ **Simple**: No load balancer complexity
✅ **Free Tier eligible**: t2.micro included in Free Tier

## Limitations

⚠️ **Single instance**: No high availability during replacement
⚠️ **Downtime**: 3-5 minutes during self-healing
⚠️ **No load balancing**: Single instance handles all traffic
⚠️ **Manual scaling**: No auto-scaling based on load

## Author
DevOps Challenge - Auto-Healing Web Tier

## License
MIT
