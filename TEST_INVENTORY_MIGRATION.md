# TEST Inventory Migration - Summary

## Overview
The TEST inventory has been restructured to follow the same pattern as the IOM inventory, with support for two South African domains:
- **efustryton.co.za** - Primary domain
- **efutechnologies.co.za** - Secondary domain

## Changes Made

### 1. Inventory Structure
Updated TEST inventory structure to match IOM:

```
inventories/TEST/
└── group_vars/
    ├── all/
    │   ├── cloudflare.yml          # Environment settings
    │   ├── credentials.yml          # Encrypted credentials
    │   └── platforms/               # Platform-specific configs
    │       ├── global/
    │       │   ├── G000.yml        # efustryton.co.za
    │       │   └── G255.yml        # efutechnologies.co.za
    │       ├── production/
    │       │   └── L008.yml        # Production platform
    │       ├── staging/
    │       │   └── S009.yml        # Staging platform
    │       └── test/
    │           └── T009.yml        # Test platform
    └── cloudflare/
        └── vars/
            ├── domain.yml           # SSL, cache, Argo settings
            ├── global.yml           # Global Cloudflare settings
            ├── network.yml          # Health checks, load balancing
            ├── notifications.yml    # Alert configurations
            ├── page_rules.yml       # Page rules (if any)
            └── zone.yml            # Zone definitions
```

### 2. Platform Configurations

#### Global Platforms
- **G000** (efustryton.co.za)
  - IP: 10.0.0.10
  
- **G255** (efutechnologies.co.za)
  - IP: 10.0.0.255

#### Production Platform
- **L008** (efustryton.co.za)
  - gameflex: 10.1.8.10
  - backoffice: 10.1.8.11
  - webapi: 10.1.8.12
  - gamemanager: 10.1.8.13

#### Staging Platform
- **S009** (efustryton.co.za)
  - gameflex: 10.2.9.10
  - backoffice: 10.2.9.11
  - webapi: 10.2.9.12
  - gamemanager: 10.2.9.13

#### Test Platform
- **T009** (efutechnologies.co.za)
  - gameflex: 10.3.9.10
  - backoffice: 10.3.9.11
  - webapi: 10.3.9.12
  - gamemanager: 10.3.9.13

### 3. Environment Settings

Updated `inventories/TEST/group_vars/all/cloudflare.yml`:
- **Production**: SSL full_strict, always HTTPS, proxied
- **Staging**: SSL full_strict, always HTTPS, proxied
- **Test**: SSL off, no forced HTTPS, proxied
- **Global**: SSL full_strict, always HTTPS, proxied

### 4. Domain Configurations

Updated `inventories/TEST/group_vars/cloudflare/vars/zone.yml`:
- Added efustryton.co.za zone
- Added efutechnologies.co.za zone
- Set default zone to efustryton.co.za

### 5. AWX Survey Setup

Updated `roles/linux/cloudflare/awx_survey_setup/defaults/main.yml`:
- Replaced old domains with new South African domains
- Updated platform list to include only TEST platforms:
  - L008 (Production)
  - S009 (Staging)
  - T009 (Test)
  - G000, G255 (Global)
- Set default zone to efustryton.co.za

### 6. Role Updates

Updated `roles/linux/cloudflare/cloudflare/tasks/validate.yml`:
- Added support for `production` and `test` platform directories
- Maintains backward compatibility with IOM structure

## Testing the Configuration

### 1. Syntax Check
```bash
ansible-playbook cloudflare.yml -i inventories/TEST/hosts --syntax-check
```

### 2. Dry Run (Check Mode)
```bash
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
  -e "platform_id=G000" \
  -e "cloudflare_zone_name=efustryton.co.za" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=TEST-001" \
  --check
```

### 3. View Inventory
```bash
ansible-inventory -i inventories/TEST/hosts --list --yaml
```

### 4. Test Specific Platform
```bash
# Test Global Platform G000
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
  -e "platform_id=G000" \
  -e "cloudflare_zone_name=efustryton.co.za" \
  -e "cloudflare_scope=all" \
  -e "ticket_number=TEST-001" \
  -e "cloudflare_dry_run=true"

# Test Production Platform L008
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
  -e "platform_id=L008" \
  -e "cloudflare_zone_name=efustryton.co.za" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=TEST-002" \
  -e "cloudflare_dry_run=true"
```

## AWX Integration

The AWX survey has been updated and will present:

### Survey Questions:
1. **Ticket Number**: For audit tracking
2. **Domain Name**: 
   - efustryton.co.za
   - efutechnologies.co.za
3. **DNS Action**: deploy or update
4. **Platform Selection**:
   - L008 (Production)
   - S009 (Staging)
   - T009 (Test)
   - G000, G255 (Global)
5. **Configuration Scope**: all, global, domain, dns, network, platform, notifications
6. **Dry Run Mode**: true or false

### To Deploy AWX Survey:
```bash
ansible-playbook awx_setup.yml -i inventories/TEST/hosts
```

## Next Steps

1. **Update Credentials**: Ensure the following environment variables are set or update `inventories/TEST/group_vars/all/credentials.yml`:
   - CLOUDFLARE_API_EMAIL
   - CLOUDFLARE_API_KEY
   - CLOUDFLARE_ACCOUNT_ID
   - AWX_USERNAME
   - AWX_PASSWORD

2. **Verify DNS Records**: Update the actual IP addresses in platform files when you have the real infrastructure IPs

3. **Test Incrementally**:
   - Start with dry-run mode
   - Test one platform at a time
   - Test one scope at a time (dns first, then expand)

4. **Monitor Cloudflare**:
   - Check Cloudflare dashboard after each deployment
   - Verify DNS records are created correctly
   - Validate SSL settings

## File Locations

- **Inventory**: `inventories/TEST/`
- **Platform Configs**: `inventories/TEST/group_vars/all/platforms/`
- **Cloudflare Role**: `roles/linux/cloudflare/cloudflare/`
- **AWX Survey**: `roles/linux/cloudflare/awx_survey_setup/`
- **Main Playbook**: `cloudflare.yml`
- **AWX Setup**: `awx_setup.yml`

## Important Notes

- All dummy IP addresses use private IP ranges (10.x.x.x)
- Replace these with actual public IPs when deploying to real infrastructure
- The structure now matches IOM inventory for consistency
- Credentials file should be encrypted with ansible-vault
- Always test with dry-run mode first before applying changes
