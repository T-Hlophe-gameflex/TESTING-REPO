#!/bin/bash
# Deploy the simplified survey to AWX

set -e

AWX_HOST="http://localhost:8081"
AWX_USER="awxcloudflare"
AWX_PASS="Cloudflare@2025"
TEMPLATE_NAME="Cloudflare-Deployment"

echo "=========================================="
echo "Deploying Simplified Survey to AWX"
echo "=========================================="
echo ""

# Generate the survey JSON from template
echo "Generating survey specification..."
cd /Users/thami.hlophe/Documents/TEST/TESTING-REPO

# Create a temporary file with the survey
cat > /tmp/cloudflare_survey.json <<'EOF'
{
  "name": "Cloudflare DNS Management",
  "description": "Deploy and update Cloudflare configurations from Git repository",
  "spec": [
    {
      "question_name": "Ticket Number",
      "question_description": "Enter the ticket/change request number for audit tracking (e.g., JIRA-1234, CHG0012345)",
      "variable": "ticket_number",
      "type": "text",
      "min": 3,
      "max": 50,
      "default": "",
      "required": true
    },
    {
      "question_name": "Platform Selection",
      "question_description": "Select the platform to deploy (L=Production, S=Staging, T=Test, G=Global). Domain is auto-detected from platform configuration.",
      "variable": "platform_id",
      "type": "multiplechoice",
      "choices": ["G000", "G255", "L008", "S009", "T009"],
      "default": "",
      "required": true
    },
    {
      "question_name": "Configuration Scope",
      "question_description": "Select what to deploy: all=Everything, global=Zone+SSL/security, domain=SSL/cache/onion/geolocation, dns=DNS records only, network=Health checks, platform=Firewall, notifications=Alerts",
      "variable": "cloudflare_scope",
      "type": "multiplechoice",
      "choices": ["all", "global", "domain", "dns", "network", "platform", "notifications"],
      "default": "all",
      "required": true
    },
    {
      "question_name": "Dry Run Mode",
      "question_description": "Preview changes without applying them. Recommended for first-time deployments and validating changes.",
      "variable": "cloudflare_dry_run",
      "type": "multiplechoice",
      "choices": ["false", "true"],
      "default": "false",
      "required": true
    }
  ]
}
EOF

echo "✓ Survey specification generated"
echo ""

# Find the job template ID
echo "Looking up job template: ${TEMPLATE_NAME}..."
TEMPLATE_ID=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  "${AWX_HOST}/api/v2/job_templates/?name=${TEMPLATE_NAME}" | \
  jq -r '.results[0].id // empty')

if [ -z "$TEMPLATE_ID" ]; then
    echo "✗ Job template '${TEMPLATE_NAME}' not found"
    echo ""
    echo "Available templates:"
    curl -s -u "${AWX_USER}:${AWX_PASS}" \
      "${AWX_HOST}/api/v2/job_templates/" | \
      jq -r '.results[].name'
    exit 1
fi

echo "✓ Found template ID: ${TEMPLATE_ID}"
echo ""

# Update the survey
echo "Updating survey specification..."
RESPONSE=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/cloudflare_survey.json \
  "${AWX_HOST}/api/v2/job_templates/${TEMPLATE_ID}/survey_spec/")

if echo "$RESPONSE" | jq -e '.name' > /dev/null 2>&1; then
    echo "✓ Survey updated successfully"
else
    echo "✗ Survey update failed"
    echo "$RESPONSE" | jq .
    exit 1
fi
echo ""

# Enable the survey on the template
echo "Enabling survey on template..."
curl -s -u "${AWX_USER}:${AWX_PASS}" \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"survey_enabled": true}' \
  "${AWX_HOST}/api/v2/job_templates/${TEMPLATE_ID}/" > /dev/null

echo "✓ Survey enabled"
echo ""

# Clean up
rm -f /tmp/cloudflare_survey.json

echo "=========================================="
echo "Survey Deployment Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  Template: ${TEMPLATE_NAME}"
echo "  ID: ${TEMPLATE_ID}"
echo "  Questions: 4 (simplified from 6)"
echo ""
echo "Removed questions:"
echo "  ❌ Domain Name (auto-detected from platform)"
echo "  ❌ DNS Action (unused variable)"
echo ""
echo "Test the survey:"
echo "  AWX UI: ${AWX_HOST}"
echo "  Username: ${AWX_USER}"
echo ""
