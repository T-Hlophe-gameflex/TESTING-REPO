#!/bin/bash
# Test Custom SSL Certificate Functionality

set -e

echo "======================================================================"
echo "🔒 Testing Custom SSL Certificate Upload"
echo "======================================================================"

# Check if test certificate file exists
if [ ! -f "test_custom_certificate.yml" ]; then
    echo "❌ Error: test_custom_certificate.yml not found"
    exit 1
fi

# Test 1: Dry-run mode (preview only)
echo ""
echo "Test 1: DRY-RUN MODE (Preview Only)"
echo "----------------------------------------------------------------------"
ansible-playbook cloudflare.yml \
    -i inventories/TEST/hosts \
    --limit cloudflare \
    --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" \
    -e "cloudflare_dry_run=On" \
    -e "selected_platform=G000" \
    -e "cloudflare_domain=route-game-flex.eu" \
    -e "@test_custom_certificate.yml"

echo ""
echo "======================================================================"
echo "Test completed! Review the output above."
echo ""
echo "To actually upload the certificate (NOT RECOMMENDED WITH TEST CERT):"
echo "  1. Get a real SSL certificate from a trusted CA"
echo "  2. Update test_custom_certificate.yml with real certificate data"
echo "  3. Run: ansible-playbook cloudflare.yml -i inventories/TEST/hosts \\"
echo "          --limit cloudflare --tags cloudflare_certificates \\"
echo "          -e 'cloudflare_scope=ssl' -e 'cloudflare_dry_run=Off' \\"
echo "          -e 'selected_platform=G000' -e '@test_custom_certificate.yml'"
echo ""
echo "To get a free SSL certificate, use Let's Encrypt:"
echo "  https://letsencrypt.org/"
echo "======================================================================"
