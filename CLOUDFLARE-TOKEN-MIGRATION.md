# Cloudflare API Token Migration Guide

## Overview

This repository now supports both **API Token** (recommended) and **API Key** (legacy) authentication methods for Cloudflare API calls.

---

## Authentication Methods

### Option 1: API Token (Recommended) ✅

**Advantages:**
- More secure - scoped permissions
- Can be limited to specific zones
- Can set expiration dates
- Easier to rotate
- No email required

**Required Permissions:**
```
Zone.Zone - Read
Zone.DNS - Edit
Zone.Zone Settings - Edit
Zone.SSL and Certificates - Edit
Zone.Firewall Services - Edit
Zone.Cache Purge - Purge
Account.Account Settings - Read
Account.Account Health Checks - Edit
Account.Account Rulesets - Edit
```

**Environment Variables:**
```bash
export CLOUDFLARE_API_TOKEN="your-api-token-here"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
```

### Option 2: API Key (Legacy)

**Disadvantages:**
- Global permissions (full account access)
- Requires email address
- Less secure
- No permission scoping

**Environment Variables:**
```bash
export CLOUDFLARE_API_EMAIL="your-email@example.com"
export CLOUDFLARE_API_KEY="your-global-api-key"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
```

---

## How to Create a Cloudflare API Token

1. **Log into Cloudflare Dashboard**
   - Go to https://dash.cloudflare.com

2. **Navigate to API Tokens**
   - Click on your profile icon (top right)
   - Select "My Profile"
   - Click "API Tokens" in the left sidebar

3. **Create Token**
   - Click "Create Token"
   - Choose "Create Custom Token"

4. **Configure Permissions**
   ```
   Permissions:
   - Zone > Zone > Read
   - Zone > DNS > Edit
   - Zone > Zone Settings > Edit
   - Zone > SSL and Certificates > Edit
   - Zone > Firewall Services > Edit
   - Zone > Cache Purge > Purge
   - Account > Account Settings > Read
   - Account > Account Rulesets > Edit
   - Account > Account Health Checks > Edit
   ```

5. **Set Zone Resources**
   - Include > Specific Zone > Select your domains
   - Or: Include > All zones from an account

6. **Set IP Address Filtering** (Optional)
   - Add your AWX server IP
   - Add your office/VPN IPs

7. **Set TTL** (Optional)
   - Set expiration date for token rotation

8. **Create and Save Token**
   - Click "Continue to summary"
   - Click "Create Token"
   - **COPY THE TOKEN** (shown only once!)

---

## Usage in AWX

### Setting Up Credentials in AWX

1. **Create Custom Credential Type** (if not exists)
   ```yaml
   Name: Cloudflare API Token
   Input Configuration:
   fields:
     - id: cloudflare_api_token
       type: string
       label: Cloudflare API Token
       secret: true
     - id: cloudflare_account_id
       type: string
       label: Cloudflare Account ID
   
   Injector Configuration:
   env:
     CLOUDFLARE_API_TOKEN: '{{ cloudflare_api_token }}'
     CLOUDFLARE_ACCOUNT_ID: '{{ cloudflare_account_id }}'
   ```

2. **Create Credential**
   - Resources > Credentials > Add
   - Name: "Cloudflare-API-Token"
   - Credential Type: "Cloudflare API Token"
   - Fill in token and account ID
   - Save

3. **Update Job Template**
   - Edit "Cloudflare-Deployment" template
   - Add credential: "Cloudflare-API-Token"
   - Save

---

## Local Development

### Using API Token
```bash
# Set environment variables
export CLOUDFLARE_API_TOKEN="your-token-here"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"

# Run playbook
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
  -e "platform_id=T009" \
  -e "cloudflare_zone_name=iforium.com" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=TEST-001"
```

### Using API Key (Legacy)
```bash
# Set environment variables
export CLOUDFLARE_API_EMAIL="your-email@example.com"
export CLOUDFLARE_API_KEY="your-global-api-key"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"

# Run playbook
ansible-playbook cloudflare.yml -i inventories/TEST/hosts \
  -e "platform_id=T009" \
  -e "cloudflare_zone_name=iforium.com" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=TEST-001"
```

---

## How It Works

The playbook automatically detects which authentication method to use:

