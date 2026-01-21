# Platform Configuration Template - Dynamic DNS Records

This template allows you to define platform DNS records dynamically using variables instead of listing each record individually.

## Platform Type Naming Convention:
- **L** = Live/Production (L008, L016, L021, etc.)
- **P** = Preprod/Pre-production (P000, P009, P016, P019)
- **S** = Staging (S009, S016, S017, S019)
- **T** = Trunk/Development (T009)

## Directory Structure:
```
inventories/{INVENTORY}/group_vars/all/platforms/
├── live/      # Live/Production platforms (L*)
├── preprod/   # Pre-production platforms (P*)
├── staging/   # Staging platforms (S*)
└── trunk/     # Trunk/Development platforms (T*)
```

**Note**: LON inventory uses `platform/` (singular) instead of `platforms/` (plural)

## Inventory Responsibilities:

### IOM Inventory
- **Platforms**: Preprod (P*), Staging (S*), Trunk (T*)
- **Domain**: iforium.com
- **Location**: Isle of Man

### LON Inventory
- **Platforms**: Live (L*) ONLY
- **Domain**: game-flex.eu
- **Location**: London

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
platform_id: "L016"             # Full platform ID (must match filename)
platform_type: "live"           # live, preprod, staging, or trunk
env_type: "live"                # Same as platform_type
platform_domain: "game-flex.eu" # Domain for this platform (game-flex.eu or iforium.com)

# IP Address Configuration
ipAddresses:
  api: "5.62.94.240"            # API service IP
  gameflex: "5.62.94.245"       # GameFlex platform IP
  webapi: "5.62.94.241"         # Web API service IP
  backoffice: "5.62.94.242"     # Backoffice admin portal IP
  bonusplaythrough: "5.62.94.243"  # Bonus Playthrough service IP
  gamemanager: "5.62.94.246"    # Game Manager service IP

# Optional: Override DNS standards with custom records
# dns_record_types:
#   - name: "api"
#     ip_key: "api"
#     comment: "API service"
#   
#   - name: "gameflex"
#     type: "CNAME"
#     content: "d3q2dc9uhx40b3.cloudfront.net"
#     comment: "GameFlex via CloudFront CDN"
```

## Standard DNS Records

DNS records are auto-generated from `ipAddresses` using DNS standards defined in `roles/linux/cloudflare/defaults/main.yml`:

```yaml
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

From the template above, these records are auto-generated:
```
api-l016.game-flex.eu              A      5.62.94.240   (proxied)
gameflex-l016.game-flex.eu         A      5.62.94.245   (proxied)
webapi-l016.game-flex.eu           A      5.62.94.241   (proxied)
backoffice-l016.game-flex.eu       A      5.62.94.242   (proxied)
bonusplaythrough-l016.game-flex.eu A      5.62.94.243   (proxied)
gamemanager-l016.game-flex.eu      A      5.62.94.246   (proxied)
```

**Naming Convention:**
- Format: `{service_name}-{platform_id}.{platform_domain}`
- Platform ID automatically lowercased
- Only services with IPs defined in `ipAddresses` are created

## Custom DNS Records

Override DNS standards by defining `dns_record_types` in platform file:

```yaml
---
platform_id: "S009"
platform_type: "staging"
env_type: "staging"
platform_domain: "iforium.com"

ipAddresses:
  gameflex: "81.88.167.98"
  backoffice: "81.88.167.90"
  webapi: "81.88.167.90"

# Custom DNS overrides standard DNS records
dns_record_types:
  - name: "gameflex"
    type: "CNAME"
    content: "d3q2dc9uhx40b3.cloudfront.net"
    comment: "GameFlex via CloudFront CDN"
  
  - name: "gameflex-origin"
    ip_key: "gameflex"
    comment: "GameFlex origin server"
  
  - name: "backoffice"
    ip_key: "backoffice"
    comment: "Backoffice admin"
  
  - name: "webapi"
    ip_key: "webapi"
    comment: "Web API"
```

**Result:**
```
gameflex-s009.iforium.com          CNAME  d3q2dc9uhx40b3.cloudfront.net
gameflex-origin-s009.iforium.com   A      81.88.167.98
backoffice-s009.iforium.com        A      81.88.167.90
webapi-s009.iforium.com            A      81.88.167.90
```

## Migration Steps:

1. Identify all unique IPs in the platform
2. Create `ipAddresses` dictionary with keys matching DNS standards (api, webapi, gameflex, etc.)
3. Set `platform_domain` based on inventory:
   - IOM platforms: `iforium.com`
   - LON platforms: `game-flex.eu`
4. Only add `dns_record_types` if custom DNS needed (CloudFront, special routing, etc.)
5. Place file in correct directory based on `platform_type`
6. Test with `--check` mode

## Example Platforms by Type:

### Live Platform (LON Inventory)
```yaml
---
platform_id: "L008"
platform_type: "live"
env_type: "live"
platform_domain: "game-flex.eu"

ipAddresses:
  api: "5.62.94.163"
  backoffice: "5.62.94.165"
  gameflex: "5.62.94.166"
  webapi: "5.62.94.164"
```

### Preprod Platform (IOM Inventory)
```yaml
---
platform_id: "P009"
platform_type: "preprod"
env_type: "preprod"
platform_domain: "iforium.com"

ipAddresses:
  gameflex: "81.88.167.72"
  backoffice: "81.88.167.90"
  webapi: "81.88.167.90"
  gamemanager: "81.88.167.90"
```

### Trunk Platform (IOM Inventory)
```yaml
---
platform_id: "T009"
platform_type: "trunk"
env_type: "trunk"
platform_domain: "iforium.com"

ipAddresses:
  gameflex: "81.88.167.90"
```

## Variables Reference:

- `sysPlatformID`: Platform ID (L016, T009, S009, etc.)
- `ipAddresses`: Dictionary of IP addresses
- `dns_record_types`: List of records to create
- `dns_ttl`: TTL for all records (default: 1 = automatic)
- `dns_proxied`: Proxy through Cloudflare (default: true)
- `platform_type`: Used in comments (production, test, etc.)
