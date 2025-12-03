# Cloudflare Configuration Scope Guide

## Overview

This document details each configuration scope available in the AWX Cloudflare deployment job and explains what gets configured when you select each scope. Understanding these scopes helps you target specific infrastructure changes without affecting unrelated services.

---

## Configuration Scopes

### 1. **all** - Complete Infrastructure Deployment

**Description:** Deploys all Cloudflare configurations across all layers - zone settings, SSL/TLS, DNS records, health checks, firewall rules, and notification policies.

**When to Use:**
- Initial platform setup
- Complete infrastructure refresh
- Major platform updates requiring all components
- Disaster recovery scenarios

**What Gets Configured:**

#### Zone-Level Settings (Global)
- **SSL/TLS Configuration:**
  - Universal SSL enablement
  - Minimum TLS version (1.0)
  - TLS 1.3 support (off)
  - Opportunistic encryption (off)
  - Automatic HTTPS rewrites (off)
  - Always Use HTTPS (off)

- **Security Settings:**
  - Security level (medium)
  - Browser integrity check (on)
  - Challenge TTL (1800 seconds)
  - Privacy Pass (on)
  - HSTS (Strict Transport Security)

- **Performance Settings:**
  - Cache level (aggressive)
  - Browser cache TTL (14400 seconds / 4 hours)
  - Minification (CSS, HTML, JS - all off)
  - Brotli compression (off)
  - Early Hints (off)
  - HTTP/3 support (off)
  - 0-RTT Connection Resumption (off)

- **Network Settings:**
  - IPv6 support (on)
  - WebSockets (on)
  - Pseudo IPv4 (off)
  - IP Geolocation (on)

#### Domain-Level Settings
- **SSL/TLS Domain Configuration:**
  - Universal SSL verification and enablement
  - SSL mode (full_strict)
  - Minimum TLS version (1.2)
  - TLS 1.3 (on)
  - Always Use HTTPS enforcement

- **Argo Smart Routing:**
  - Argo smart routing (enabled)
  - Tiered caching (enabled)
  - Performance acceleration

- **Cache Rules:**
  - Bypass cache for TestPage.html
  - Bypass cache for gamelaunch test pages
  - Cache gamelaunch express JS files (300s TTL)
  - Cache HTML files with specific rules
  - Conditional caching based on URL patterns

- **Origin Configuration:**
  - Query string sorting for cache
  - Origin-specific settings

#### DNS Records
- Platform-specific A records
- CNAME records for services
- Dynamic record generation based on platform variables
- Records include:
  - `api-{platform}` - API endpoints
  - `admin-{platform}` - Admin interfaces  
  - `gameflex-{platform}` - Gaming services
  - `www` - Website
  - `backoffice` - Back office systems

#### Network & Health Checks
- HTTP/HTTPS health checks for platform services
- Health check monitoring for:
  - GameFlex platform (`/health` endpoint)
  - API service (`/api/v1/health` endpoint)
- Check regions: Western Europe (WEU), Eastern North America (ENAM)
- Monitoring intervals: 60-120 seconds
- Retry configuration: 2-3 attempts
- Expected status codes validation

- **IP Geolocation:**
  - Enable IP-based geolocation for traffic analytics
  - Country-level traffic data

- **Geo-Blocking:**
  - Block traffic from specific countries (CN, RU, KP, IR)

#### Platform Firewall Rules
- Platform-specific firewall expressions
- Custom security rules per platform
- Rate limiting rules (if configured)
- Action rules (allow, block, challenge, js_challenge)

#### Notifications & Alerts
- **Email Destinations:**
  - DevOps team notification list
  - Alert recipient configuration

- **Notification Policies:**
  - SSL certificate expiry alerts
  - Health check failure notifications
  - DDoS attack alerts
  - Rate limit threshold warnings

**Execution Time:** 3-8 minutes (depending on platform complexity)

**Risk Level:** ⚠️ High - Affects all infrastructure components

---

### 2. **global** - Zone & Security Foundation

**Description:** Configures zone-wide settings that affect all traffic and services within the Cloudflare zone. These are the foundational security and performance settings.

**When to Use:**
- Updating security policies
- Changing SSL/TLS requirements
- Adjusting global cache behavior
- Modifying zone-level features

**What Gets Configured:**

- ✅ SSL/TLS zone settings (min TLS version, TLS 1.3, opportunistic encryption)
- ✅ Security settings (security level, browser checks, challenge TTL)
- ✅ Performance settings (cache level, browser cache TTL, minification)
- ✅ Network settings (IPv6, WebSockets, Pseudo IPv4)
- ✅ DDoS protection settings
- ✅ Zone-level rate limiting configuration