1. **Check for API Token**
   - If `CLOUDFLARE_API_TOKEN` is set → Use Token authentication
   - Headers: `Authorization: Bearer <token>`

2. **Fall back to API Key**
   - If token not set → Use API Key authentication
   - Headers: `X-Auth-Email` and `X-Auth-Key`

3. **Validation**
   - Ensures required credentials are present
   - Shows which method is being used
   - Fails with clear message if credentials missing

---

## Migration Path

### For Existing Deployments

**Step 1: Create API Token**
- Follow "How to Create a Cloudflare API Token" above

**Step 2: Test with Token**
```bash
# Test locally first
export CLOUDFLARE_API_TOKEN="new-token"
export CLOUDFLARE_ACCOUNT_ID="account-id"
ansible-playbook cloudflare.yml -i inventories/TEST/hosts --check \
  -e "platform_id=T009" \
  -e "cloudflare_zone_name=iforium.com" \
  -e "cloudflare_scope=dns" \
  -e "ticket_number=TEST-001"
```

**Step 3: Update AWX Credentials**
- Create new "Cloudflare API Token" credential
- Update job template to use new credential
- Test in AWX

**Step 4: Remove API Key** (Optional)
- Once token is working, remove API Key credentials
- Update any documentation referencing API Keys

### No Downtime

- Both methods work simultaneously
- Can switch between them without code changes
- Gradual migration per environment possible

---

## Troubleshooting

### Error: "Missing required variables: cloudflare_api_token"

**Cause:** API Token not set in environment or AWX credential

**Solution:**
```bash
# Verify token is set
echo $CLOUDFLARE_API_TOKEN

# If empty, set it:
export CLOUDFLARE_API_TOKEN="your-token"
```

### Error: "401 Unauthorized"

**Cause:** Invalid token or insufficient permissions

**Solution:**
1. Verify token is correct
2. Check token hasn't expired
3. Verify token has required permissions (see list above)
4. Test token with curl:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json"
```

### Error: "403 Forbidden"

**Cause:** Token doesn't have permission for the operation

**Solution:**
- Edit token in Cloudflare dashboard
- Add missing permissions
- Regenerate if needed

---

## Security Best Practices

1. **Use API Tokens, Not API Keys**
   - Tokens are more secure
   - Scoped permissions limit damage if compromised

2. **Set Token Expiration**
   - Rotate tokens regularly (e.g., every 90 days)
   - Set expiration dates on tokens

3. **Limit IP Access**
   - Restrict token usage to specific IPs
   - Add AWX server IP and your office/VPN IPs

4. **Store in Secrets Manager**
   - Use AWX credentials (encrypted)
   - Or GitHub Secrets for CI/CD
   - Never commit tokens to Git

5. **Monitor Token Usage**
   - Review Cloudflare audit logs
   - Disable unused tokens
   - Investigate suspicious activity

6. **Principle of Least Privilege**
   - Only grant permissions needed
   - Create separate tokens per application/environment if needed

---

## Testing Token Permissions

Test your token has correct permissions:

```bash
# Test authentication
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"

# Test zone access
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"

# Test DNS record read
curl -X GET "https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

Expected response: `"success": true`

---

## Comparison Table

| Feature | API Token | API Key |
|---------|-----------|---------|
| **Security** | ✅ High (scoped) | ❌ Low (global) |
| **Permissions** | ✅ Granular | ❌ All-or-nothing |
| **Expiration** | ✅ Configurable | ❌ Never expires |
| **IP Restrictions** | ✅ Supported | ❌ Not supported |
| **Rotation** | ✅ Easy | ⚠️ Difficult |
| **Email Required** | ✅ No | ❌ Yes |
| **Audit Trail** | ✅ Per-token | ⚠️ Per-account |
| **Recommended** | ✅ Yes | ❌ No (legacy) |

---

## Related Documentation

- **Cloudflare API Docs:** https://developers.cloudflare.com/fundamentals/api/get-started/
- **Creating API Tokens:** https://developers.cloudflare.com/fundamentals/api/get-started/create-token/
- **Configuration Scope Guide:** `CONFIGURATION-SCOPE-GUIDE.md`
- **AWX Setup README:** `roles/linux/awx_survey_setup/README.md`

---

**Document Version:** 1.0  
**Last Updated:** December 8, 2025  
**Maintained By:** DevOps Team
