# Cloudflare Role

## Overview

Manages Cloudflare DNS, security, performance, and network configurations across multiple domains and platforms using a **minimal configuration approach**. The role dynamically generates DNS records from simple IP address mappings, reducing configuration complexity from 50+ lines to 5-15 lines per platform.

**Key Features:**
- **Dynamic DNS Generation** - Automatically builds DNS records from `ipAddresses` dictionary and global standards
- **Minimal Platform Files** - Only define unique IPs and custom DNS; standard records auto-generated
- **Environment Organization** - Platforms organized by type (production, staging, global, test)
- **Auto-Discovery** - AWX survey automatically discovers platforms from filesystem
- **Flexible Overrides** - Platform-specific `dns_record_types` override global standards when needed

---

## Directory Structure

```
cloudflare/
├── tasks/
│   ├── main.yml           # Task orchestration and workflow control
│   ├── validate.yml       # Configuration validation and API credential checks
│   ├── global.yml         # Zone management and global security settings
│   ├── domain.yml         # SSL, cache, Argo, and DNSSEC configuration
│   ├── network.yml        # Health checks and IP geolocation settings
│   ├── dns.yml            # DNS record creation and updates
│   ├── platform.yml       # Platform-specific firewall rules
│   └── notifications.yml  # Email and webhook alert destinations
```

---

## Inventory Integration

### Inventory Structure

The role loads configuration from multiple inventory locations:

```
inventories/{ENVIRONMENT}/
├── hosts                                    # Inventory hosts file
└── group_vars/
    ├── all/
    │   ├── credentials.yml                 # Cloudflare API credentials
    │   └── cloudflare_survey.yml           # AWX-specific configuration
    └── cloudflare/
        ├── vars/
        │   ├── platform.yml                # Global DNS standards & domain mappings
        │   ├── zone.yml                    # Zone definitions and settings
        │   ├── global.yml                  # Global security/performance settings
        │   ├── domain.yml                  # Domain-level configurations
        │   ├── network.yml                 # Network and health check settings
        │   ├── page_rules.yml              # Global page rules
        │   └── notifications.yml           # Alert destination configurations
        └── platforms/                       # Platform-specific configs (5-15 lines each)
            ├── production/                  # Production platforms (L008-L025, P000-P019)
            │   ├── L008.yml
            │   ├── L012.yml
            │   ├── P000.yml
            │   └── ...
            ├── staging/                     # Staging platforms (S009, S016, S017, S019)
            │   ├── S009.yml
            │   └── ...
            ├── global/                      # Global platforms (G000, G255)
            │   ├── G000.yml
            │   └── G255.yml
            └── test/                        # Test platforms (T009)
                └── T009.yml
```

### Credentials File (all/credentials.yml)

Contains Cloudflare API authentication:

```yaml
cloudflare_api_email: "your-email@example.com"
cloudflare_api_key: "your_global_api_key_here"
cloudflare_account_id: "your_account_id_here"
```

**Security Note:** Always encrypt with Ansible Vault in production.

### AWX Survey Configuration (all/cloudflare_survey.yml)

AWX-specific settings (platforms and domains auto-discovered from filesystem):

```yaml
# AWX Configuration
awx_host: "http://localhost:8081"
awx_organization_override: "Default"
awx_inventory_name: "TEST"
awx_project_name: "TEST-Cloudflare"
awx_template_name: "Cloudflare-Deployment"
awx_playbook_path: "cloudflare.yml"

# Default Values
default_zone: "iforium.com"
default_scope: "dns"
default_dns_action: "deploy"
```

**Note:** The AWX survey setup role auto-discovers platforms from the filesystem and loads domains from `platform.yml`, eliminating the need to maintain duplicate platform/domain lists.

### Platform Configuration (cloudflare/vars/platform.yml)

**Central configuration** for DNS standards and domain mappings:

```yaml
---
# Global Standards for DNS Record Generation
standard_dns_record_types:
  - name: "api"
    ip_key: "api"
    comment: "API service"
    
  - name: "webapi"
    ip_key: "webapi"
    comment: "Web API service"
  
  - name: "gameflex"
    ip_key: "gameflex"
    comment: "GameFlex platform"
    
  - name: "backoffice"
    ip_key: "backoffice"
    comment: "Backoffice admin portal"
  
  - name: "gamemanager"
    ip_key: "gamemanager"
    comment: "Game Manager service"
  
  - name: "bonusplaythrough"
    ip_key: "bonusplaythrough"
    comment: "Bonus Playthrough service"
  
  - name: "operatorwalletapi"
    ip_key: "operatorwalletapi"
    comment: "Operator Wallet API service"

# Domain Definitions
cloudflare_domains:
  - name: "game-flex.eu"
    description: "Game Flex EU - European production gaming"
  - name: "game-flex.us"
    description: "Game Flex US - US production gaming"
  - name: "route-game-flex.eu"
    description: "Route Game Flex EU - IOM production gaming"
  - name: "iforium.com"
    description: "Iforium - Production, staging, and global services"

# Environment to Domain Mapping
environment_domain_map:
  production:
    eu: "game-flex.eu"
    us: "game-flex.us"
    iom: "iforium.com"
    route: "route-game-flex.eu"
  staging: "iforium.com"
  test: "iforium.com"
  global: "iforium.com"

# Defaults
default_dns_ttl: 1
default_dns_proxied: true
default_ssl_mode: "full_strict"
default_always_use_https: true
```

