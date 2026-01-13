#!/bin/bash
# Test G000 platform with DEPLOY MODE (dry_run=false)

set -e

AWX_HOST="http://localhost:8081"
AWX_USER="awxcloudflare"
AWX_PASS="Cloudflare@2025"
TEMPLATE_ID="28"

echo "=========================================="
echo "Testing G000 with DEPLOY MODE"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will apply changes to Cloudflare!"
echo "    Domain: route-game-flex.eu"
echo "    Platform: G000"
echo "    Scope: dns"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# Launch a test job with dry_run=false
echo "Launching AWX job with dry_run=false..."
JOB_RESPONSE=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "ticket_number": "TEST-G000-DEPLOY",
      "platform_id": "G000",
      "cloudflare_scope": "dns",
      "cloudflare_dry_run": "false"
    }
  }' \
  "${AWX_HOST}/api/v2/job_templates/${TEMPLATE_ID}/launch/")

JOB_ID=$(echo "$JOB_RESPONSE" | jq -r '.id // empty')

if [ -z "$JOB_ID" ]; then
    echo "✗ Failed to launch job"
    echo "$JOB_RESPONSE" | jq .
    exit 1
fi

echo "✓ Job launched: ID ${JOB_ID}"
echo ""

# Wait for job to complete
echo "Waiting for job to complete..."
for i in {1..30}; do
    STATUS=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
      "${AWX_HOST}/api/v2/jobs/${JOB_ID}/" | jq -r '.status')
    
    if [ "$STATUS" = "successful" ]; then
        echo "✓ Job completed successfully"
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "✗ Job failed"
        break
    fi
    
    echo "  Status: ${STATUS} (${i}/30)"
    sleep 2
done
echo ""

# Get job output and check for deploy mode
echo "Checking job output..."
JOB_OUTPUT=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  "${AWX_HOST}/api/v2/jobs/${JOB_ID}/stdout/?format=txt")

# Check for deploy mode message
if echo "$JOB_OUTPUT" | grep -q "DEPLOY MODE - Changes will be applied"; then
    echo "✓ Running in DEPLOY MODE (changes applied)"
elif echo "$JOB_OUTPUT" | grep -q "DRY-RUN MODE ENABLED"; then
    echo "✗ Still running in DRY-RUN MODE (unexpected)"
else
    echo "? Mode status unclear"
fi
echo ""

# Show DNS changes
if echo "$JOB_OUTPUT" | grep -q "Manage DNS record"; then
    echo "DNS Records being created/updated:"
    echo "$JOB_OUTPUT" | grep -A3 "Manage DNS record" | head -20
else
    echo "No DNS record changes found"
fi
echo ""

echo "=========================================="
echo "Test Complete"
echo "=========================================="
echo ""
echo "View full job output:"
echo "  ${AWX_HOST}/#/jobs/playbook/${JOB_ID}/output"
echo ""