**What Does NOT Get Configured:**
- ❌ Domain-specific SSL/Argo/cache rules
- ❌ DNS records
- ❌ Health checks
- ❌ Platform firewall rules
- ❌ Notifications

**Example Use Cases:**
- Enforce stricter TLS version requirements across all domains
- Update zone-level security posture
- Change global cache behavior
- Enable/disable zone features like IPv6 or WebSockets

**Execution Time:** 1-2 minutes

**Risk Level:** 🟡 Medium - Affects entire zone but no DNS/routing changes

---

### 3. **domain** - SSL, Cache & Performance Rules

**Description:** Configures domain-specific settings including SSL certificates, Argo routing, cache rules, and origin configurations. These settings control how Cloudflare handles traffic for the specific domain.

**When to Use:**
- Updating SSL certificate settings
- Modifying cache rules for specific URL patterns
- Adjusting Argo smart routing
- Changing origin server configurations
- Testing new cache strategies

**What Gets Configured:**

- ✅ **Universal SSL:**
  - Enable/verify Universal SSL
  - SSL mode configuration (off, flexible, full, full_strict)
  - Custom certificate management

- ✅ **Argo Smart Routing:**
  - Smart routing enablement
  - Tiered caching configuration
  - Performance optimization

- ✅ **Cache Rules (via Rulesets API):**
  - TestPage.html bypass rules
  - Gamelaunch test page bypass
  - JS file caching (300s TTL)
  - HTML file caching rules
  - Conditional cache based on URI patterns
  - Edge TTL and Browser TTL configuration

- ✅ **Origin Settings:**
  - Query string sorting for cache keys
  - Origin connection settings
  - Host header configuration

- ✅ **Cache Purging:**
  - Pattern-based cache purging (if configured)
  - Selective cache invalidation

**What Does NOT Get Configured:**
- ❌ Zone-level security/SSL settings
- ❌ DNS records
- ❌ Health checks
- ❌ Firewall rules
- ❌ Notifications

**Example Use Cases:**
- Roll out new cache rules for API endpoints
- Update SSL configuration after certificate changes
- Adjust Argo settings for performance tuning
- Modify cache bypass rules for testing pages

**Execution Time:** 1-3 minutes

**Risk Level:** 🟡 Medium - Affects traffic handling but no DNS changes

---

### 4. **dns** - DNS Records Only

**Description:** Creates or updates DNS records for the selected platform. This is the most frequently used scope for adding new services or updating IP addresses.

**When to Use:**
- Adding new platform services
- Updating IP addresses after infrastructure changes
- Adding/removing subdomains
- Modifying DNS record properties (TTL, proxy status)

**What Gets Configured:**

- ✅ **Platform DNS Records:**
  - A records for service endpoints
  - CNAME records for aliases
  - Dynamic record generation based on:
    - Platform ID (L008, P019, S009, etc.)
    - Platform domain (game-flex.eu, route-game-flex.eu, etc.)
    - IP addresses from platform configuration

- ✅ **Record Properties:**
  - Record name (with platform suffix)
  - Record type (A, CNAME, TXT, etc.)
  - Content (IP address or target)
  - TTL (Time To Live)
  - Proxy status (orange-clouded vs grey-clouded)
  - Comment/description for tracking

- ✅ **Typical Records Created:**
  - `api-{platform}.domain.com` → Platform API IP
  - `admin-{platform}.domain.com` → Admin interface IP
  - `gameflex-{platform}.domain.com` → Gaming service IP
  - `ws-{platform}.domain.com` → WebSocket service IP
  - `backoffice.domain.com` → Back office IP (no platform suffix)

**Record Behavior:**
- **Create:** If record doesn't exist
- **Update:** If record exists but content/settings differ
- **Idempotent:** Safe to run multiple times

**What Does NOT Get Configured:**
- ❌ Zone or domain settings
- ❌ SSL/TLS configuration
- ❌ Cache rules
- ❌ Health checks
- ❌ Firewall rules
- ❌ Notifications

**Example Use Cases:**
- New platform deployment: Add all DNS records for L025
- IP address change: Update existing records after server migration
- Service addition: Add new subdomain for monitoring service
- Proxy toggle: Change record from proxied to DNS-only

**Dry-Run Output Example:**
```
🔍 DRY-RUN: Would CREATE DNS record:
  Name: api-l008.game-flex.eu
  Type: A
  Content: 192.0.2.10
  TTL: 1 (Auto)
  Proxied: true
```

**Execution Time:** 30 seconds - 2 minutes

