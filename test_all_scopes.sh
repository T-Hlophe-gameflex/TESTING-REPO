#!/bin/bash

# Test all Cloudflare scopes
# Usage: ./test_all_scopes.sh [platform_id]

set -e

PLATFORM="${1:-S009}"
AWX_URL="http://localhost:8081"
AWX_USER="admin"
AWX_PASS="wEdJbpUfPB5daUlMqWTx1ZPmguwRAMKN"
TEMPLATE_ID="28"
TICKET="TEST-SCOPE-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testing All Cloudflare Scopes${NC}"
echo -e "${BLUE}Platform: ${PLATFORM}${NC}"
echo -e "${BLUE}Ticket: ${TICKET}${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Array of scopes to test
SCOPES=("dns" "domain" "network" "notifications")

# Function to launch and monitor job
test_scope() {
    local SCOPE=$1
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing Scope: ${SCOPE}${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Launch job
    JOB_RESPONSE=$(curl -s -X POST "${AWX_URL}/api/v2/job_templates/${TEMPLATE_ID}/launch/" \
        -u "${AWX_USER}:${AWX_PASS}" \
        -H "Content-Type: application/json" \
        -d "{
            \"extra_vars\": {
                \"ticket_number\": \"${TICKET}\",
                \"cloudflare_region\": \"TEST\",
                \"platform_id\": \"${PLATFORM}\",
                \"cloudflare_scope\": \"${SCOPE}\",
                \"cloudflare_dry_run\": \"On\"
            }
        }")
    
    JOB_ID=$(echo "$JOB_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('job', 'ERROR'))" 2>/dev/null || echo "ERROR")
    
    if [ "$JOB_ID" = "ERROR" ]; then
        echo -e "${RED}✗ Failed to launch job for scope: ${SCOPE}${NC}"
        echo "Response: $JOB_RESPONSE"
        return 1
    fi
    
    echo -e "Job ID: ${JOB_ID}"
    echo -n "Waiting for job to complete"
    
    # Monitor job status
    for i in {1..60}; do
        sleep 2
        echo -n "."
        
        JOB_STATUS=$(curl -s "${AWX_URL}/api/v2/jobs/${JOB_ID}/" -u "${AWX_USER}:${AWX_PASS}")
        STATUS=$(echo "$JOB_STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])" 2>/dev/null || echo "unknown")
        FAILED=$(echo "$JOB_STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin)['failed'])" 2>/dev/null || echo "true")
        
        if [ "$STATUS" = "successful" ]; then
            echo ""
            echo -e "${GREEN}✓ Scope '${SCOPE}' test PASSED (Job ${JOB_ID})${NC}"
            
            # Show summary
            echo -e "\n${BLUE}Summary for ${SCOPE}:${NC}"
            curl -s "${AWX_URL}/api/v2/jobs/${JOB_ID}/stdout/?format=txt" -u "${AWX_USER}:${AWX_PASS}" | \
                grep -A 20 "CLOUDFLARE CONFIGURATION SUMMARY" || echo "No summary found"
            
            return 0
        elif [ "$STATUS" = "failed" ]; then
            echo ""
            echo -e "${RED}✗ Scope '${SCOPE}' test FAILED (Job ${JOB_ID})${NC}"
            
            # Show errors
            echo -e "\n${RED}Error output:${NC}"
            curl -s "${AWX_URL}/api/v2/jobs/${JOB_ID}/stdout/?format=txt" -u "${AWX_USER}:${AWX_PASS}" | \
                tail -50
            
            return 1
        fi
    done
    
    echo ""
    echo -e "${YELLOW}⚠ Job ${JOB_ID} timed out (status: ${STATUS})${NC}"
    return 1
}

# Test each scope
PASSED=0
FAILED=0

for SCOPE in "${SCOPES[@]}"; do
    if test_scope "$SCOPE"; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    sleep 3  # Brief pause between tests
done

# Final summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: ${PASSED}/${#SCOPES[@]}${NC}"
echo -e "${RED}Failed: ${FAILED}/${#SCOPES[@]}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All scope tests passed!${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ Some scope tests failed${NC}\n"
    exit 1
fi
