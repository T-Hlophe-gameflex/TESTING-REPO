# Custom SSL Certificate Testing Guide

## Overview
This guide explains how to test custom SSL certificate upload functionality for Cloudflare domains.

## What's Been Implemented

### New Files
1. **`test_custom_certificate.yml`** - Sample certificate configuration with test data
2. **`test_custom_certificate.sh`** - Automated test script for certificate upload
3. **`roles/linux/cloudflare/tasks/ssl_certs.yml`** - Certificate management tasks

### Features
- ✅ Upload custom SSL certificates to Cloudflare
- ✅ List existing custom certificates
- ✅ Support for certificate bundles (intermediate certificates)
- ✅ Geo-restriction configuration
- ✅ Dry-run mode for safe testing
- ✅ Support for both API Token and Global API Key authentication

## Testing Options

### Option 1: Quick Test with Sample Data (Recommended First Step)

The `test_custom_certificate.yml` contains a **test/sample certificate** (not a real one) for preview testing:

```bash
./test_custom_certificate.sh
```

This runs in **DRY-RUN mode** - it shows what would happen without making changes.

**Expected Output:**
```
====================================================================
🔒 CUSTOM SSL CERTIFICATES - DRY RUN MODE
====================================================================
Would check for existing certificates on domain: route-game-flex.eu
Custom certificates to upload: 1
Certificates preview:
  - Certificate 1: Present (826 chars)
  - Private Key: Present (625 chars)
  - Bundle: None
====================================================================
```

### Option 2: Test with Real Certificate

To test with a **real SSL certificate**:

#### Step 1: Obtain an SSL Certificate

**Option A: Use Let's Encrypt (Free)**
```bash
# Install certbot
brew install certbot  # macOS
# or
apt-get install certbot  # Linux

# Generate certificate (requires domain ownership verification)
sudo certbot certonly --manual --preferred-challenges dns \
  -d route-game-flex.eu \
  -d "*.route-game-flex.eu"

# Certificates will be in: /etc/letsencrypt/live/route-game-flex.eu/
```

**Option B: Use Existing Certificate**
If you already have a certificate from a CA (DigiCert, Sectigo, etc.), use those files.

#### Step 2: Update Configuration

Edit `test_custom_certificate.yml`:

```yaml
test_custom_certificate:
  certificate: |
    -----BEGIN CERTIFICATE-----
    [Your actual certificate content here]
    -----END CERTIFICATE-----
  
  private_key: |
    -----BEGIN PRIVATE KEY-----
    [Your actual private key here]
    -----END PRIVATE KEY-----
  
  # Optional: Intermediate certificates
  bundle: |
    -----BEGIN CERTIFICATE-----
    [Intermediate certificate 1]
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    [Intermediate certificate 2]
    -----END CERTIFICATE-----
```

#### Step 3: Add to Platform Configuration

Edit your platform file (e.g., `inventories/TEST/group_vars/all/platforms/global/G000.yml`):

```yaml
# Add this section to enable custom certificate upload
cloudflare_domain_ssl:
  ssl_mode: "full_strict"
  min_tls_version: "1.2"
  universal_ssl_enabled: true
  custom_certificates:
    - certificate: "{{ test_custom_certificate.certificate }}"
      private_key: "{{ test_custom_certificate.private_key }}"
      bundle: "{{ test_custom_certificate.bundle | default('') }}"
      bundle_method: "ubiquitous"  # or "optimal" or "force"
```

#### Step 4: Test in Dry-Run Mode

```bash
ansible-playbook cloudflare.yml \
    -i inventories/TEST/hosts \
    --limit cloudflare \
    --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" \
    -e "cloudflare_dry_run=On" \
    -e "selected_platform=G000" \
    -e "@test_custom_certificate.yml"
```

#### Step 5: Deploy (If Dry-Run Looks Good)

```bash
ansible-playbook cloudflare.yml \
    -i inventories/TEST/hosts \
    --limit cloudflare \
    --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" \
    -e "cloudflare_dry_run=Off" \
    -e "selected_platform=G000" \
    -e "@test_custom_certificate.yml"
```

### Option 3: Via AWX (Once Credentials Are Fixed)