**Risk Level:** 🟢 Low - Only affects DNS routing, no settings changes

---

### 5. **network** - Health Checks & Geolocation

**Description:** Configures health monitoring and network-level features including health checks for services and IP geolocation settings.

**When to Use:**
- Setting up monitoring for new services
- Updating health check endpoints
- Enabling/disabling IP geolocation
- Configuring geo-blocking rules

**What Gets Configured:**

- ✅ **Health Checks:**
  - **GameFlex Platform Health:**
    - URL: `https://gameflex-{platform}.domain.com/health`
    - Check interval: 60 seconds
    - Timeout: 10 seconds
    - Retries: 2
    - Expected codes: 200, 204
    - Check regions: WEU, ENAM
  
  - **API Service Health:**
    - URL: `https://api-{platform}.domain.com/api/v1/health`
    - Check interval: 120 seconds
    - Timeout: 10 seconds
    - Retries: 3
    - Expected codes: 200, 201
    - Check regions: WEU, ENAM

- ✅ **Health Check Configuration:**
  - Protocol (HTTP/HTTPS)
  - Port (typically 443)
  - Path to health endpoint
  - Expected status codes
  - Expected response body (optional)
  - Follow redirects setting
  - Allow insecure SSL setting
  - Regional monitoring points

- ✅ **IP Geolocation:**
  - Enable IP-based geolocation headers
  - Adds `CF-IPCountry` header to requests
  - Used for traffic analytics and routing

- ✅ **Geographic Controls:**
  - Country-based access rules (if configured)
  - Geo-blocking for specific countries

**Health Check States:**
- **Healthy:** Endpoint responds with expected codes
- **Unhealthy:** Endpoint fails retries
- **Degraded:** Intermittent failures

**What Does NOT Get Configured:**
- ❌ DNS records
- ❌ SSL/Cache rules
- ❌ Firewall rules (use 'platform' scope)
- ❌ Zone settings
- ❌ Notifications (use 'notifications' scope)

**Example Use Cases:**
- Monitor new platform services after deployment
- Update health check paths after API version changes
- Enable geolocation for regional traffic routing
- Configure failure detection for alerting

**Execution Time:** 1-2 minutes

**Risk Level:** 🟢 Low - Monitoring only, no traffic impact

---

### 6. **platform** - Firewall & Platform Rules

**Description:** Applies platform-specific firewall rules and security configurations. These rules control access and security at the platform level.

**When to Use:**
- Creating platform-specific access controls
- Implementing rate limiting per platform
- Adding security rules for specific endpoints
- Blocking/allowing specific traffic patterns

**What Gets Configured:**

- ✅ **Platform Firewall Rules:**
  - Custom firewall expressions for platform
  - Rule actions (allow, block, challenge, js_challenge, managed_challenge)
  - Rule priorities and ordering
  - Rule descriptions for tracking

- ✅ **Firewall Rule Components:**
  - **Expression:** Matching conditions (IP, URI, headers, ASN, country)
  - **Action:** What to do with matching traffic
  - **Priority:** Rule evaluation order
  - **Enabled:** Active/inactive status
  - **Description:** Rule purpose and context

- ✅ **Common Rule Patterns:**
  - Block specific countries for platform
  - Allow only specific IP ranges
  - Rate limit API endpoints
  - Challenge suspicious traffic
  - Block known malicious user agents

**Example Firewall Rules:**
```yaml
- action: "block"
  description: "Block malicious countries for L008"
  expression: '(ip.geoip.country in {"CN" "RU" "KP"} and http.host contains "l008")'
  enabled: true
  priority: 1

- action: "challenge"
  description: "Challenge high-rate API requests"
  expression: '(http.request.uri.path contains "/api/" and rate(5m) > 100)'
  enabled: true
  priority: 2
```

**Firewall Actions:**
- **allow:** Bypass other rules and allow traffic
- **block:** Block traffic with 403 response
- **challenge:** Present CAPTCHA challenge
- **js_challenge:** JavaScript challenge (invisible)
- **managed_challenge:** Cloudflare Managed Challenge

**What Does NOT Get Configured:**
- ❌ DNS records
- ❌ Health checks
- ❌ SSL/Cache rules
- ❌ Zone-level security settings
- ❌ Notifications

**Example Use Cases:**
- Block specific countries from accessing production platform
- Rate limit API endpoints to prevent abuse
- Allow only office IPs to admin interfaces
- Challenge traffic from suspicious ASNs

**Execution Time:** 1-2 minutes

**Risk Level:** 🟡 Medium - Can block legitimate traffic if misconfigured

---

### 7. **notifications** - Alerts & Monitoring

