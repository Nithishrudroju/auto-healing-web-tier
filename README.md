# Auto-Healing Web Tier on AWS

## Solution Overview
- **Cloud Provider**: AWS (us-east-1 region)
- **IaC Tool**: Terraform
- **Architecture**: Auto Scaling Group + Network Load Balancer + Containerized NGINX
- **Container Registry**: Docker Hub (public)
- **High Availability**: Multi-AZ deployment with 2+ instances

## Architecture

```
Internet
    ↓
Network Load Balancer (Multi-AZ)
    ↓
Auto Scaling Group (2-3 instances)
    ↓
EC2 t2.micro (Docker + NGINX Container) x 2+
```

### Key Features
- ✅ Self-healing via ASG health checks
- ✅ Load-balanced traffic across 2+ instances
- ✅ Containerized NGINX application
- ✅ Automatic container deployment via user-data
- ✅ Multi-AZ deployment for high availability
- ✅ Zero downtime during instance failures

## Prerequisites
- AWS Account with IAM user credentials
- Terraform >= 1.0 installed
- Docker installed locally
- Docker Hub account (free)
- AWS CLI configured (optional)

## Step-by-Step Deployment Guide

### Step 1: Configure AWS IAM Permissions

Your IAM user needs the following permissions. Attach the policy to your user:

```bash
aws iam attach-user-policy \
  --user-name nithish-test \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-user-policy \
  --user-name nithish-test \
  --policy-arn arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess
```

**Or create a custom policy** with minimal permissions:
- `ec2:*` (EC2 full access)
- `elasticloadbalancing:*` (ELB full access)
- `autoscaling:*` (Auto Scaling full access)

### Step 2: Build and Push Docker Image

Navigate to the project directory and build the Docker image:

```bash
cd C:\Users\Windows\OneDrive\Desktop\DevOps\auto-healing-web-tier

# Build the Docker image
docker build -t nithishkumar111/auto-healing-web:latest .

# Login to Docker Hub
docker login

# Push the image to Docker Hub
docker push nithishkumar111/auto-healing-web:latest
```

**Note**: If using a different Docker Hub username, update `terraform.tfvars`:
```hcl
docker_image = "your-dockerhub-username/auto-healing-web:latest"
```

### Step 3: Configure AWS Credentials

Ensure your AWS credentials are configured:

```bash
# Option 1: Using AWS CLI
aws configure

# Option 2: Using environment variables
set AWS_ACCESS_KEY_ID=your-access-key
set AWS_SECRET_ACCESS_KEY=your-secret-key
set AWS_DEFAULT_REGION=us-east-1
```

### Step 4: Review Terraform Configuration

Check the configuration files:

**terraform.tfvars** (current settings):
```hcl
aws_region       = "us-east-1"
instance_type    = "t2.micro"
min_size         = 2
desired_capacity = 2
max_size         = 3
docker_image     = "nithishkumar111/auto-healing-web:latest"
```

Modify these values if needed for your requirements.

### Step 5: Initialize Terraform

Initialize Terraform to download required providers:

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
Terraform has been successfully initialized!
```

### Step 6: Validate Configuration

Validate the Terraform configuration:

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### Step 7: Plan Infrastructure Changes

Review what Terraform will create:

```bash
terraform plan
```

This will show:
- 1 Security Group
- 1 Launch Template
- 1 Auto Scaling Group
- 1 Network Load Balancer
- 1 Target Group
- 1 Load Balancer Listener

### Step 8: Deploy Infrastructure

Apply the Terraform configuration to create resources:

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Deployment time**: ~3-5 minutes

Expected output:
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

application_url = "http://web20260409173648224300000003-8ef837c6ab76fd9a.elb.us-east-1.amazonaws.com"
nlb_dns_name = "web20260409173648224300000003-8ef837c6ab76fd9a.elb.us-east-1.amazonaws.com"
```

### Step 9: Access the Application

Get the application URL:

```bash
terraform output application_url
```

Open the URL in your browser:
```
http://<nlb-dns-name>
```

**Note**: Wait 2-3 minutes after deployment for instances to become healthy and pass health checks.

### Step 10: Verify Auto-Healing (Optional)

Test the self-healing capability:

```bash
# Get running instance IDs
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=web-asg" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output table

# Terminate one instance to trigger auto-healing
aws ec2 terminate-instances --instance-ids <instance-id>

# Watch ASG launch replacement (takes 3-5 minutes)
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names web-asg \
  --query "AutoScalingGroups[0].Instances[]"
```

The ASG will automatically launch a new instance to maintain desired capacity.

## Project Structure

```
.
├── main.tf                  # Main infrastructure resources
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── terraform.tfvars         # Variable values
├── terraform.tfvars.example # Example variable file
├── Dockerfile               # Container definition
├── index.html               # Static web page
├── .gitignore               # Git ignore rules
├── .dockerignore            # Docker ignore rules
├── ARCHITECTURE.md          # Architecture documentation
├── DEPLOYMENT.md            # Deployment guide
├── DELIVERABLES.md          # Project deliverables
└── README.md                # This file
```

