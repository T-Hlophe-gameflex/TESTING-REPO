# ✅ Custom SSL Certificate Testing - Implementation Complete

## Summary

I've implemented full custom SSL certificate upload functionality for Cloudflare domains. You can now test certificate uploads both locally and via AWX (once credentials are fixed).

## What Was Created

### 1. **Certificate Management Tasks** (`roles/linux/cloudflare/tasks/ssl_certs.yml`)
- Upload custom SSL certificates to Cloudflare
- List existing certificates
- Configure SSL/TLS mode and minimum TLS version
- Support for certificate bundles (intermediate certificates)
- Geo-restriction configuration
- Full dry-run mode support

### 2. **Test Configuration** (`test_custom_certificate.yml`)
- Sample certificate structure showing the format
- Includes test certificate and private key (not real, for demo only)
- Shows how to configure bundle and geo-restrictions

### 3. **Automated Test Script** (`test_custom_certificate.sh`)
- One-command test execution
- Runs in safe dry-run mode by default
- Includes instructions for real certificate deployment

### 4. **Documentation** (`SSL_CERTIFICATE_TESTING.md`)
- Complete guide for certificate testing
- How to obtain SSL certificates (Let's Encrypt, commercial CAs)
- Security best practices
- Troubleshooting guide
- AWX integration instructions

## Test Results

```
✅ Test Run Successful (Dry-Run Mode)

Domain: route-game-flex.eu
SSL Mode: full_strict
Universal SSL: Enabled
Min TLS Version: 1.2
Custom Certificates: 1

Certificate Details:
  - Certificate 1: Present (921 bytes)
  - Private Key: Present (662 bytes)
  - Bundle: None
  - Bundle Method: ubiquitous

Mode: DRY-RUN (Preview Only)
```

## How to Test

### Quick Test (Sample Certificate)
```bash
./test_custom_certificate.sh
```

This shows what would happen without making changes. Perfect for understanding the process.

### Test with Real Certificate

#### 1. Get a Certificate

**Option A: Let's Encrypt (Free)**
```bash
brew install certbot
sudo certbot certonly --manual --preferred-challenges dns \
  -d route-game-flex.eu -d "*.route-game-flex.eu"
```

**Option B: Use Existing Certificate**
If you have a certificate from DigiCert, Sectigo, etc., use those files.

#### 2. Update Configuration

Edit `test_custom_certificate.yml`:
```yaml
test_custom_certificate:
  certificate: |
    -----BEGIN CERTIFICATE-----
    [Your actual certificate]
    -----END CERTIFICATE-----
  
  private_key: |
    -----BEGIN PRIVATE KEY-----
    [Your actual private key]
    -----END PRIVATE KEY-----
```

#### 3. Test in Dry-Run
```bash
./test_custom_certificate.sh
```

#### 4. Deploy
```bash
ansible-playbook cloudflare.yml \
    -i inventories/TEST/hosts \
    --limit cloudflare \
    --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" \
    -e "cloudflare_dry_run=Off" \
    -e "selected_platform=G000" \
    -e "cloudflare_domain=route-game-flex.eu" \
    -e "@test_custom_certificate.yml"
```

## Integration with AWX

The certificate management is already integrated into the cloudflare role and will work via AWX once credentials are fixed.

### To use via AWX:

1. **Fix AWX Credentials** (one-time setup):
   - Login: http://localhost:8081 (admin/your-password)
   - Go to: Administration → Credential Types
   - Edit: "Cloudflare API"
   - Remove `cloudflare_api_email` and `cloudflare_api_key` from **required** fields
   - Save
   - Go to: Resources → Credentials
   - Edit: "Cloudflare-API-Token"
   - Fill in Token and Account ID
   - Save

2. **Add Certificate to Platform Config**:
   Edit `inventories/TEST/group_vars/all/platforms/global/G000.yml`:
   ```yaml
   cloudflare_domain_ssl:
     ssl_mode: "full_strict"
     min_tls_version: "1.2"
     universal_ssl_enabled: true
     custom_certificates:
       - certificate: "{{ lookup('file', 'certs/mycert.pem') }}"
         private_key: "{{ lookup('file', 'certs/mykey.pem') }}"
   ```

3. **Run AWX Job**:
   - Template: "Cloudflare-Deployment"
   - Platform: "G000"
   - Scope: Select "ssl" or "all"
   - Dry Run: Choose "On" first, then "Off" to deploy

## API Endpoints Used

The implementation uses Cloudflare's official API v4:

1. **GET** `/zones/{zone_id}/custom_certificates` - List existing certificates
2. **POST** `/zones/{zone_id}/custom_certificates` - Upload new certificate
3. **PATCH** `/zones/{zone_id}/settings/ssl` - Configure SSL/TLS mode

All endpoints support both authentication methods:
- API Token (recommended): `Authorization: Bearer {token}`
- Global API Key (legacy): `X-Auth-Email` + `X-Auth-Key` headers

## Security Notes

⚠️ **Important:**

1. **Never commit real private keys to Git**
   - Use Ansible Vault: `ansible-vault encrypt test_custom_certificate.yml`
   - Or store in AWX as encrypted credentials

2. **Test certificate is not secure**
   - The sample in `test_custom_certificate.yml` is fake
   - Always use real certificates from trusted CAs

3. **Protect certificate files**
   ```bash
   chmod 600 test_custom_certificate.yml
   ```

4. **Use strong encryption**
   - Minimum 2048-bit RSA (prefer 4096-bit)
   - Or ECDSA P-256/P-384

## Verification

After deploying a certificate:

1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select domain: route-game-flex.eu
3. Go to: **SSL/TLS → Edge Certificates**
4. Look for your certificate in **Custom Certificates** section

You should see:
- ✅ Certificate ID
- ✅ Hostnames covered
- ✅ Expiration date
- ✅ Status: Active

## Next Steps

**Immediate:**
1. ✅ Test with sample certificate (done - working!)
2. 🔄 Fix AWX credentials (manual step required)
3. 📝 Commit new files to repository

**When Ready to Deploy Real Certificate:**
1. Obtain SSL certificate from Let's Encrypt or CA
2. Update `test_custom_certificate.yml` with real certificate
3. Test in dry-run mode
4. Deploy via AWX or local playbook

## Files Modified/Created

```
✅ roles/linux/cloudflare/tasks/ssl_certs.yml         (NEW - certificate management)
✅ roles/linux/cloudflare/tasks/main.yml              (MODIFIED - added ssl_certs import)
✅ test_custom_certificate.yml                         (NEW - sample config)
✅ test_custom_certificate.sh                          (NEW - test script)
✅ SSL_CERTIFICATE_TESTING.md                          (NEW - full documentation)
✅ SSL_CERTIFICATE_IMPLEMENTATION.md                   (NEW - this summary)
```

## Command Reference

```bash
# Quick test (dry-run)
./test_custom_certificate.sh

# Test with real cert (dry-run)
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
    --limit cloudflare --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" -e "cloudflare_dry_run=On" \
    -e "selected_platform=G000" -e "cloudflare_domain=route-game-flex.eu" \
    -e "@test_custom_certificate.yml"

# Deploy real cert
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
    --limit cloudflare --tags cloudflare_certificates \
    -e "cloudflare_scope=ssl" -e "cloudflare_dry_run=Off" \
    -e "selected_platform=G000" -e "cloudflare_domain=route-game-flex.eu" \
    -e "@test_custom_certificate.yml"

# Encrypt certificate file
ansible-vault encrypt test_custom_certificate.yml

# Run with encrypted file
ansible-playbook cloudflare.yml ... --ask-vault-pass
```

## Support

For questions or issues:
1. Check `SSL_CERTIFICATE_TESTING.md` for detailed guide
2. Review Cloudflare API docs: https://developers.cloudflare.com/ssl/
3. Test in dry-run mode first to preview changes

---

**Status**: ✅ **READY FOR TESTING**

You can now test custom certificate uploads! Start with the sample certificate (safe, no changes), then move to real certificates when ready.
