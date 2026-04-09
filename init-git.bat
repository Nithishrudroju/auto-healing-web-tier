@echo off
REM Git initialization script with incremental commits (Windows)

echo Initializing Git repository...
git init

echo Setting up Git configuration...
git config user.name "Your Name"
git config user.email "your.email@example.com"

echo Creating incremental commits...

REM Commit 1: Initial project structure
git add .gitignore .dockerignore
git commit -m "chore: initial project setup with ignore files"

REM Commit 2: Container setup
git add Dockerfile index.html
git commit -m "feat: add Dockerfile and static web page"

REM Commit 3: Terraform variables
git add variables.tf terraform.tfvars.example
git commit -m "feat: add Terraform variables configuration"

REM Commit 4: Core infrastructure
git add main.tf
git commit -m "feat: implement auto-scaling infrastructure with NLB"

REM Commit 5: Outputs
git add outputs.tf
git commit -m "feat: add Terraform outputs for ALB DNS"

REM Commit 6: Documentation
git add README.md
git commit -m "docs: add comprehensive README with setup instructions"

REM Commit 7: Architecture
git add ARCHITECTURE.md
git commit -m "docs: add architecture diagram and component details"

REM Commit 8: Deployment guide
git add DEPLOYMENT.md
git commit -m "docs: add step-by-step deployment guide"

REM Commit 9: CI/CD pipeline
git add .github/
git commit -m "ci: add GitHub Actions workflow for Terraform validation"

REM Commit 10: Deliverables summary
git add DELIVERABLES.md
git commit -m "docs: add project deliverables summary"

REM Commit 11: Remove old userdata.sh (if exists)
if exist "userdata.sh" (
    git rm userdata.sh
    git commit -m "chore: remove unused userdata.sh file"
)

echo.
echo ✅ Git repository initialized with incremental commits!
echo.
echo Next steps:
echo 1. Create GitHub repository
echo 2. git remote add origin https://github.com/YOUR_USERNAME/auto-healing-web-tier.git
echo 3. git branch -M main
echo 4. git push -u origin main
pause