## Terraform Resources Created

| Resource | Purpose |
|----------|---------|
| `aws_security_group.web` | Allows HTTP (port 80) traffic |
| `aws_launch_template.web` | EC2 instance configuration with Docker user-data |
| `aws_autoscaling_group.web` | Self-healing ASG (2-3 instances) |
| `aws_lb.web` | Network Load Balancer for traffic distribution |
| `aws_lb_target_group.web` | Target group with HTTP health checks |
| `aws_lb_listener.web` | Listener forwarding traffic to targets |

## Self-Healing Mechanism

1. **Health Checks**: NLB performs HTTP health checks on port 80 every 30 seconds
2. **Failure Detection**: If 2 consecutive checks fail, instance marked unhealthy
3. **Auto Replacement**: ASG terminates unhealthy instance and launches new one
4. **Traffic Routing**: NLB automatically routes traffic only to healthy instances
5. **Zero Downtime**: With 2+ instances, application remains available during healing

**Health Check Configuration**:
- Protocol: HTTP
- Path: `/`
- Interval: 30 seconds
- Timeout: 3 seconds
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 2 consecutive failures

## Cost Estimation (USD)

| Resource | Monthly Cost |
|----------|-------------|
| 2x t2.micro EC2 (Free Tier) | $0.00 |
| 1x Network Load Balancer | ~$16.20 |
| Data Transfer (2GB) | ~$0.18 |
| **Total (with Free Tier)** | **~$16.38** |
| **Total (without Free Tier)** | **~$22.50** |

### Cost Breakdown:
- **NLB**: $0.0225/hour × 730 hours = $16.43/month
- **EC2**: 2 × t2.micro ($0.0116/hour × 730 hours) = $16.94/month (Free Tier: $0)
- **Data Transfer**: First 1GB free, then $0.09/GB
- **AWS Free Tier** (first 12 months): 750 hours/month of t2.micro

## Cleanup

To destroy all resources and avoid charges:

```bash
terraform destroy
```

Type `yes` when prompted to confirm.

**Warning**: This will permanently delete all resources created by Terraform.

## Troubleshooting

### Issue: Permission Denied Errors

**Error**: `UnauthorizedOperation: You are not authorized to perform: ec2:DescribeImages`

**Solution**: Attach required IAM policies (see Step 1)

### Issue: Application Not Accessible

**Symptoms**: Cannot access NLB URL

**Solutions**:
1. Wait 2-3 minutes for instances to pass health checks
2. Verify security group allows port 80: `aws ec2 describe-security-groups --group-ids <sg-id>`
3. Check instance status: `aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=web-asg"`
4. Check target health: `aws elbv2 describe-target-health --target-group-arn <tg-arn>`

### Issue: Docker Container Not Starting

**Symptoms**: Instances unhealthy, health checks failing

**Solutions**:
1. SSH into instance and check logs:
   ```bash
   sudo cat /var/log/cloud-init-output.log
   sudo docker ps -a
   sudo docker logs <container-id>
   ```
2. Verify Docker image is accessible: `docker pull nithishkumar111/auto-healing-web:latest`
3. Check user-data script in launch template

### Issue: Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**: 
```bash
# Remove lock file
del .terraform.tfstate.lock.info

# Or force unlock (use with caution)
terraform force-unlock <lock-id>
```

## Testing Checklist

- [ ] Application accessible via NLB URL
- [ ] Both instances showing as healthy in target group
- [ ] Terminate one instance and verify auto-healing
- [ ] Application remains accessible during instance replacement
- [ ] Docker container running on both instances
- [ ] Health checks passing (HTTP 200 response)

## Advantages of This Architecture

✅ **High Availability**: Multi-AZ deployment with 2+ instances  
✅ **Self-Healing**: Automatic instance replacement on failure  
✅ **Load Balanced**: Traffic distributed across healthy instances  
✅ **Scalable**: Can scale from 2 to 3 instances automatically  
✅ **Containerized**: Easy to update application via Docker image  
✅ **Infrastructure as Code**: Reproducible and version-controlled  

## Limitations

⚠️ **Cost**: NLB adds ~$16/month (consider ALB for HTTP-only workloads)  
⚠️ **Healing Time**: 3-5 minutes to replace failed instance  
⚠️ **No Auto-Scaling**: Fixed capacity (2-3 instances), no CPU-based scaling  
⚠️ **HTTP Only**: No HTTPS/SSL termination configured  

## Next Steps / Improvements

1. **Add HTTPS**: Configure SSL certificate and HTTPS listener
2. **Auto-Scaling Policies**: Add CPU-based scaling policies
3. **Monitoring**: Set up CloudWatch alarms and dashboards
4. **CI/CD**: Automate Docker image builds and deployments
5. **Custom Domain**: Add Route 53 DNS with custom domain
6. **Logging**: Configure centralized logging with CloudWatch Logs
7. **Backup**: Implement automated AMI backups

## Author
DevOps Challenge - Auto-Healing Web Tier

## License
MIT