**Description:** Configures notification destinations and alert policies for infrastructure monitoring and incident response.

**When to Use:**
- Setting up alerting for new platforms
- Adding notification recipients
- Creating new alert policies
- Updating webhook integrations

**What Gets Configured:**

- ✅ **Email Destinations:**
  - DevOps team email lists
  - Individual recipient addresses
  - Email destination names for policy reference

- ✅ **Webhook Destinations:**
  - Slack webhook URLs
  - PagerDuty integrations
  - Custom webhook endpoints
  - Webhook secrets for security

- ✅ **Notification Policies:**
  - **SSL Certificate Expiry:**
    - Alert 30 days before expiration
    - Daily reminders as expiry approaches
    - Destinations: DevOps team email
  
  - **Health Check Failures:**
    - Alert on health check state changes
    - Platform-specific health checks
    - Destinations: DevOps team, on-call webhooks
  
  - **DDoS Attack Detection:**
    - Alert on DDoS mitigation activation
    - Real-time attack notifications
    - Destinations: Security team, incident webhook
  
  - **Rate Limit Threshold:**
    - Alert when rate limits are triggered
    - High-volume traffic warnings
    - Destinations: Operations team

- ✅ **Alert Types Available:**
  - `universal_ssl_event_type` - SSL certificate events
  - `health_check_status_notification` - Health check state changes
  - `ddos_attack_l7_alert` - Layer 7 DDoS alerts
  - `rate_limit_threshold_alert` - Rate limiting alerts
  - `zone_configuration_change` - Configuration changes
  - `failing_logpush_job_disabled` - Log push failures

**Policy Configuration:**
```yaml
- name: "health-check-failures"
  description: "Notify when health checks fail"
  enabled: true
  alert_type: "health_check_status_notification"
  filters:
    health_check_id:
      - "l008-api-health"
      - "l008-gameflex-health"
  mechanisms:
    email:
      - "cloudflare-devops-team"
    webhooks:
      - "slack-incidents-channel"
```

**What Does NOT Get Configured:**
- ❌ DNS records
- ❌ Health checks themselves (use 'network' scope)
- ❌ Firewall rules
- ❌ SSL/Cache rules
- ❌ Zone settings

**Example Use Cases:**
- Set up alerts for newly deployed platform
- Add new team member to notification list
- Integrate with PagerDuty for on-call rotation
- Configure Slack alerts for dev team

**Execution Time:** 1-2 minutes

**Risk Level:** 🟢 Low - No impact on traffic or services

---

## Scope Selection Decision Tree

```
┌─────────────────────────────────────┐
│   What do you want to change?      │
└─────────────────────────────────────┘
                │
                ├─ Everything? ──────────────────────────► Use: all
                │
                ├─ Just IP addresses/subdomains? ─────────► Use: dns
                │
                ├─ SSL certificates or cache rules? ──────► Use: domain
                │
                ├─ Zone security/performance settings? ───► Use: global
                │
                ├─ Health monitoring? ────────────────────► Use: network
                │
                ├─ Access control/firewall? ──────────────► Use: platform
                │
                └─ Alerting/notifications? ───────────────► Use: notifications
```

---

## Scope Dependencies

Some scopes depend on configurations from other scopes:

```
global (zone settings)
  └── domain (requires zone to exist)
       ├── dns (requires domain config for proxying)
       ├── network (health checks require DNS records)
       └── platform (firewall rules reference DNS names)

notifications
  └── network (alert on health check failures)
```

**Recommendation:** For initial platform setup, always use `all` scope first, then use targeted scopes for updates.

---

## Best Practices

### 1. **Use Dry-Run Mode First**
Always test with `Dry Run Mode = yes` before applying changes:
- Preview what will change
- Validate configuration correctness
- Catch potential issues early

### 2. **Scope Selection Guidelines**

| Change Type | Recommended Scope | Frequency |
|-------------|------------------|-----------|
| New platform deployment | `all` | Rarely |
| IP address update | `dns` | Weekly |
| New subdomain | `dns` | Daily |
| Cache rule adjustment | `domain` | Monthly |
| SSL certificate update | `domain` | Quarterly |
| Security policy change | `global` | Quarterly |
| Health check update | `network` | Monthly |
| Firewall rule change | `platform` | Weekly |
| Alert recipient change | `notifications` | Monthly |

### 3. **Change Windows**

- **Low-Risk Scopes** (dns, notifications, network): Anytime
- **Medium-Risk Scopes** (domain, platform): During change windows
- **High-Risk Scopes** (all, global): During planned maintenance

### 4. **Scope Combination Strategy**

