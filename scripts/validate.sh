#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[✅ PASS]${NC} $1"; }
fail() { echo -e "${RED}[❌ FAIL]${NC} $1"; exit 1; }

echo "🔍 Running Day 1.2 Validation..."

# 1. Check S3 bucket was created by the pipeline
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET_PREFIX="cnc-logs"   # ← Change this if you used a different prefix!
BUCKET_NAME="${BUCKET_PREFIX}-${ACCOUNT}-dev"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    log "S3 bucket created successfully: $BUCKET_NAME"
else
    fail "S3 bucket $BUCKET_NAME not found. Did you change the prefix?"
fi

# 2. Verify security features
ENC=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "none")
if [[ "$ENC" == "AES256" ]]; then
    log "Server-side encryption (AES256) enabled"
else
    fail "Encryption missing"
fi

# 3. Check mandatory tags
TAGS=$(aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" --query 'TagSet[*].Key' --output text 2>/dev/null || echo "")
for tag in "ManagedBy" "Environment" "Project" "Owner"; do
    if echo "$TAGS" | grep -q "$tag"; then
        log "Tag '$tag' present"
    else
        fail "Missing required tag: $tag"
    fi
done

# 4. Check GitHub Actions workflow exists
if [ -f "../.github/workflows/terraform.yml" ]; then
    log "GitHub Actions pipeline configured"
else
    fail "Workflow file missing"
fi

echo ""
echo -e "${GREEN}🎉 DAY 1.2 VALIDATION PASSED!${NC}"
echo ""
echo "✅ You have successfully built a self-service Golden Path pipeline!"
echo ""
echo "What you achieved in Day 1:"
echo "   • Golden Path template with security defaults (Day 1.1)"
echo "   • Automated CI/CD pipeline with Plan → Review → Apply (Day 1.2)"
echo "   • Secure, tagged, encrypted S3 bucket provisioned automatically"
echo "   • Remote state management in Terraform Cloud"
echo ""
echo "Your platform is now ready for developers to self-serve infrastructure!"
EOF
