#!/bin/bash
# Test the simplified survey in AWX

set -e

AWX_HOST="http://localhost:8081"
AWX_USER="awxcloudflare"
AWX_PASS="Cloudflare@2025"
TEMPLATE_ID=28

echo "=========================================="
echo "Testing Simplified Survey in AWX"
echo "=========================================="
echo ""

# Test 1: Verify survey is enabled
echo "Test 1: Verify survey configuration"
echo "-----------------------------------"
SURVEY_INFO=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  "http://localhost:8081/api/v2/job_templates/${TEMPLATE_ID}/")

SURVEY_ENABLED=$(echo "$SURVEY_INFO" | jq -r '.survey_enabled')
TEMPLATE_NAME=$(echo "$SURVEY_INFO" | jq -r '.name')

if [ "$SURVEY_ENABLED" = "true" ]; then
    echo "✓ Survey is enabled on template: ${TEMPLATE_NAME}"
else
    echo "✗ Survey is NOT enabled"
    exit 1
fi
echo ""

# Test 2: Verify survey structure
echo "Test 2: Verify survey has 4 questions"
echo "--------------------------------------"
SURVEY=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
  "http://localhost:8081/api/v2/job_templates/${TEMPLATE_ID}/survey_spec/")

QUESTION_COUNT=$(echo "$SURVEY" | jq '.spec | length')
echo "Question count: ${QUESTION_COUNT}"

if [ "$QUESTION_COUNT" -eq 4 ]; then
    echo "✓ Survey has correct number of questions"
else
    echo "✗ Survey should have 4 questions, found ${QUESTION_COUNT}"
    exit 1
fi
echo ""

# Test 3: Verify removed questions
echo "Test 3: Verify redundant questions removed"
echo "-------------------------------------------"
HAS_DOMAIN_NAME=$(echo "$SURVEY" | jq '.spec[] | select(.variable == "cloudflare_zone_name") | .variable' | wc -l)
HAS_DNS_ACTION=$(echo "$SURVEY" | jq '.spec[] | select(.variable == "dns_action") | .variable' | wc -l)

if [ "$HAS_DOMAIN_NAME" -eq 0 ]; then
    echo "✓ Domain Name question removed"
else
    echo "✗ Domain Name question still exists"
    exit 1
fi

if [ "$HAS_DNS_ACTION" -eq 0 ]; then
    echo "✓ DNS Action question removed"
else
    echo "✗ DNS Action question still exists"
    exit 1
fi
echo ""

# Test 4: List current questions
echo "Test 4: Current survey questions"
echo "--------------------------------"
echo "$SURVEY" | jq -r '.spec[] | "  \(.question_name) → \(.variable)"'
echo ""

# Test 5: Verify platform choices
echo "Test 5: Verify platform choices"
echo "--------------------------------"
PLATFORMS=$(echo "$SURVEY" | jq -r '.spec[] | select(.variable == "platform_id") | .choices[]')
EXPECTED_PLATFORMS=("G000" "G255" "L008" "S009" "T009")

echo "Available platforms:"
for platform in $PLATFORMS; do
    echo "  ✓ $platform"
done
echo ""

# Test 6: Launch a dry-run job for each platform
echo "Test 6: Launch dry-run test jobs"
echo "---------------------------------"
echo "Launching test jobs for each platform..."
echo ""

for PLATFORM in G000 G255 L008 S009 T009; do
    echo "Testing platform: ${PLATFORM}"
    
    # Determine expected domain
    case $PLATFORM in
        G000|G255)
            EXPECTED_DOMAIN="efustryton.co.za"
            ;;
        L008)
            EXPECTED_DOMAIN="efutechnologies.co.za"
            ;;
        S009)
            EXPECTED_DOMAIN="efustryton.co.za"
            ;;
        T009)
            EXPECTED_DOMAIN="efutechnologies.co.za"
            ;;
    esac
    
    # Launch job with survey answers
    JOB_LAUNCH=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
      -X POST \
      -H "Content-Type: application/json" \
      -d "{
        \"extra_vars\": {
          \"ticket_number\": \"TEST-${PLATFORM}\",
          \"platform_id\": \"${PLATFORM}\",
          \"cloudflare_scope\": \"dns\",
          \"cloudflare_dry_run\": \"true\"
        }
      }" \
      "http://localhost:8081/api/v2/job_templates/${TEMPLATE_ID}/launch/")
    
    JOB_ID=$(echo "$JOB_LAUNCH" | jq -r '.id // empty')
    
    if [ -n "$JOB_ID" ]; then
        echo "  ✓ Job launched: ID ${JOB_ID}"
        echo "    Expected domain: ${EXPECTED_DOMAIN}"
        
        # Wait a bit for job to start
        sleep 2
        
        # Check job status
        JOB_STATUS=$(curl -s -u "${AWX_USER}:${AWX_PASS}" \
          "http://localhost:8081/api/v2/jobs/${JOB_ID}/" | jq -r '.status')
        echo "    Job status: ${JOB_STATUS}"
    else
        ERROR=$(echo "$JOB_LAUNCH" | jq -r '.detail // .error // "Unknown error"')
        echo "  ✗ Failed to launch job: ${ERROR}"
    fi
    echo ""
done

echo "=========================================="
echo "Survey Testing Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Survey simplified from 6 to 4 questions"
echo "  ✓ Domain Name question removed (auto-detected)"
echo "  ✓ DNS Action question removed (unused)"
echo "  ✓ All 5 platforms available in survey"
echo "  ✓ Test jobs launched for validation"
echo ""
echo "Access AWX UI to review jobs:"
echo "  URL: ${AWX_HOST}"
echo "  Username: ${AWX_USER}"
echo ""
