# Platform Configuration Template - Dynamic DNS Records

This template allows you to define platform DNS records dynamically using variables instead of listing each record individually.

## Benefits:
- Single source of truth for IP addresses
- Easy to update IPs across all records
- Consistent naming convention
- Less repetitive configuration
- Support for both A and CNAME records

## Template Structure:

```yaml
---
# Platform Identity
sysPlatformID: "L016"           # Platform ID (used in hostnames)
platformID: "016"               # Short platform number
platform_id: "L016"             # Full platform ID
platform_number: "016"          # Platform number
platform_type: "production"     # production, test, staging, etc.
env_type: "production"          # Environment type

# IP Address Configuration
ipAddresses:
  main: "5.62.94.161"           # Main IP (root domain, backoffice)
  api: "5.62.94.162"            # API service IP
  gameflex: "5.62.94.163"       # GameFlex platform IP
  webapi: "5.62.94.164"         # Web API service IP
  backoffice: "5.62.94.161"     # Backoffice admin portal IP

# DNS Record Types to Create
dns_record_types:
  # A Records (using ipAddresses)
  - name: "api"
    ip_key: "api"
    comment: "API service"
  
  - name: "gameflex"
    ip_key: "gameflex"
    comment: "GameFlex platform"
  
  - name: "webapi"
    ip_key: "webapi"
    comment: "Web API service"
  
  # Special A Records (no platform suffix)
  - name: "@"
    ip_key: "main"
    comment: "Root domain"
  
  - name: "backoffice"
    ip_key: "backoffice"
    comment: "Backoffice admin portal"
  
  # CNAME Records (using content directly)
  - name: "www"
    type: "CNAME"
    content: "route-game-flex.eu"
    comment: "WWW alias to root domain"

# DNS Settings
dns_ttl: 1
dns_proxied: true

# SSL Settings
ssl_mode: "full_strict"
always_use_https: true

# Platform Domain
platform_domain: "route-game-flex.eu"
location: "TEST"
region: "Test Environment"
```

## How It Works:

### A Records:
- Records with `ip_key` will be A records
- Hostname format: `{name}-{sysPlatformID|lower}` (e.g., `api-l016`)
- Special names (@, www, backoffice) don't get the platform suffix
- IP is pulled from `ipAddresses[ip_key]`

### CNAME Records:
- Records with `type: "CNAME"` and `content` will be CNAME records
- Use `content` field directly for the target
- Example: `www` points to `route-game-flex.eu`

## Generated DNS Records Example:

From the template above, these records are generated:
```
api-l016.route-game-flex.eu         A      5.62.94.162   (proxied)
gameflex-l016.route-game-flex.eu    A      5.62.94.163   (proxied)
webapi-l016.route-game-flex.eu      A      5.62.94.164   (proxied)
@                                     A      5.62.94.161   (proxied)
backoffice.route-game-flex.eu       A      5.62.94.161   (proxied)
www.route-game-flex.eu              CNAME  route-game-flex.eu (proxied)
```

## Migration Steps:

1. Identify all unique IPs in the platform
2. Create `ipAddresses` dictionary with keys (main, api, webapi, gameflex, etc.)
3. List all record types in `dns_record_types` with their ip_key
4. For CNAME records, add `type: "CNAME"` and `content` fields
5. Remove old `cloudflare_dns_records` list
6. Test with `--check` mode

## Variables Reference:

- `sysPlatformID`: Platform ID (L016, T009, S009, etc.)
- `ipAddresses`: Dictionary of IP addresses
- `dns_record_types`: List of records to create
- `dns_ttl`: TTL for all records (default: 1 = automatic)
- `dns_proxied`: Proxy through Cloudflare (default: true)
- `platform_type`: Used in comments (production, test, etc.)