You **cannot select multiple scopes** in one job run. To apply multiple changes:

**Option A - Sequential Runs:**
```
1. Run job with scope: dns
2. Run job with scope: network
3. Run job with scope: notifications
```

**Option B - Use "all" Scope:**
```
1. Run job with scope: all (if all changes are ready)
```

### 5. **Rollback Strategy**

Each scope has different rollback approaches:

| Scope | Rollback Method | Time to Rollback |
|-------|----------------|------------------|
| `dns` | Re-run job with previous IPs | 1-2 minutes |
| `domain` | Re-run job with previous cache rules | 2-3 minutes |
| `global` | Re-run job with previous zone settings | 2-3 minutes |
| `network` | Disable health checks in UI | 30 seconds |
| `platform` | Disable firewall rules in UI | 30 seconds |
| `notifications` | Disable policies in UI | 30 seconds |

### 6. **Audit & Tracking**

- **Always provide Ticket Number:** Links changes to change requests
- **Document scope selection:** Note why specific scope was chosen
- **Review dry-run output:** Ensure changes match intentions
- **Monitor after deployment:** Check logs and alerts post-change

---

## Troubleshooting

### Problem: "DNS records not created after running 'dns' scope"

**Possible Causes:**
- Zone doesn't exist (requires 'global' scope first)
- Platform variables not defined in inventory
- IP addresses missing from platform configuration

**Solution:**
1. Verify zone exists: Run with `global` scope first
2. Check platform file: `inventories/TEST/group_vars/cloudflare/platforms/production/{platform}.yml`
3. Ensure `ipAddresses` dictionary is populated

---

### Problem: "Health checks failing after creation"

**Possible Causes:**
- DNS records don't exist yet
- Service not responding on health check path
- Firewall blocking health check IPs

**Solution:**
1. Run `dns` scope first to create records
2. Verify service health endpoint: `curl https://api-{platform}.domain.com/health`
3. Allow Cloudflare IP ranges in firewall

---

### Problem: "Cache rules not applying"

**Possible Causes:**
- Domain scope not run after global changes
- Cache rules syntax error in configuration
- Existing page rules conflicting

**Solution:**
1. Run `domain` scope explicitly
2. Validate YAML syntax in `domain.yml`
3. Check page rules in Cloudflare UI for conflicts

---

### Problem: "Notifications not being received"

**Possible Causes:**
- Email destination not verified
- Webhook endpoint unreachable
- Policy filters too restrictive

**Solution:**
1. Verify email in Cloudflare dashboard
2. Test webhook endpoint separately
3. Review policy filters in `notifications.yml`

---

## Configuration File Reference

Each scope reads from specific inventory files:

| Scope | Configuration Files |
|-------|-------------------|
| `global` | `inventories/TEST/group_vars/cloudflare/vars/global.yml`<br>`inventories/TEST/group_vars/cloudflare/vars/zone.yml` |
| `domain` | `inventories/TEST/group_vars/cloudflare/vars/domain.yml` |
| `dns` | `inventories/TEST/group_vars/cloudflare/platforms/{env}/{platform}.yml` |
| `network` | `inventories/TEST/group_vars/cloudflare/vars/network.yml` |
| `platform` | `inventories/TEST/group_vars/cloudflare/platforms/{env}/{platform}.yml` |
| `notifications` | `inventories/TEST/group_vars/cloudflare/vars/notifications.yml` |

---

## Summary Table

| Scope | Purpose | Risk | Time | When to Use |
|-------|---------|------|------|-------------|
| **all** | Complete deployment | ⚠️ High | 3-8 min | Initial setup, full refresh |
| **global** | Zone foundation | 🟡 Medium | 1-2 min | Security policy updates |
| **domain** | SSL/Cache rules | 🟡 Medium | 1-3 min | Cache/SSL changes |
| **dns** | DNS records | 🟢 Low | 0.5-2 min | IP updates, new services |
| **network** | Health monitoring | 🟢 Low | 1-2 min | Monitoring setup |
| **platform** | Firewall rules | 🟡 Medium | 1-2 min | Access control changes |
| **notifications** | Alerts | 🟢 Low | 1-2 min | Alert configuration |

---

## Related Documentation

- **AWX Survey Setup:** `roles/linux/awx_survey_setup/README.md`
- **Cloudflare Role Documentation:** `roles/linux/cloudflare/documents/README.md`
- **Platform Configuration Guide:** `README.md`
- **Validation Framework:** `README-validation.md` (if exists)

---

**Document Version:** 1.0  
**Last Updated:** December 3, 2025  
**Maintained By:** DevOps Team