1. **Fix AWX Credentials** (see [AWX Credential Fix Guide](#awx-credential-fix))
2. **Add Certificate to Platform Config** in your repository
3. **Run AWX Job** with:
   - Job Template: `Cloudflare-Deployment`
   - Survey: Select platform (e.g., G000)
   - Extra Variables:
     ```yaml
     cloudflare_scope: ssl
     cloudflare_dry_run: "Off"
     ```

## Certificate Bundle Methods

Cloudflare supports three bundle methods:

- **`ubiquitous`** (default) - Most compatible, works with all browsers
- **`optimal`** - Modern browsers only, smaller size
- **`force`** - Use exact bundle provided, no modifications

## Geo-Restrictions (Optional)

Restrict certificate usage by region:

```yaml
custom_certificates:
  - certificate: "..."
    private_key: "..."
    geo_restrictions:
      label: "US-Only Certificate"
      regions:
        - "us"
        - "ca"
```

## API Endpoints Used

The implementation uses these Cloudflare API endpoints:

1. **List Custom Certificates**
   ```
   GET /zones/{zone_id}/custom_certificates
   ```

2. **Upload Custom Certificate**
   ```
   POST /zones/{zone_id}/custom_certificates
   ```

3. **Set SSL Mode**
   ```
   PATCH /zones/{zone_id}/settings/ssl
   ```

## Security Best Practices

⚠️ **IMPORTANT SECURITY NOTES:**

1. **Never commit private keys to Git**
   - Use Ansible Vault for production: `ansible-vault encrypt test_custom_certificate.yml`
   - Or store in AWX credentials as encrypted values

2. **Test certificates are not secure**
   - The sample certificate in `test_custom_certificate.yml` is fake
   - Always use certificates from trusted CAs in production

3. **Protect certificate files**
   ```bash
   chmod 600 test_custom_certificate.yml  # Read/write for owner only
   ```

4. **Use strong key sizes**
   - Minimum 2048-bit RSA
   - Prefer 4096-bit RSA or ECDSA P-256

## Troubleshooting

### Error: "Certificate validation failed"
- **Cause**: Certificate and private key don't match
- **Solution**: Verify you're using the correct private key for the certificate

### Error: "Invalid certificate format"
- **Cause**: Certificate not in PEM format
- **Solution**: Convert certificate:
  ```bash
  openssl x509 -in cert.der -inform DER -out cert.pem -outform PEM
  ```

### Error: "Bundle required"
- **Cause**: Certificate chain incomplete
- **Solution**: Add intermediate certificates to `bundle` field

### Certificate not appearing in Cloudflare dashboard
- **Cause**: May take a few minutes to propagate
- **Solution**: Wait 2-3 minutes, then check Zone → SSL/TLS → Edge Certificates

## AWX Credential Fix

Before using AWX to deploy certificates, fix the credential configuration:

1. Login to AWX: http://localhost:8081 (username: `admin`)
2. Navigate to **Administration → Credential Types**
3. Edit **Cloudflare API** credential type
4. Remove `cloudflare_api_email` and `cloudflare_api_key` from **REQUIRED** fields
5. Keep them as optional (in FIELDS but not in REQUIRED)
6. Save
7. Navigate to **Resources → Credentials**
8. Edit **Cloudflare-API-Token** credential
9. Fill in:
   - **Cloudflare API Token**: `532feb7bc2386bceec9bd98dd022300fc1b72`
   - **Cloudflare Account ID**: `a8150e633a23cca7a4137979160b96c6`
   - Leave email/key blank
10. Save

## Verification

After successful upload, verify in Cloudflare:

1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select your domain
3. Go to **SSL/TLS → Edge Certificates**
4. Look for your custom certificate in the **Custom Certificates** section

You should see:
- Certificate ID
- Hostnames covered
- Expiration date
- Status (Active)

## Next Steps

1. **Test Sample Certificate** (dry-run): `./test_custom_certificate.sh`
2. **Review Output** to understand the process
3. **Get Real Certificate** from Let's Encrypt or your CA
4. **Update Configuration** with real certificate data
5. **Test in Dry-Run** mode first
6. **Deploy** when confident

## Additional Resources

- [Cloudflare Custom SSL Documentation](https://developers.cloudflare.com/ssl/edge-certificates/custom-certificates/)
- [Let's Encrypt Documentation](https://letsencrypt.org/getting-started/)
- [OpenSSL Certificate Guide](https://www.openssl.org/docs/man1.1.1/man1/openssl-x509.html)