**How it works:**
1. **Dynamic DNS Builder** (in `main.yml`) loops through `standard_dns_record_types`
2. For each record type, it looks up the IP from platform's `ipAddresses` dictionary using `ip_key`
3. If IP exists, it creates DNS record named `{record_name}-{platform_id}` (e.g., `api-l012`)
4. Result: Minimal platform files (5-15 lines) automatically generate full DNS configurations

### Global Settings (cloudflare/vars/global.yml)

Contains zone-wide security and performance settings:

```yaml
cloudflare_global_ssl_settings:
  ssl: "strict"
  min_tls_version: "1.2"
  tls_1_3: "on"
  opportunistic_encryption: "on"
  automatic_https_rewrites: "on"
  always_use_https: "on"

cloudflare_global_security_settings:
  security_level: "medium"
  browser_check: "on"
  challenge_ttl: 1800
  privacy_pass: "on"
  security_header:
    enabled: true
    max_age: 31536000

cloudflare_global_performance_settings:
  cache_level: "aggressive"
  browser_cache_ttl: 14400
  minify:
    css: "on"
    js: "on"
    html: "on"
  brotli: "on"
  early_hints: "on"
  http3: "on"
  zero_rtt: "on"

cloudflare_global_network_settings:
  ipv6: "on"
  websockets: "on"
  pseudo_ipv4: "off"
  ip_geolocation: "on"
```

### Domain Settings (cloudflare/vars/domain.yml)

Domain-level configurations for SSL, caching, and performance:

```yaml
cloudflare_domain_ssl:
  universal_ssl_enabled: true
  ssl_mode: "full_strict"

cloudflare_domain_argo:
  enabled: true
  smart_routing: true
  tiered_caching: true

cloudflare_domain_cache:
  cache_rules:
    - action: set_cache_settings
      action_parameters:
        cache: true
        edge_ttl:
          mode: respect_origin
          default: 7200
        browser_ttl:
          mode: respect_origin

cloudflare_domain_origin:
  true_client_ip_header: "on"
  always_online: "on"
  origin_error_page_pass_thru: "off"
  sort_query_string_for_cache: "on"

cloudflare_domain_dnssec:
  enabled: true

cloudflare_domain_onion_routing:
  enabled: true
```

### Network Settings (cloudflare/vars/network.yml)

Health checks and network monitoring:

```yaml
cloudflare_health_checks:
  - name: "{{ platform_id }}-gameflex-health"
    address: "gameflex-{{ platform_id | lower }}.{{ platform_domain }}"
    check_regions:
      - "WEUR"
      - "EEUR"
    type: "HTTPS"
    port: 443
    method: "GET"
    path: "/health"
    interval: 60
    retries: 2
    timeout: 5
```

### Notification Settings (cloudflare/vars/notifications.yml)

Alert destinations for Cloudflare events:

```yaml
cloudflare_email_destinations:
  - name: "devops-team"
    email: "devops@example.com"
  - name: "qa-team"
    email: "qa@example.com"

cloudflare_webhook_destinations:
  - name: "teams-alerts"
    url: "https://outlook.office.com/webhook/..."
```

### Platform Files (cloudflare/platforms/{env_type}/{PLATFORM_ID}.yml)

**Minimal configuration approach** - Only define unique IPs and custom DNS:

#### Standard Platform (Uses Global DNS Standards)

```yaml
---
platform_id: "L012"
platform_type: "production"
env_type: "production"

ipAddresses:
  api: "5.62.94.177"
  backoffice: "5.62.94.176"
  gameflex: "5.62.94.178"
  webapi: "5.62.94.134"
```

**What happens:**
- Dynamic DNS builder reads `standard_dns_record_types` from `platform.yml`
- For each type, looks up IP from `ipAddresses` using `ip_key`
- Generates: `api-l012`, `backoffice-l012`, `gameflex-l012`, `webapi-l012`
- Result: 4 DNS records from 8 lines of config

#### Platform with Custom DNS (Overrides Global Standards)

```yaml
---
platform_id: "L016"
platform_type: "production"
env_type: "production"

ipAddresses:
  main: "5.62.94.161"
  backoffice: "5.62.94.161"

dns_record_types:
  - name: "@"
    ip_key: "main"
    comment: "Root domain"
  
  - name: "www"
    type: "CNAME"
    content: "route-game-flex.eu"
    comment: "WWW alias to root domain"
  
  - name: "api-l016"
    type: "CNAME"
    content: "api-l016.game-flex.eu"
    comment: "API service via game-flex.eu"
```

**What happens:**
- Platform defines custom `dns_record_types` - overrides global standards
- Creates: `@` (root), `www` CNAME, `api-l016` CNAME
- Result: Full custom DNS control when needed

