# Quick Reference Card

## 🚀 Essential Commands

### Docker Commands
```bash
# Build image
docker build -t auto-healing-web:latest .

# Test locally
docker run -d -p 8080:80 auto-healing-web:latest

# Push to Docker Hub
docker tag auto-healing-web:latest YOUR_USERNAME/auto-healing-web:latest
docker push YOUR_USERNAME/auto-healing-web:latest

# Push to GitHub Container Registry
docker tag auto-healing-web:latest ghcr.io/YOUR_USERNAME/auto-healing-web:latest
docker push ghcr.io/YOUR_USERNAME/auto-healing-web:latest
```

### Terraform Commands
```bash
# Initialize
terraform init

# Format code
terraform fmt

# Validate
terraform validate

# Plan (dry-run)
terraform plan

# Apply (deploy)
terraform apply

# Destroy (cleanup)
terraform destroy

# Show outputs
terraform output
terraform output -raw alb_dns_name
```

### AWS CLI Commands
```bash
# List EC2 instances
aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType]" --output table

# List Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]" --output table

# List Load Balancers
aws elbv2 describe-load-balancers --query "LoadBalancers[].[LoadBalancerName,DNSName,State.Code]" --output table

# Terminate instance (test self-healing)
aws ec2 terminate-instances --instance-ids i-xxxxx

# Get current costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

### Git Commands
```bash
# Initialize repository
git init

# Add files
git add .

# Commit
git commit -m "feat: initial commit"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/auto-healing-web-tier.git

# Push
git branch -M main
git push -u origin main

# View history
git log --oneline
```

## 📋 Pre-Deployment Checklist

- [ ] Docker installed and running
- [ ] AWS credentials configured
- [ ] Terraform installed (>= 1.0)
- [ ] Docker image built and pushed
- [ ] terraform.tfvars updated with your docker_image
- [ ] AWS region set correctly (ap-south-1)

## 🔍 Verification Commands

```bash
# Check Terraform version
terraform version

# Check AWS credentials
aws sts get-caller-identity

# Check Docker
docker --version
docker ps

# Test container locally
curl http://localhost:8080

# Test deployed application
curl http://$(terraform output -raw alb_dns_name)
```

## 🐛 Troubleshooting Quick Fixes

### Terraform init fails
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Container not accessible
```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*web*"

# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>
```

### High AWS costs
```bash
# List all running resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws elbv2 describe-load-balancers

# Destroy everything
terraform destroy -auto-approve
```

## 💰 Cost Optimization Tips

1. **Use Free Tier**: t2.micro for 750 hours/month (first 12 months)
2. **Remove NLB**: Use Elastic IP instead (~$10.50/month)
3. **Use Spot Instances**: 70% cost reduction
4. **Stop when not in use**: `terraform destroy` after testing
5. **Set billing alerts**: AWS Budgets at $20 threshold

## 📊 Resource Naming Convention

| Resource Type | Name Pattern | Example |
|--------------|--------------|---------|
| Launch Template | `web-*` | `web-20240101123456` |
| Auto Scaling Group | `terraform-*` | `terraform-xxxxx` |
| Load Balancer | `web-nlb` | `web-nlb` |
| Target Group | `web-tg` | `web-tg` |
| Security Group | `terraform-*` | `terraform-xxxxx` |

## 🔗 Useful Links

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Pricing Calculator](https://calculator.aws)
- [Docker Hub](https://hub.docker.com)
- [GitHub Container Registry](https://ghcr.io)
- [AWS Free Tier](https://aws.amazon.com/free)

## 📞 Support

For issues or questions:
1. Check DEPLOYMENT.md troubleshooting section
2. Review Terraform plan output
3. Check AWS CloudWatch logs
4. Verify security group rules

---

**Pro Tip**: Always run `terraform plan` before `terraform apply` to review changes!
