# Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ HTTP (Port 80)
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Network Load Balancer (NLB)                     │
│                    web-nlb                                   │
│              (Multi-AZ, Health Checks)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ TCP:80
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Target Group (web-tg)                           │
│              Health Check: HTTP GET /                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
        ▼                                     ▼
┌──────────────────┐                 ┌──────────────────┐
│   EC2 Instance   │                 │   EC2 Instance   │
│   (t3.micro)     │                 │   (t3.micro)     │
│                  │                 │   (Auto-scaled)  │
│  ┌────────────┐  │                 │  ┌────────────┐  │
│  │   Docker   │  │                 │  │   Docker   │  │
│  │  ┌──────┐  │  │                 │  │  ┌──────┐  │  │
│  │  │NGINX │  │  │                 │  │  │NGINX │  │  │
│  │  │:80   │  │  │                 │  │  │:80   │  │  │
│  │  └──────┘  │  │                 │  │  └──────┘  │  │
│  └────────────┘  │                 │  └────────────┘  │
└──────────────────┘                 └──────────────────┘
        │                                     │
        └──────────────────┬──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│           Auto Scaling Group (ASG)                           │
│           Min: 1, Desired: 1, Max: 2                         │
│           Health Check Type: ELB                             │
│           Self-Healing Enabled                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Security Groups                           │
├─────────────────────────────────────────────────────────────┤
│  NLB SG:  Ingress 0.0.0.0/0:80 → NLB                        │
│  Web SG:  Ingress 0.0.0.0/0:80 → EC2:80                     │
│           Egress  EC2 → 0.0.0.0/0 (all)                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Container Registry                         │
│         Docker Hub / GitHub Container Registry               │
│         Image: auto-healing-web:latest                       │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Network Load Balancer
- Type: Network Load Balancer (Layer 4)
- Protocol: TCP
- Port: 80
- Multi-AZ deployment

### Auto Scaling Group
- Launch Template: Amazon Linux 2023 + Docker
- Instance Type: t2.micro
- Capacity: Min 2, Desired 2, Max 3
- Health Check: ELB with 300s grace period
- Self-healing: Automatic instance replacement

### EC2 Instances
- AMI: Amazon Linux 2023
- Docker: Installed via user-data
- Container: NGINX Alpine with custom HTML
- Auto-restart: Container restarts on failure

### Container Deployment Flow
1. EC2 launches from Launch Template
2. User-data script installs Docker
3. Docker pulls image from registry
4. Container runs on port 80
5. NLB health check validates instance
6. Traffic routes to healthy instances
