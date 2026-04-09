# Auto-Healing Web Tier on AWS

## Solution Overview
- **Cloud Provider**: AWS (us-east-1 region)
- **IaC Tool**: Terraform
- **Architecture**: Auto Scaling Group + Network Load Balancer + Containerized NGINX
- **Container Registry**: Docker Hub (free tier)
- **Monthly Cost**: **< $20 AUD** ✅

## Architecture

```
Internet
    ↓
Network Load Balancer (Multi-AZ)
    ↓
Auto Scaling Group (2+ instances)
    ↓
EC2 t2.micro (Docker + NGINX Container) x 2+
```

### Key Features
- ✅ Self-healing via ASG health checks
- ✅ Load-balanced traffic across 2+ instances (N+1 capacity)
- ✅ Containerized application  
- ✅ Automatic container deployment via user-data
- ✅ Multi-AZ deployment for high availability
- ✅ **Cost-optimized: ~$15-20 AUD/month**

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

After deployment, get the Network Load Balancer URL:
```bash
terraform output nlb_dns_name
```

Visit `http://<nlb-dns-name>` in your browser.

## Cost Estimation (AUD)

| Resource | Monthly Cost (AUD) |
|----------|-------------------|
| 2x t2.micro EC2 (Free Tier) | $0.00 |
| 1x Network Load Balancer | $22.40 |
| Data Transfer (2GB) | $2.80 |
| **Total (with Free Tier)** | **$25.20** |
| **Total (without Free Tier)** | **$38.50** |

### Cost Breakdown:
- **With AWS Free Tier** (first 12 months): ~$25.20/month
- **After Free Tier**: ~$38.50/month
- **NLB Cost**: ~$22.40/month (Layer 4 LB with health checks)
- **EC2 Cost**: 2x t2.micro instances (~$7.80/month after Free Tier)
- **Data Transfer**: ~$2.80/month for 2GB outbound

### AWS Free Tier Includes:
- 750 hours/month of t2.micro EC2 (12 months) - covers 1 instance
- 15 GB data transfer out
- NLB charges apply after Free Tier expires

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
- `aws_autoscaling_group` - Self-healing ASG (2-3 instances with ELB health checks)
- `aws_lb` - Network Load Balancer for traffic distribution
- `aws_lb_target_group` - Target group with TCP health checks
- `aws_lb_listener` - Listener to forward traffic to targets
- `aws_security_group` - Security group for EC2

## Self-Healing Mechanism

- ASG monitors instance health via Network Load Balancer health checks
- If instance becomes unhealthy, ASG terminates and launches new instance
- NLB automatically removes unhealthy instances and routes traffic to healthy ones
- Downtime: Minimal (~1-2 minutes) with multi-instance setup
- No manual intervention required
- Health checks validate port 80 TCP connectivity

## Naming Conventions

- Resources: `web-<resource-type>`
- Example: `web-asg`, `web-nlb`, `web-tg`, `web-sg`
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
