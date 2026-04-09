# Deployment Guide

## Step-by-Step Instructions

### Phase 1: Container Setup (15 minutes)

#### 1.1 Build Docker Image
```bash
cd auto-healing-web-tier
docker build -t auto-healing-web:latest .
```

#### 1.2 Test Locally
```bash
docker run -d -p 8080:80 auto-healing-web:latest
curl http://localhost:8080
docker stop $(docker ps -q --filter ancestor=auto-healing-web:latest)
```

#### 1.3 Push to Docker Hub
```bash
# Tag image
docker tag auto-healing-web:latest YOUR_DOCKERHUB_USERNAME/auto-healing-web:latest

# Login
docker login

# Push
docker push YOUR_DOCKERHUB_USERNAME/auto-healing-web:latest
```

**Alternative: GitHub Container Registry**
```bash
# Create Personal Access Token with write:packages scope
export CR_PAT=YOUR_TOKEN

# Login
echo $CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Tag and push
docker tag auto-healing-web:latest ghcr.io/YOUR_GITHUB_USERNAME/auto-healing-web:latest
docker push ghcr.io/YOUR_GITHUB_USERNAME/auto-healing-web:latest
```

### Phase 2: Terraform Setup (10 minutes)

#### 2.1 Configure AWS Credentials
```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"

# Option 2: AWS CLI
aws configure
```

#### 2.2 Update Variables
```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
# Update docker_image with your registry URL
```

#### 2.3 Initialize Terraform
```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Phase 3: Validation (5 minutes)

#### 3.1 Format Check
```bash
terraform fmt
```

#### 3.2 Validate Configuration
```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

#### 3.3 Review Plan
```bash
terraform plan
```

Review the output. You should see:
- 8 resources to be created
- No errors or warnings

### Phase 4: Deployment (Optional - 10 minutes)

#### 4.1 Apply Configuration
```bash
terraform apply
```

Type `yes` when prompted.

Wait 5-10 minutes for:
- NLB provisioning
- EC2 instances launching
- Docker containers starting
- Health checks passing

#### 4.2 Get Load Balancer URL
```bash
terraform output alb_dns_name
```

#### 4.3 Test Application
```bash
# Wait 2-3 minutes for health checks
curl http://$(terraform output -raw alb_dns_name)
```

Or open in browser:
```
http://<nlb-dns-name>
```

### Phase 5: Verification (5 minutes)

#### 5.1 Check Auto Scaling Group
```bash
aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'web')].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Current:Instances[0].HealthStatus}" \
  --output table
```

#### 5.2 Test Self-Healing
```bash
# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=*web*" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Watch ASG launch replacement (takes 3-5 minutes)
watch -n 10 'aws autoscaling describe-auto-scaling-groups \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, \"web\")].Instances[]" \
  --output table'
```

### Phase 6: Cleanup

#### 6.1 Destroy Infrastructure
```bash
terraform destroy
```

Type `yes` when prompted.

#### 6.2 Verify Cleanup
```bash
# Check no resources remain
aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=Terraform" --query "Reservations[].Instances[].InstanceId"
aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='web-nlb'].LoadBalancerArn"
```

## Troubleshooting

### Issue: Terraform init fails
```bash
# Clear cache
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: Health checks failing
```bash
# SSH to instance (add key pair to launch template first)
ssh -i your-key.pem ec2-user@<instance-ip>

# Check Docker status
sudo systemctl status docker
sudo docker ps
sudo docker logs $(sudo docker ps -q)

# Check user-data logs
sudo cat /var/log/cloud-init-output.log
```

### Issue: Container not pulling
```bash
# Check if image is public
docker pull YOUR_DOCKERHUB_USERNAME/auto-healing-web:latest

# If private, add Docker credentials to user-data
```

### Issue: High costs
```bash
# Check running resources
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" --output table
aws elbv2 describe-load-balancers --query "LoadBalancers[].[LoadBalancerName,State.Code]" --output table

# Destroy immediately
terraform destroy -auto-approve
```

## Cost Monitoring

### Daily Cost Check
```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "1 day ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

### Set Billing Alert
1. Go to AWS Billing Console
2. Create Budget
3. Set threshold: $20 USD
4. Add email notification

## Next Steps

1. Add HTTPS with ACM certificate
2. Implement CloudWatch alarms
3. Add application monitoring
4. Set up CI/CD pipeline
5. Implement blue-green deployment
6. Add WAF for security
