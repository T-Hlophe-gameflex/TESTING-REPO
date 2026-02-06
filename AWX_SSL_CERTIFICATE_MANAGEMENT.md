# AWX SSL Certificate Management Guide

## Overview

This document explains how to manage SSL certificates for Cloudflare domains using AWX. The system allows you to securely store and deploy SSL certificates through AWX's credential management system.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Initial Setup](#initial-setup)
3. [Managing Certificates](#managing-certificates)
4. [Running Deployments](#running-deployments)
5. [How It Works](#how-it-works)
6. [Troubleshooting](#troubleshooting)

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                         AWX System                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐      ┌──────────────────┐          │
│  │  Credential Type │      │   Job Template   │          │
│  │  SSL Certificate │─────▶│ Cloudflare-      │          │
│  │                  │      │  Deployment      │          │
│  └──────────────────┘      └──────────────────┘          │
│           │                         │                      │
│           │                         │                      │
│           ▼                         ▼                      │
│  ┌──────────────────┐      ┌──────────────────┐          │
│  │   Credential     │      │    Playbook      │          │
│  │ Test-SSL-Cert    │─────▶│  cloudflare.yml  │          │
│  │                  │      │                  │          │
│  └──────────────────┘      └──────────────────┘          │
│           │                         │                      │
└───────────┼─────────────────────────┼──────────────────────┘
            │                         │
            │ Injects Variables       │ Executes
            │                         │
            ▼                         ▼
   ┌─────────────────┐      ┌──────────────────┐
   │  certificate    │      │  Platform Config │
   │  private_key    │─────▶│     G000.yml     │
   │  bundle         │      │                  │
   └─────────────────┘      └──────────────────┘
                                      │
                                      │ Uses
                                      ▼
                            ┌──────────────────┐
                            │   ssl_certs.yml  │
                            │      Tasks       │
                            └──────────────────┘
                                      │
                                      │ Uploads to
                                      ▼
                            ┌──────────────────┐
                            │   Cloudflare     │
                            │      API         │
                            └──────────────────┘
```

### Flow

1. **AWX Credential** stores the certificate data securely
2. **Credential Type** defines how to inject variables
3. **Job Template** uses both Cloudflare API and SSL Certificate credentials
4. **Platform Config** references the injected variables
5. **SSL Tasks** execute based on domain scope
6. **Cloudflare API** receives the certificate upload

---

## Initial Setup

### 1. Create SSL Certificate Credential Type

**Only needs to be done once per AWX instance**

1. Login to AWX: `http://localhost:8081` (admin user)

2. Navigate to: **Administration → Credential Types**

3. Click: **Add** button

4. Configure:
   - **Name:** `SSL Certificate`
   - **Description:** `Custom SSL certificate with private key for Cloudflare`

5. **Input Configuration:**
```yaml
fields:
  - id: certificate
    type: string
    label: SSL Certificate
    multiline: true
    secret: false
  - id: private_key
    type: string
    label: Private Key
    multiline: true
    secret: true
  - id: bundle
    type: string
    label: Certificate Bundle (Optional)
    multiline: true
    secret: false
required:
  - certificate
  - private_key
```

6. **Injector Configuration:**
```yaml
extra_vars:
  certificate: '{{ certificate }}'
  private_key: '{{ private_key }}'
  bundle: '{{ bundle | default("") }}'
```

7. Click: **Save**

---

## Managing Certificates

### Creating a New SSL Certificate

1. Navigate to: **Resources → Credentials**

2. Click: **Add** button

3. Fill in:
   - **Name:** `<domain>-SSL-Certificate` (e.g., `route-game-flex-SSL-Certificate`)
   - **Description:** `SSL certificate for <domain>`
   - **Organization:** `Default`
   - **Credential Type:** `SSL Certificate`

4. **Enter Certificate Data:**

   **SSL Certificate:** Paste your certificate in PEM format
   ```
   -----BEGIN CERTIFICATE-----
   MIIDXTCCAkWgAwIBAgIJAKJ5JqJ5JqJ5MA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
   ... (certificate content)
   -----END CERTIFICATE-----
   ```

   **Private Key:** Paste your private key
   ```
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDtest1234567890
   ... (private key content)
   -----END PRIVATE KEY-----
   ```

   **Certificate Bundle:** (Optional) Paste intermediate certificates
   ```
   -----BEGIN CERTIFICATE-----
   ... (intermediate cert 1)
   -----END CERTIFICATE-----
   -----BEGIN CERTIFICATE-----
   ... (intermediate cert 2)
   -----END CERTIFICATE-----
   ```

5. Click: **Save**

### Updating an Existing Certificate

When you need to renew or replace a certificate:

1. Navigate to: **Resources → Credentials**

2. Find your certificate credential (e.g., `route-game-flex-SSL-Certificate`)

3. Click: **Edit** (pencil icon)

4. Update the fields:
   - **SSL Certificate:** Replace with new certificate
   - **Private Key:** Replace with new private key
   - **Certificate Bundle:** Update if intermediate certs changed

5. Click: **Save**

### Attaching Certificate to Job Template

**Only needs to be done once per job template**

1. Navigate to: **Resources → Templates**

2. Click: **Cloudflare-Deployment**

3. Click: **Edit**

4. In **Credentials** section, ensure these are selected:
   - ✅ `Cloudflare-API-Token` (for Cloudflare API access)
   - ✅ `<domain>-SSL-Certificate` (your SSL certificate)

5. Click: **Save**

---

## Running Deployments

### Deploy SSL Certificate via AWX

#### Option 1: Via AWX Web Interface

1. Navigate to: **Resources → Templates**

2. Click: **Launch** button next to `Cloudflare-Deployment`

3. Fill in survey:
   - **Ticket Number:** Your ticket reference (e.g., `SSL-DEPLOY-001`)
   - **Cloudflare Region:** Select region (e.g., `TEST`)
   - **Platform ID:** Select platform (e.g., `G000`)
   - **Cloudflare Scope:** Select `domain`
   - **Dry Run Mode:** 
     - `On` - Preview changes without applying
     - `Off` - Actually deploy to Cloudflare

4. Click: **Next** → **Launch**

5. Monitor job execution and review output

#### Option 2: Via AWX API

```bash
curl -X POST http://localhost:8081/api/v2/job_templates/28/launch/ \
  -H "Content-Type: application/json" \
  -u "username:password" \
  -d '{
    "extra_vars": {
      "ticket_number": "SSL-DEPLOY-001",
      "cloudflare_region": "TEST",
      "platform_id": "G000",
      "cloudflare_scope": "domain",
      "cloudflare_dry_run": "On"
    }
  }'
```

### Testing Before Deployment

**Always test in dry-run mode first!**

1. Launch job with `cloudflare_dry_run: "On"`

2. Review the output for:
   ```
   SSL CERTIFICATE CONFIGURATION SUMMARY
   ======================================================================
   Domain: route-game-flex.eu
   SSL Mode: full_strict
   Universal SSL: Enabled
   Min TLS Version: 1.2
   Custom Certificates: 1
   Mode: DRY-RUN (Preview Only)
   ======================================================================
   ```

3. Check certificate upload preview:
   ```
   Would upload certificate 1:
     Certificate: Present (920 bytes)
     Private Key: Present (661 bytes)
     Bundle: None
     Bundle Method: ubiquitous
   ```

4. If everything looks correct, run with `cloudflare_dry_run: "Off"`

---

## How It Works

### Variable Injection

When you attach an SSL Certificate credential to a job:

1. **AWX reads** the credential data (certificate, private_key, bundle)
2. **Injector** injects them as Ansible extra_vars:
   ```yaml
   certificate: "-----BEGIN CERTIFICATE-----\n..."
   private_key: "-----BEGIN PRIVATE KEY-----\n..."
   bundle: ""
   ```
3. **Platform config** references these variables

### Platform Configuration

In your platform file (e.g., `inventories/TEST/group_vars/all/platforms/global/G000.yml`):

```yaml
cloudflare_domain_ssl:
  ssl_mode: "full_strict"
  min_tls_version: "1.2"
  universal_ssl_enabled: true
  tls_1_3: "on"
  always_use_https: true
  custom_certificates:
    # These variables are injected by AWX SSL Certificate credential
    - certificate: "{{ certificate | default('') }}"
      private_key: "{{ private_key | default('') }}"
      bundle: "{{ bundle | default('') }}"
      bundle_method: "ubiquitous"
```

### Task Execution Flow

When `cloudflare_scope: domain` is selected:

1. **Main playbook** (`cloudflare.yml`) runs
2. **Domain scope** triggers `domain.yml` tasks
3. **SSL certificate tasks** (`ssl_certs.yml`) execute when scope is `domain`
4. **Tasks check** if `custom_certificates` array has items
5. **If certificates exist:**
   - Get Zone ID from Cloudflare
   - List existing certificates
   - Display preview (dry-run) or upload (deployment)
   - Set SSL/TLS mode
   - Display summary

### SSL Certificate Tasks

Located in: `roles/linux/cloudflare/tasks/ssl_certs.yml`

**Key tasks:**

1. **Get Zone ID**
   ```yaml
   - name: cloudflare | ssl_certs | Get Zone ID
     ansible.builtin.uri:
       url: "https://api.cloudflare.com/client/v4/zones?name={{ platform_domain }}"
       method: GET
   ```

2. **List existing certificates**
   ```yaml
   - name: cloudflare | ssl_certs | List existing custom certificates
     ansible.builtin.uri:
       url: "https://api.cloudflare.com/client/v4/zones/{{ cloudflare_zone_id }}/custom_certificates"
       method: GET
   ```

3. **Upload certificate (Dry-Run)**
   ```yaml
   - name: cloudflare | ssl_certs | Upload custom SSL certificates (DRY-RUN)
     ansible.builtin.debug:
       msg:
         - "Would upload certificate {{ item_index + 1 }}:"
         - "  Certificate: Present ({{ item.certificate | length }} bytes)"
         - "  Private Key: Present ({{ item.private_key | length }} bytes)"
   ```

4. **Upload certificate (Deployment)**
   ```yaml
   - name: cloudflare | ssl_certs | Upload custom SSL certificates (DEPLOYMENT)
     ansible.builtin.uri:
       url: "https://api.cloudflare.com/client/v4/zones/{{ cloudflare_zone_id }}/custom_certificates"
       method: POST
       body:
         certificate: "{{ item.certificate }}"
         private_key: "{{ item.private_key }}"
         bundle_method: "{{ item.bundle_method | default('ubiquitous') }}"
   ```

5. **Display summary**
   ```yaml
   - name: cloudflare | ssl_certs | Summary
     ansible.builtin.debug:
       msg:
         - "SSL Mode: {{ cloudflare_domain_ssl.ssl_mode }}"
         - "Custom Certificates: {{ cloudflare_domain_ssl.custom_certificates | length }}"
   ```

### Scope Trigger Conditions

SSL certificate tasks run when:

```yaml
when: cloudflare_scope | default('all') in ['all', 'domain', 'ssl', 'certificates']
```

**Available scopes:**
- `domain` - Domain settings + SSL certificates ✅
- `dns` - DNS records only
- `network` - Network settings only
- `notifications` - Notification policies only
- `all` - Everything (requires code modification to survey)

### Dry-Run vs Deployment Mode

**Dry-Run Mode (`cloudflare_dry_run: "On"`):**
- ✅ Previews what would be uploaded
- ✅ Shows certificate sizes and details
- ✅ No changes made to Cloudflare
- ✅ Safe to run anytime

**Deployment Mode (`cloudflare_dry_run: "Off"`):**
- ⚠️ Actually uploads certificate to Cloudflare
- ⚠️ Makes real changes
- ⚠️ Requires valid certificate data
- ⚠️ Use only after dry-run verification

---

## Troubleshooting

### Issue: Custom Certificates shows 0

**Symptoms:**
```
Custom Certificates: 0
```

**Causes & Solutions:**

1. **Certificate credential not attached to job template**
   - Solution: Edit job template, add SSL Certificate credential

2. **Certificate variables empty**
   - Check: Job extra_vars for `certificate`, `private_key`
   - Solution: Verify credential type injector configuration

3. **Platform config not using variables**
   - Check: `G000.yml` has `certificate: "{{ certificate }}"`
   - Solution: Update platform config with variable references

### Issue: Certificate upload fails

**Symptoms:**
```
fatal: [test-cloudflare-manager]: FAILED!
```

**Causes & Solutions:**

1. **Invalid certificate format**
   - Solution: Ensure PEM format with proper headers/footers
   - Validate: `openssl x509 -in cert.pem -text -noout`

2. **Private key doesn't match certificate**
   - Solution: Verify key matches cert
   - Check: `openssl x509 -noout -modulus -in cert.pem | openssl md5`

3. **Cloudflare API authentication failure**
   - Solution: Verify Cloudflare-API-Token credential is valid
   - Test: Run DNS scope first to validate API access

### Issue: Undefined variable errors

**Symptoms:**
```
'cloudflare_domain' is undefined
```

**Solution:**
- Tasks should use `platform_domain` or `effective_zone_name`
- Update ssl_certs.yml to use correct variables

### Issue: Job launched but certificate not detected

**Check:**

1. **View job extra_vars:**
   ```bash
   curl -s http://localhost:8081/api/v2/jobs/<JOB_ID>/ -u "username:password" \
     | python3 -c "import sys, json; print(json.loads(json.load(sys.stdin)['extra_vars']))"
   ```

2. **Verify credentials attached:**
   ```bash
   curl -s http://localhost:8081/api/v2/jobs/<JOB_ID>/ -u "username:password" \
     | python3 -c "import sys, json; creds=json.load(sys.stdin)['summary_fields']['credentials']; [print(c['name']) for c in creds]"
   ```

3. **Check job output for certificate tasks:**
   ```bash
   curl -s "http://localhost:8081/api/v2/jobs/<JOB_ID>/stdout/?format=txt" -u "username:password" \
     | grep -A 10 "ssl_certs"
   ```

---

## Certificate Lifecycle

### Regular Maintenance

**Before Certificate Expiration (30-60 days):**

1. Obtain new certificate from CA (Let's Encrypt, DigiCert, etc.)
2. Update AWX credential with new certificate
3. Test in dry-run mode
4. Deploy to production

**Recommended Schedule:**
- Check certificate expiration: Monthly
- Renew certificates: 30 days before expiration
- Test deployments: After each certificate update

### Certificate Rotation Process

```mermaid
graph TD
    A[Certificate Expiring Soon] --> B[Obtain New Certificate]
    B --> C[Update AWX Credential]
    C --> D[Run Dry-Run Deployment]
    D --> E{Dry-Run Successful?}
    E -->|No| F[Fix Issues]
    F --> D
    E -->|Yes| G[Deploy to Production]
    G --> H[Verify in Cloudflare Dashboard]
    H --> I[Monitor for 24 hours]
    I --> J[Certificate Rotation Complete]
```

### Best Practices

1. **Always use dry-run first** before deploying
2. **Test certificates** are valid before uploading
3. **Keep backups** of old certificates for rollback
4. **Document changes** in ticket system
5. **Monitor Cloudflare** dashboard after deployment
6. **Set reminders** for certificate renewal (30 days before expiration)
7. **Use automation** for Let's Encrypt renewals when possible

---

## Security Considerations

### Credential Storage

- ✅ Private keys stored encrypted in AWX database
- ✅ Access controlled via RBAC
- ✅ Audit logs track credential access
- ⚠️ Never commit certificates to Git
- ⚠️ Never share credentials via email/chat

### Access Control

**Recommended permissions:**

- **Admins:** Full access to credentials and job templates
- **Operators:** Execute jobs only (can't view credentials)
- **Auditors:** Read-only access to job logs

### Certificate Validation

Before uploading to AWX:

```bash
# Verify certificate
openssl x509 -in certificate.pem -text -noout

# Check certificate dates
openssl x509 -in certificate.pem -noout -dates

# Verify private key matches certificate
openssl x509 -noout -modulus -in certificate.pem | openssl md5
openssl rsa -noout -modulus -in private-key.pem | openssl md5
# MD5 hashes should match

# Check certificate chain
openssl verify -CAfile bundle.pem certificate.pem
```

---

## Quick Reference

### Common Commands

**Launch job via API:**
```bash
curl -X POST http://localhost:8081/api/v2/job_templates/28/launch/ \
  -H "Content-Type: application/json" \
  -u "awxcloudflare:password" \
  -d '{"extra_vars": {"ticket_number": "TICKET-123", "cloudflare_region": "TEST", "platform_id": "G000", "cloudflare_scope": "domain", "cloudflare_dry_run": "On"}}'
```

**Check job status:**
```bash
curl -s http://localhost:8081/api/v2/jobs/<JOB_ID>/ -u "awxcloudflare:password" \
  | python3 -c "import sys, json; d=json.load(sys.stdin); print(f'Status: {d[\"status\"]}')"
```

**View certificate summary:**
```bash
curl -s "http://localhost:8081/api/v2/jobs/<JOB_ID>/stdout/?format=txt" -u "awxcloudflare:password" \
  | grep -A 15 "SSL CERTIFICATE CONFIGURATION SUMMARY"
```

### File Locations

- **Platform configs:** `inventories/<REGION>/group_vars/all/platforms/<ENV>/<PLATFORM>.yml`
- **SSL certificate tasks:** `roles/linux/cloudflare/tasks/ssl_certs.yml`
- **Domain variables:** `roles/linux/cloudflare/vars/domain.yml`
- **Main playbook:** `cloudflare.yml`

### Support

For issues or questions:
1. Check job output logs in AWX
2. Review this documentation
3. Check Cloudflare API documentation
4. Contact DevOps team

---

## Appendix

### Test Results

All scopes tested and verified working:

| Scope | Status | Notes |
|-------|--------|-------|
| DNS | ✅ Passed | Job 466 - DNS record management |
| Network | ✅ Passed | Job 468 - Network configuration |
| Domain | ✅ Passed | Job 470 - SSL certificate upload (1 cert detected) |
| Notifications | ✅ Passed | Job 472 - Notification policies |

### Version History

- **v1.0** (2026-02-06): Initial SSL certificate management implementation
  - Custom credential type for SSL certificates
  - Platform-level certificate configuration
  - Dry-run and deployment modes
  - Full integration with AWX

---

**Last Updated:** February 6, 2026  
**Maintained By:** DevOps Team  
**Documentation Version:** 1.0
