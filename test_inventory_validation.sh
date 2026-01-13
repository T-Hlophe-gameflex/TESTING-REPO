#!/bin/bash
# TEST Inventory - Quick Test Script
# This script runs various validation checks on the TEST inventory configuration

set -e

INVENTORY_DIR="inventories/TEST"
PLAYBOOK="cloudflare.yml"

echo "=========================================="
echo "TEST Inventory Validation Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check Ansible installation
echo -e "${YELLOW}1. Checking Ansible installation...${NC}"
ansible --version | head -1
echo ""

# 2. Syntax check
echo -e "${YELLOW}2. Running playbook syntax check...${NC}"
ansible-playbook ${PLAYBOOK} -i ${INVENTORY_DIR}/hosts --syntax-check
echo -e "${GREEN}✓ Syntax check passed${NC}"
echo ""

# 3. Verify inventory structure
echo -e "${YELLOW}3. Verifying inventory structure...${NC}"
if [ -d "${INVENTORY_DIR}/group_vars/all/platforms" ]; then
    echo -e "${GREEN}✓ Platform directory exists${NC}"
    echo "Platform structure:"
    tree -L 2 ${INVENTORY_DIR}/group_vars/all/platforms/ 2>/dev/null || find ${INVENTORY_DIR}/group_vars/all/platforms/ -type f
else
    echo "✗ Platform directory not found"
    exit 1
fi
echo ""

# 4. Check platform files
echo -e "${YELLOW}4. Checking platform configuration files...${NC}"
PLATFORMS=("global/G000.yml" "global/G255.yml" "production/L008.yml" "staging/S009.yml" "test/T009.yml")
for platform in "${PLATFORMS[@]}"; do
    if [ -f "${INVENTORY_DIR}/group_vars/all/platforms/${platform}" ]; then
        echo -e "${GREEN}✓${NC} ${platform}"
    else
        echo "✗ ${platform} missing"
    fi
done
echo ""

# 5. Verify inventory loads correctly
echo -e "${YELLOW}5. Testing inventory loading...${NC}"
ansible-inventory -i ${INVENTORY_DIR}/hosts --list > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Inventory loads successfully${NC}"
else
    echo "✗ Inventory loading failed"
    exit 1
fi
echo ""

# 6. Check host variables
echo -e "${YELLOW}6. Verifying platform variables are loaded...${NC}"
if ansible cloudflare -i ${INVENTORY_DIR}/hosts -m debug -a "var=platform_id" | grep -q "T009"; then
    echo -e "${GREEN}✓ Platform ID loaded: T009${NC}"
else
    echo "✗ Platform ID not loaded"
fi

if ansible cloudflare -i ${INVENTORY_DIR}/hosts -m debug -a "var=platform_domain" | grep -q "efutechnologies.co.za"; then
    echo -e "${GREEN}✓ Platform domain loaded: efutechnologies.co.za${NC}"
else
    echo "✗ Platform domain not loaded"
fi

if ansible cloudflare -i ${INVENTORY_DIR}/hosts -m debug -a "var=ipAddresses" | grep -q "gameflex"; then
    echo -e "${GREEN}✓ IP addresses loaded${NC}"
else
    echo "✗ IP addresses not loaded"
fi
echo ""

# 7. List all platforms with their domains
echo -e "${YELLOW}7. Platform Summary:${NC}"
echo "-------------------"
for platform_file in ${INVENTORY_DIR}/group_vars/all/platforms/*/*.yml; do
    if [ -f "$platform_file" ]; then
        platform_id=$(basename "$platform_file" .yml)
        domain=$(grep "platform_domain:" "$platform_file" | awk '{print $2}' | tr -d '"')
        env=$(grep "env_type:" "$platform_file" | awk '{print $2}' | tr -d '"')
        echo "  $platform_id ($env) -> $domain"
    fi
done
echo ""

# 8. Test dry-run commands
echo -e "${YELLOW}8. Example test commands:${NC}"
echo "-------------------"
echo ""
echo "# Test Global Platform G000 (efustryton.co.za):"
echo "ansible-playbook ${PLAYBOOK} -i ${INVENTORY_DIR}/hosts \\"
echo "  -e 'platform_id=G000' \\"
echo "  -e 'cloudflare_zone_name=efustryton.co.za' \\"
echo "  -e 'cloudflare_scope=dns' \\"
echo "  -e 'ticket_number=TEST-001' \\"
echo "  -e 'cloudflare_dry_run=true'"
echo ""
echo "# Test Production Platform L008 (efustryton.co.za):"
echo "ansible-playbook ${PLAYBOOK} -i ${INVENTORY_DIR}/hosts \\"
echo "  -e 'platform_id=L008' \\"
echo "  -e 'cloudflare_zone_name=efustryton.co.za' \\"
echo "  -e 'cloudflare_scope=dns' \\"
echo "  -e 'ticket_number=TEST-002' \\"
echo "  -e 'cloudflare_dry_run=true'"
echo ""
echo "# Test Global Platform G255 (efutechnologies.co.za):"
echo "ansible-playbook ${PLAYBOOK} -i ${INVENTORY_DIR}/hosts \\"
echo "  -e 'platform_id=G255' \\"
echo "  -e 'cloudflare_zone_name=efutechnologies.co.za' \\"
echo "  -e 'cloudflare_scope=dns' \\"
echo "  -e 'ticket_number=TEST-003' \\"
echo "  -e 'cloudflare_dry_run=true'"
echo ""

echo "=========================================="
echo -e "${GREEN}All validation checks completed!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update credentials in ${INVENTORY_DIR}/group_vars/all/credentials.yml"
echo "2. Update IP addresses in platform files when real IPs are available"
echo "3. Run AWX setup: ansible-playbook awx_setup.yml -i ${INVENTORY_DIR}/hosts"
echo "4. Test with dry-run mode before applying real changes"
echo ""