#### Platform with Mixed Standard + Custom DNS

```yaml
---
platform_id: "S009"
platform_type: "staging"
env_type: "staging"

ipAddresses:
  gameflex: "81.88.167.98"
  backoffice: "81.88.167.90"
  webapi: "81.88.167.90"
  gamemanager: "81.88.167.90"
  bonusplaythrough: "81.88.167.90"

dns_record_types:
  - name: "gameflex"
    type: "CNAME"
    content: "d3q2dc9uhx40b3.cloudfront.net"
    comment: "GameFlex via CloudFront CDN"
  
  - name: "gameflex-origin"
    ip_key: "gameflex"
    comment: "GameFlex origin server"
```

**What happens:**
- Custom `dns_record_types` completely replaces global standards
- Creates: `gameflex` CNAME to CloudFront + `gameflex-origin` A record
- Other IPs in `ipAddresses` not used (because custom DNS defined)
- Result: Flexible per-platform DNS architecture

### Platform Organization by Environment

Platforms organized in subdirectories by type:

- **production/** - L008-L025 (LON/US), P000-P019 (IOM)
- **staging/** - S009, S016, S017, S019
- **global/** - G000, G255
- **test/** - T009

**Loading Strategy:**
```yaml
# In validate.yml - loads first match found
with_first_found:
  - platforms/{{ env_type }}/{{ platform_id }}.yml
  - platforms/production/{{ platform_id }}.yml
  - platforms/staging/{{ platform_id }}.yml
  - platforms/global/{{ platform_id }}.yml
  - platforms/test/{{ platform_id }}.yml
```

### Configuration Loading Sequence

1. **Credentials Loading**
   - Loaded from: `inventories/{ENV}/group_vars/all/credentials.yml`
   - Variables: `cloudflare_api_email`, `cloudflare_api_key`, `cloudflare_account_id`
   - Used for: API authentication

2. **Platform Configuration Loading (NEW ARCHITECTURE)**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/platform.yml`
   - Variables: `standard_dns_record_types`, `cloudflare_domains`, `environment_domain_map`
   - Used for: Global DNS standards and domain mappings
   - **This is the central configuration that enables minimal platform files**

3. **Zone Configuration Loading**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/zone.yml`
   - Variables: `cloudflare_zones`
   - Used for: Zone management and validation

4. **Global Settings Loading**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/global.yml`
   - Variables: SSL, security, performance, network settings
   - Applied to: All zones in the configuration

5. **Domain Settings Loading**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/domain.yml`
   - Variables: SSL, Argo, cache, origin, DNSSEC settings
   - Applied to: Specific zone based on platform domain

6. **Network Settings Loading**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/network.yml`
   - Variables: Health checks, monitoring settings
   - Applied to: Platform-specific endpoints

7. **Notification Settings Loading**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/vars/notifications.yml`
   - Variables: Email and webhook destinations
   - Applied to: Account-level alerting

8. **Platform-Specific Configuration Loading (Dynamic)**
   - Loaded from: `inventories/{ENV}/group_vars/cloudflare/platforms/{env_type}/{platform_id}.yml`
   - Variables: `ipAddresses`, optional `dns_record_types`, platform metadata
   - Applied to: Specific platform when `platform_id` is provided
   - **Dynamic Loading:** Uses `with_first_found` to search multiple environment folders
   - **Minimal Files:** Only 5-15 lines defining IPs and custom DNS (if needed)

9. **Dynamic DNS Record Generation (NEW)**
   - Executed in: `roles/linux/cloudflare/tasks/main.yml`
   - Process:
     1. Loops through `dns_record_types` (platform-specific) OR `standard_dns_record_types` (global)
     2. For each record type, looks up IP from `ipAddresses[ip_key]`
     3. Generates DNS record with name: `{record_name}-{platform_id}` (e.g., `api-l012`)
     4. Adds comment with platform and environment details
   - Result: Full DNS configuration auto-generated from minimal input

### Variable Precedence

Configuration variables follow Ansible's standard precedence order:

1. Extra vars (command line `-e`)
2. Task vars (in playbook)
3. **Platform-specific `dns_record_types`** (overrides global DNS standards)
4. **Platform-specific `ipAddresses`** (provides IPs for DNS generation)
5. Group vars cloudflare/vars/platform.yml (`standard_dns_record_types`, `cloudflare_domains`)
6. Group vars cloudflare/vars/*.yml (global, domain, network settings)
7. Host vars
8. Inventory defaults
9. Role defaults (inline in tasks)

**Key Override Behavior:**
- If platform defines `dns_record_types`, it **completely replaces** `standard_dns_record_types`
- If platform doesn't define `dns_record_types`, uses global `standard_dns_record_types`
- `ipAddresses` dictionary is always platform-specific (no global default)

**Example:**
```yaml
# platform.yml (global)
standard_dns_record_types:
  - name: "api"
    ip_key: "api"

# L012.yml (uses global standards)
ipAddresses:
  api: "5.62.94.177"
# Result: Creates api-l012 DNS record

# L016.yml (overrides with custom DNS)
ipAddresses:
  main: "5.62.94.161"
dns_record_types:
  - name: "@"
    ip_key: "main"
# Result: Creates @ (root) DNS record, ignores global standards
```

---

## Configuration Scopes

The role supports granular execution through scopes:

- `all` - Complete configuration across all settings
- `dns` - DNS records only
- `domain` - Domain-level settings (SSL, cache, Argo)
- `global` - Global zone settings and security headers
- `network` - Network configuration and health checks
- `platform` - Platform-specific firewall rules
- `notifications` - Alert destinations and webhooks

---

## Execution Flow

### 0. Dynamic DNS Record Generation (NEW - main.yml, before validate)

**Purpose:** Generate DNS records from platform variables before validation

**Steps:**
- Check if `platform_id` is defined
- Determine record source: platform's `dns_record_types` OR global `standard_dns_record_types`
- Loop through each record type:
  - **For A records:** Look up IP from `ipAddresses[ip_key]`
  - If IP exists, create record with name: `{record_name}-{platform_id}` (except @, www, backoffice)
  - Add platform and environment details to comment
  - **For CNAME records:** Use content as-is, add to records list
- Set `cloudflare_dns_records` fact with generated records
- Result: Full DNS configuration ready for deployment

**Example Flow:**
```yaml
# Input (platform file)
ipAddresses:
  api: "5.62.94.177"
  gameflex: "5.62.94.178"

# Processing (dynamic builder)
standard_dns_record_types:
  - name: "api", ip_key: "api"      → ipAddresses["api"] = "5.62.94.177" ✓
  - name: "gameflex", ip_key: "gameflex" → ipAddresses["gameflex"] = "5.62.94.178" ✓
  - name: "webapi", ip_key: "webapi"  → ipAddresses["webapi"] = NOT FOUND ✗ (skipped)

# Output (generated DNS records)
cloudflare_dns_records:
  - name: "api-l012", type: "A", content: "5.62.94.177", comment: "L012 - API service (production environment)"
  - name: "gameflex-l012", type: "A", content: "5.62.94.178", comment: "L012 - GameFlex platform (production environment)"
```

**Inventory Usage:**
- Reads: `ipAddresses` from platform file (platforms/{env_type}/{platform_id}.yml)
- Reads: `dns_record_types` from platform file OR `standard_dns_record_types` from platform.yml
- Uses: `platform_id`, `platform_type`, `env_type` for naming and comments

### 1. Validation Phase (validate.yml)

**Purpose:** Validate configuration and prepare execution environment

**Steps:**
- Build zone list from survey variable or defaults
- Set default zone from first zone in list
- Calculate `effective_zone_name` (prioritizes platform_domain over defaults)
- Display execution banner with domain, platform, scope, and ticket
- Validate required variables exist
- Set configuration directory path
- Load zone configuration from inventory
- Load global configuration from inventory
- Load domain configuration from inventory
- Load network configuration from inventory
- Load notification configuration from inventory
- **Dynamically load platform-specific configuration** using `with_first_found`:
  - Searches: platforms/{env_type}/{platform_id}.yml
  - Falls back to: production, staging, global, test subdirectories
  - Loads: `ipAddresses`, optional `dns_record_types`, metadata
- Verify platform configuration loaded successfully (checks `ipAddresses` exists)
- Validate API credentials present
- Test API connectivity with token verification
- Verify account access
- Display validation summary

**Inventory Usage:**
- Reads: `cloudflare_api_email`, `cloudflare_api_key`, `cloudflare_account_id` from credentials.yml
- Reads: `cloudflare_zones` from zone.yml (optional)
- Reads: Global/domain/network/notification settings from respective files
- Reads: Platform config from platforms/{env_type}/{platform_id}.yml (dynamic)
- Reads: `standard_dns_record_types` from platform.yml (used by DNS builder)

**Variables Set:**
- `effective_zone_name` - Computed zone for DNS operations
- `cloudflare_config_dir` - Path to inventory cloudflare configs
- All configuration variables loaded from inventory files

### 2. Global Configuration (global.yml)

**Purpose:** Manage zones and apply global settings

**Steps:**
- Display global configuration banner
- Check if zone creation is allowed
- Fetch existing zones from Cloudflare API
- Initialize zone ID mapping dictionary
- Build zone ID mapping from API results
- Set primary zone facts for execution
- Display zone mappings for verification
- Sanitize performance settings (remove immutable keys)
- Apply global SSL settings to all zones
- Apply global security settings to all zones
- Apply global performance settings to all zones
- Apply global network settings to all zones
- Log any failed settings (informational only)
- Display global configuration summary

**Inventory Usage:**
- Reads: `cloudflare_zones` from zone.yml
- Reads: `cloudflare_global_ssl_settings` from global.yml
- Reads: `cloudflare_global_security_settings` from global.yml
- Reads: `cloudflare_global_performance_settings` from global.yml
- Reads: `cloudflare_global_network_settings` from global.yml

**API Calls:**
- GET /zones?name={zone_name} - Fetch zone details
- PATCH /zones/{zone_id}/settings/{setting} - Update zone settings

### 3. Domain Configuration (domain.yml)

**Purpose:** Configure domain-specific settings

**Steps:**
- Display domain configuration banner
- Check Universal SSL status
- Enable Universal SSL if not enabled
- Configure Argo Smart Routing
- Configure Argo Tiered Caching
- Apply cache rules via Rulesets API
- Configure origin server settings
- Enable DNSSEC
- Enable Onion Routing (Tor support)
- Display Onion Routing status
- Display DNSSEC details
- Purge cache patterns if specified
- Display domain configuration summary

**Inventory Usage:**
- Reads: `cloudflare_domain_ssl` from domain.yml
- Reads: `cloudflare_domain_argo` from domain.yml
- Reads: `cloudflare_domain_cache` from domain.yml
- Reads: `cloudflare_domain_origin` from domain.yml
- Reads: `cloudflare_domain_dnssec` from domain.yml
- Reads: `cloudflare_domain_onion_routing` from domain.yml

**API Calls:**
- GET /zones/{zone_id}/ssl/universal/settings
- PATCH /zones/{zone_id}/ssl/universal/settings
- PATCH /zones/{zone_id}/argo/smart_routing
- PATCH /zones/{zone_id}/argo/tiered_caching
- PUT /zones/{zone_id}/rulesets/phases/http_request_cache_settings/entrypoint
- PATCH /zones/{zone_id}/settings/{setting}
- PATCH /zones/{zone_id}/dnssec
- POST /zones/{zone_id}/purge_cache

### 4. Network Configuration (network.yml)

**Purpose:** Configure health checks and network monitoring

**Steps:**
- Display network configuration banner
- Create health check monitors for platform endpoints
- Enable IP Geolocation headers
- Display IP Geolocation status
- Display network configuration summary

**Inventory Usage:**
- Reads: `cloudflare_health_checks` from network.yml
- Uses: `platform_id`, `platform_domain` from platform file

**API Calls:**
- POST /zones/{zone_id}/healthchecks
- PATCH /zones/{zone_id}/settings/ip_geolocation

### 5. DNS Management (dns.yml)

**Purpose:** Create and update DNS records (generated dynamically from platform data)

**Steps:**
- Set target zone name (uses `platform_domain` if available, otherwise `effective_zone_name`)
- Display DNS configuration banner with zone and record count
- Fetch zone ID from Cloudflare API
- Set zone_id fact for subsequent operations
- Loop through `cloudflare_dns_records` (generated by dynamic DNS builder):
  - Check if each DNS record exists
  - Create new records if not found
  - Update existing records if content changed
- Display DNS configuration summary with record count

**Inventory Usage:**
- Reads: `platform_domain` from platform file (overrides zone selection)
- Uses: `cloudflare_dns_records` (generated from `ipAddresses` + `standard_dns_record_types`)
- Uses: `effective_zone_name` as fallback if platform_domain not set

**API Calls:**
- GET /zones?name={zone_name} - Get zone ID
- GET /zones/{zone_id}/dns_records?name={record_name} - Check existing records
- POST /zones/{zone_id}/dns_records - Create new records
- PUT /zones/{zone_id}/dns_records/{record_id} - Update existing records

**DNS Record Format (Generated):**
```yaml
cloudflare_dns_records:
  - name: "api-l012"              # Auto-generated: {name}-{platform_id}
    type: "A"                     # From record type definition
    content: "5.62.94.177"        # From ipAddresses[ip_key]
    ttl: 1                        # From defaults or platform override
    proxied: true                 # From defaults or platform override
    comment: "L012 - API service (production environment)"  # Auto-generated
```

**Dynamic Generation Benefits:**
- **Consistency:** All platforms use same naming convention
- **Minimal Config:** Only define IPs, DNS records auto-generated
- **Flexibility:** Override with custom `dns_record_types` when needed
- **Documentation:** Comments automatically include platform and environment details

### 6. Platform Configuration (platform.yml)

**Purpose:** Apply platform-specific firewall rules

**Steps:**
- Display platform configuration banner
- Skip if no platform_id provided
- Create platform-specific firewall rules
- Display platform configuration summary

**Inventory Usage:**
- Uses: `platform_id` from command line or survey
- May use: Additional platform metadata from platform file

**API Calls:**
- POST /zones/{zone_id}/firewall/rules

### 7. Notifications (notifications.yml)

**Purpose:** Configure alert destinations

**Steps:**
- Display notification configuration banner
- Create email alert destinations
- Create webhook alert destinations
- Display notification configuration summary

**Inventory Usage:**
- Reads: `cloudflare_email_destinations` from notifications.yml
- Reads: `cloudflare_webhook_destinations` from notifications.yml

**API Calls:**
- POST /accounts/{account_id}/alerting/v3/destinations/email
- POST /accounts/{account_id}/alerting/v3/destinations/webhooks

### 8. Completion Summary (main.yml)

**Purpose:** Display final execution summary

**Steps:**
- Show configuration completion banner
- Display domain, platform, scope, and ticket details
- Show what was configured based on scope
- Provide Cloudflare dashboard link for verification

---

## Required Variables

### API Credentials
- `cloudflare_api_email` - Cloudflare account email (from credentials.yml)
- `cloudflare_api_key` - Cloudflare Global API key (from credentials.yml)
- `cloudflare_account_id` - Cloudflare account ID (from credentials.yml)

### Execution Parameters
- `ticket_number` - Change management ticket reference (required)
- `platform_id` - Platform identifier (optional, required for DNS scope)
- `cloudflare_scope` - Configuration scope (default: all)

### From Platform Configuration (platform.yml)
- `standard_dns_record_types` - Global DNS standards with `ip_key` mappings
- `cloudflare_domains` - Domain definitions for AWX survey
- `environment_domain_map` - Environment to domain mapping

### From Platform Files
- `ipAddresses` - Dictionary of service IPs (e.g., `{api: "x.x.x.x", gameflex: "y.y.y.y"}`)
- `dns_record_types` - Optional override of global DNS standards
- `platform_type` / `env_type` - Platform classification (production, staging, test, global)

---

## Optional Variables

### Platform File Overrides
- `dns_record_types` - Override global `standard_dns_record_types` for custom DNS
- `platform_domain` - Override automatic domain selection
- `dns_ttl` - Override default TTL for all records
- `dns_proxied` - Override default proxy setting

### API Configuration (inline defaults in tasks)
- `cloudflare_api_timeout` - API request timeout (default: 30)
- `cloudflare_api_retries` - Retry attempts (default: 3)
- `cloudflare_api_delay` - Retry delay (default: 2)
- `cloudflare_validate_certs` - SSL validation (default: true)

### Zone Management
- `effective_zone_name` - Computed zone name (set by validate.yml)
- `cloudflare_zone_ids` - Zone ID mappings (built by global.yml)
- `cloudflare_zones` - Optional explicit zone list (auto-built from survey if not provided)

---

## Usage Examples

### Configure DNS for specific platform (Most Common)
```bash
ansible-playbook cloudflare.yml \
  -i inventories/IOM/hosts \
  -e "platform_id=P016" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=JIRA-1234"
```

**What happens:**
1. Loads credentials from `inventories/IOM/group_vars/all/credentials.yml`
2. Loads `standard_dns_record_types` from `inventories/IOM/group_vars/cloudflare/vars/platform.yml`
3. Dynamically loads `inventories/IOM/group_vars/cloudflare/platforms/production/P016.yml`
4. **Dynamic DNS Builder** generates DNS records:
   - Loops through `standard_dns_record_types`
   - For each type, looks up IP from P016's `ipAddresses` dictionary
   - Creates record: `{name}-p016` with IP from `ipAddresses[ip_key]`
5. Creates/updates generated DNS records in Cloudflare
6. Result: Full DNS configuration from minimal 5-15 line platform file

### Configure new platform with minimal setup
```bash
# 1. Create minimal platform file (8 lines)
cat > inventories/IOM/group_vars/cloudflare/platforms/production/P020.yml <<EOF
---
platform_id: "P020"
platform_type: "production"
env_type: "production"

ipAddresses:
  api: "195.68.198.60"
  gameflex: "195.68.198.61"
  webapi: "195.68.198.62"
EOF

# 2. Deploy DNS records (auto-generated from global standards)
ansible-playbook cloudflare.yml \
  -i inventories/IOM/hosts \
  -e "platform_id=P020" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=JIRA-1234"

# Result: Creates api-p020, gameflex-p020, webapi-p020 DNS records
```

### Platform with custom DNS (override global standards)
```bash
# 1. Create platform with custom dns_record_types
cat > inventories/IOM/group_vars/cloudflare/platforms/production/L021.yml <<EOF
---
platform_id: "L021"
platform_type: "production"
env_type: "production"

ipAddresses:
  main: "5.62.94.200"

dns_record_types:
  - name: "@"
    ip_key: "main"
    comment: "Root domain"
  - name: "www"
    type: "CNAME"
    content: "route-game-flex.eu"
    comment: "WWW redirect"
EOF

# 2. Deploy (uses custom DNS instead of global standards)
ansible-playbook cloudflare.yml \
  -i inventories/LON/hosts \
  -e "platform_id=L021" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=JIRA-1234"

# Result: Creates @ and www records only (ignores global standards)
```

### Apply all configurations to platform
```bash
ansible-playbook cloudflare.yml \
  -i inventories/TEST/hosts \
  -e "platform_id=L008" \
  -e "cloudflare_scope=all" \
  -e "ticket_number=JIRA-1234"
```

**What happens:**
1. Loads all configuration files from TEST inventory
2. Loads platform L008 configuration
3. Applies global settings from global.yml to all zones
4. Applies domain settings from domain.yml to game-flex.eu
5. Creates DNS records from L008.yml
6. Configures health checks using L008 platform metadata

### Update global security settings only
```bash
ansible-playbook cloudflare.yml \
  -i inventories/TEST/hosts \
  -e "cloudflare_scope=global" \
  -e "ticket_number=JIRA-1234"
```

**What happens:**
1. Loads global.yml security settings
2. Applies to all zones defined in zone.yml
3. Skips DNS, domain, network, platform, and notification tasks

### Dry-run validation
```bash
ansible-playbook cloudflare.yml \
  -i inventories/TEST/hosts \
  --check \
  -e "platform_id=L008" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=JIRA-1234"
```

**What happens:**
1. Loads configuration from inventory
2. **Runs dynamic DNS builder** to generate records from `ipAddresses`
3. Validates structure and variable interpolation
4. Shows what DNS records would be created without making actual changes
5. Tests API connectivity (bypasses check mode for validation)

---

## Tags

### Functional Tags
- `cloudflare` - All Cloudflare tasks
- `cloudflare_configuration` - Configuration tasks
- `cloudflare_dns` - DNS record management
- `cloudflare_global` - Global zone settings
- `cloudflare_domain` - Domain-level settings
- `cloudflare_network` - Network configuration
- `cloudflare_platform` - Platform-specific rules
- `cloudflare_notifications` - Alert configuration

### Granular Tags
- `cloudflare_zone_management` - Zone creation and ID mapping
- `cloudflare_zone_settings` - Zone setting modifications
- `cloudflare_ssl` - SSL/TLS configuration
- `cloudflare_argo` - Argo Smart Routing and Tiered Caching
- `cloudflare_cache` - Cache configuration and rules
- `cloudflare_dnssec` - DNSSEC management
- `cloudflare_firewall` - Firewall rule creation
- `cloudflare_health_checks` - Health check monitors
- `always` - Completion summary (runs always)

---

## Best Practices

### Platform Configuration (NEW APPROACH)
- **Minimal Files:** Only define `ipAddresses` and custom DNS (if needed)
- **Use Global Standards:** Let `standard_dns_record_types` auto-generate common DNS records
- **Override When Needed:** Define platform-specific `dns_record_types` for special cases
- **Consistent Naming:** Platform ID automatically appended to record names (e.g., `api-l012`)
- **Environment Organization:** Place platforms in correct subdirectory (production, staging, global, test)
- **IP Dictionary:** Use clear keys matching `ip_key` in DNS standards (api, gameflex, webapi, etc.)

### Inventory Management
- Keep credentials encrypted with Ansible Vault
- Separate configuration by environment (TEST, IOM, LON)
- Centralize DNS standards in `platform.yml` - avoid duplication
- Use `environment_domain_map` for automatic domain selection
- Version control all inventory changes
- Document custom DNS in platform file comments

### DNS Record Generation
- Rely on dynamic builder for standard platforms (reduces errors)
- Only define custom `dns_record_types` when truly necessary
- Keep `ipAddresses` keys consistent across platforms
- Use descriptive comments in `standard_dns_record_types`
- Test new platforms in TEST environment first

### Adding New Platforms
```bash
# 1. Create minimal file in correct subdirectory
cat > inventories/IOM/group_vars/cloudflare/platforms/production/P025.yml <<EOF
---
platform_id: "P025"
platform_type: "production"
env_type: "production"

ipAddresses:
  api: "REPLACE_WITH_API_IP"
  gameflex: "REPLACE_WITH_GAMEFLEX_IP"
  webapi: "REPLACE_WITH_WEBAPI_IP"
EOF

# 2. Test in check mode
ansible-playbook cloudflare.yml --check -i inventories/IOM/hosts \
  -e "platform_id=P025" -e "cloudflare_scope=dns" -e "ticket_number=TEST-123"

# 3. Deploy for real
ansible-playbook cloudflare.yml -i inventories/IOM/hosts \
  -e "platform_id=P025" -e "cloudflare_scope=dns" -e "ticket_number=JIRA-1234"

# 4. AWX survey auto-discovers new platform (no manual update needed)
```

### Security
- Store API credentials in Ansible Vault
- Use separate API tokens per environment
- Enable DNSSEC for production domains
- Use proxied=true for web services (DDoS protection)
- Rotate API tokens regularly

### Performance
- Enable Argo Smart Routing for optimal routing
- Use Tiered Caching to reduce origin load
- Set appropriate TTL values based on change frequency
- Enable HTTP/3 and Zero RTT for faster connections
- Use proxied records for cacheable content

### Change Management
- Always provide ticket_number for audit trail
- Use check mode for validation before execution
- Test in TEST environment first
- Use specific scopes to limit blast radius
- Document changes in platform file comments

---

## Error Handling

### Validation Failures
- **Missing API credentials:** Playbook fails immediately at validation phase
- **Invalid platform ID:** Playbook fails when loading platform configuration with `with_first_found` error
- **Missing ipAddresses:** Validation fails if `ipAddresses` dictionary not defined in platform file
- **Missing ticket number:** Playbook fails at variable validation
- **Solution:** Ensure all required variables are defined in inventory or passed via `-e`

### API Failures
- **Network timeout:** Automatic retry with exponential backoff (3 attempts)
- **Rate limiting:** Delayed retry with configurable delay (default 2s)
- **Premium features:** Error code 1004 ignored (logged but doesn't stop execution)
- **Authentication errors:** Playbook fails immediately
- **Solution:** Check API key permissions (need Zone:DNS:Edit at minimum) and account access

### Platform Loading Errors
- **Platform file not found:** `with_first_found` searches all environment subdirectories, fails if not in any
- **Empty ipAddresses:** Validation fails with "ipAddresses dictionary must be defined"
- **Missing ip_key:** DNS record generation silently skips (IP value empty string check)
- **Solution:** 
  - Verify platform file exists in correct subdirectory (production, staging, global, test)
  - Ensure `ipAddresses` dictionary defined with appropriate keys
  - Check `ip_key` in DNS standards matches keys in `ipAddresses`

### DNS Generation Issues
- **No records created:** Check if `ipAddresses` keys match `ip_key` in `standard_dns_record_types`
- **Wrong record names:** Verify `platform_id` is lowercase (auto-converted in template)
- **Missing standard records:** Check if platform defines custom `dns_record_types` (overrides global)
- **Solution:**
  - Compare `ipAddresses` keys with `ip_key` values in platform.yml
  - Remove platform-specific `dns_record_types` to use global standards
  - Check dynamic DNS builder output in task results

### Check Mode Support
- All URI tasks bypass check mode (`check_mode: no`) for proper validation
- Shows what would be changed without making actual API calls
- Validates configuration structure and variable interpolation
- Tests API connectivity even in check mode

---

## Troubleshooting

### Configuration Not Loading
**Symptoms:** Variables undefined or using defaults
**Causes:**
- Incorrect inventory path
- Missing configuration files
- Typos in variable names
**Solutions:**
- Verify inventory path with `ansible-inventory --list -i inventories/IOM/hosts`
- Check files exist: `ls inventories/{ENV}/group_vars/cloudflare/vars/`
- Review playbook output for file loading messages
- Verify platform.yml contains `standard_dns_record_types`

### Dynamic DNS Not Generating Records
**Symptoms:** Tasks skipped, no DNS records created, `cloudflare_dns_records` empty
**Causes:**
- `ipAddresses` dictionary missing or empty
- Keys in `ipAddresses` don't match `ip_key` in DNS standards
- Platform defines custom `dns_record_types` (overrides global)
- `platform_id` not defined
**Solutions:**
- Check platform file has `ipAddresses` dictionary with entries
- Compare `ipAddresses` keys with `ip_key` values in `standard_dns_record_types`:
  ```bash
  # View global DNS standards
  grep -A 2 "ip_key:" inventories/TEST/group_vars/cloudflare/vars/platform.yml
  
  # View platform IPs
  grep -A 5 "ipAddresses:" inventories/TEST/group_vars/cloudflare/platforms/production/L012.yml
  ```
- Remove custom `dns_record_types` from platform file to use global standards
- Ensure `-e "platform_id=XXX"` passed to playbook

### Wrong Platform Configuration Loaded
**Symptoms:** DNS records from different platform
**Causes:**
- Platform file in wrong subdirectory
- `env_type` not matching subdirectory name
- Multiple files with same name in different directories
**Solutions:**
- Verify file location matches `env_type`:
  ```bash
  # Production platforms should be in:
  inventories/{ENV}/group_vars/cloudflare/platforms/production/
  
  # Staging platforms:
  inventories/{ENV}/group_vars/cloudflare/platforms/staging/
  ```
- Check `with_first_found` loading order in validate.yml
- Use unique platform IDs across all environments

### DNS Records Not Created
**Symptoms:** Tasks skipped or records not appearing in Cloudflare
**Causes:**
- Wrong zone selected
- platform_domain not matching actual zone
- DNS records list empty
**Solutions:**
- Check `effective_zone_name` in task output
- Verify `platform_domain` in platform file matches zone in zone.yml
- Confirm `cloudflare_dns_records` has entries in platform file

### API Authentication Errors
**Symptoms:** 401 Unauthorized or 403 Forbidden
**Causes:**
- Invalid API token
- Token lacks required permissions
- Wrong account ID
**Solutions:**
- Verify token in Cloudflare dashboard (My Profile > API Tokens)
- Ensure token has Zone:Edit and DNS:Edit permissions
- Confirm account ID matches Cloudflare account

### Zone Not Found
**Symptoms:** Zone ID not set, API returns empty results
**Causes:**
- Zone doesn't exist in Cloudflare
- Zone name typo in configuration
- API token lacks zone access
**Solutions:**
- Check zone exists in Cloudflare dashboard
- Verify zone name in zone.yml matches exactly
- Ensure API token has access to the zone

---

## Related Documentation

- AWX Survey Setup Role: `roles/linux/awx_survey_setup/README.md`
- Main README: `/README.md`
- AWX Setup Guide: `/README-awx-k3d.md`
- Validation Framework: `/README-validation.md`
