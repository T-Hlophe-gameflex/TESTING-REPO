#!/bin/bash
# Test G000 platform with route-game-flex.eu domain

set -e

AWX_HOST="http://localhost:8081"
AWX_USER="awxcloudflare"
AWX_PASS="Cloudflare@2025"
TEMPLATE_ID="28"

echo "=========================================="
echo "Testing G000 with route-game-flex.eu"
echo "=========================================="
echo ""

# Verify the platform file has the correct domain
echo "1. Verifying platform file configuration..."
DOMAIN=$(grep "platform_domain:" /Users/thami.hlophe/Documents/TEST/TESTING-REPO/inventories/TEST/group_vars/all/platforms/global/G000.yml | awk '{print $2}' | tr -d '"')
echo "   Platform Domain: ${DOMAIN}"

if [ "$DOMAIN" = "route-game-flex.eu" ]; then
    echo "   ✓ Domain correctly set to route-game-flex.eu"
else
    echo "   ✗ Expected route-game-flex.eu but got ${DOMAIN}"
    exit 1
fi
echo ""

# Launch a test job
echo "2. Launching AWX job with G000 platform..."
JOB_RESPONSE=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "ticket_number": "TEST-G000-DOMAIN",
      "platform_id": "G000",
      "cloudflare_scope": "dns",
      "cloudflare_dry_run": "true"
    }
  }' \
  "${AWX_HOST}/api/v2/job_templates/${TEMPLATE_ID}/launch/")

JOB_ID=$(echo "$JOB_RESPONSE" | jq -r '.id // empty')

if [ -z "$JOB_ID" ]; then
    echo "   ✗ Failed to launch job"
    echo "$JOB_RESPONSE" | jq .
    exit 1
fi

echo "   ✓ Job launched: ID ${JOB_ID}"
echo ""

# Wait for job to complete
echo "3. Waiting for job to complete..."
for i in {1..30}; do
    STATUS=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
      "${AWX_HOST}/api/v2/jobs/${JOB_ID}/" | jq -r '.status')
    
    if [ "$STATUS" = "successful" ]; then
        echo "   ✓ Job completed successfully"
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "   ✗ Job failed"
        break
    fi
    
    echo "   Status: ${STATUS} (${i}/30)"
    sleep 2
done
echo ""

# Get job output and check for domain
echo "4. Checking job output for domain usage..."
JOB_OUTPUT=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  "${AWX_HOST}/api/v2/jobs/${JOB_ID}/stdout/?format=txt")

echo "$JOB_OUTPUT" | grep -E "platform_domain|effective_zone_name|target_zone|route-game-flex" | head -20 || echo "   (searching full output...)"
echo ""

# Check if route-game-flex.eu appears in the output
if echo "$JOB_OUTPUT" | grep -q "route-game-flex.eu"; then
    echo "   ✓ Domain 'route-game-flex.eu' found in job output"
    echo ""
    echo "   Context:"
    echo "$JOB_OUTPUT" | grep -B2 -A2 "route-game-flex.eu" | head -15
else
    echo "   ✗ Domain 'route-game-flex.eu' NOT found in job output"
    echo ""
    echo "   Checking what domain was used:"
    echo "$JOB_OUTPUT" | grep -E "zone_name|domain" | head -10
fi
echo ""

echo "=========================================="
echo "Test Complete"
echo "=========================================="
echo ""
echo "View full job output:"
echo "  ${AWX_HOST}/#/jobs/playbook/${JOB_ID}/output"
echo ""
