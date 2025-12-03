# AWX Survey Setup Role

## Overview

Automates the creation and configuration of AWX job templates with dynamic surveys for Cloudflare DNS management. This role **auto-discovers platforms from the filesystem** and **loads domains from platform.yml**, eliminating the need to maintain duplicate configuration lists.

**Key Features:**
- **Auto-Discovery** - Scans filesystem for platform files, no manual list maintenance
- **Dynamic Surveys** - Generates AWX survey with all available platforms and domains
- **Sorted Platform List** - Orders platforms by prefix (G, L, P, S, T) and numeric value
- **Zero Duplication** - Single source of truth for platforms (filesystem) and domains (platform.yml)
- **Idempotent** - Safe to run multiple times, updates existing job template

---

## Directory Structure

```
awx_survey_setup/
├── tasks/
│   └── main.yml                 # Main task orchestration with auto-discovery
├── templates/
│   └── survey_spec.json.j2      # AWX survey specification template
├── defaults/
│   └── main.yml                 # Default variables (fallback only, deprecated)
└── README.md                    # This file
```

---

## How It Works

### 1. Platform Auto-Discovery

The role scans the filesystem for platform files instead of maintaining a hardcoded list:

```yaml
# Searches these directories
- inventories/TEST/group_vars/cloudflare/platforms/production/
- inventories/TEST/group_vars/cloudflare/platforms/staging/
- inventories/TEST/group_vars/cloudflare/platforms/global/
- inventories/TEST/group_vars/cloudflare/platforms/test/

# Finds all *.yml files
# Result: L008.yml, L012.yml, P000.yml, S009.yml, T009.yml, G000.yml, etc.
```

**Benefits:**
- Add new platform file → Automatically appears in AWX survey
- Remove platform file → Automatically removed from survey
- No manual list updates required
- Always in sync with actual configuration

### 2. Platform Sorting

Platforms are sorted by prefix and numeric value for organized dropdown:

```yaml
# Input (unsorted from filesystem)
[P019, P009, L020, L008, G000, S009, T009, G255]

# Processing
Groups by prefix: G=[G000, G255], L=[L008, L020], P=[P009, P019], S=[S009], T=[T009]
Sorts each group numerically

# Output (sorted for survey)
[G000, G255, L008, L020, P009, P019, S009, T009]
```

**Sort Order:**
1. G (Global) - G000, G255
2. L (LON/Location) - L008-L025
3. P (Production IOM) - P000-P019
4. S (Staging) - S009, S016, S017, S019
5. T (Test) - T009

### 3. Domain Loading

Domains loaded from central configuration instead of hardcoded:

```yaml
# Loaded from: inventories/TEST/group_vars/cloudflare/vars/platform.yml
cloudflare_domains:
  - name: "game-flex.eu"
    description: "Game Flex EU - European production gaming"
  - name: "game-flex.us"
    description: "Game Flex US - US production gaming"
  - name: "route-game-flex.eu"
    description: "Route Game Flex EU - IOM production gaming"
  - name: "iforium.com"
    description: "Iforium - Production, staging, and global services"
```

**Benefits:**
- Single source of truth in platform.yml
- Same domains used by Ansible roles and AWX survey
- No duplication between AWX configuration and platform config

---

## Survey Questions

The role generates 5 survey questions that integrate with inventory:

### Question 1: Platform ID

**Configuration:**
```yaml
variable: platform_id
type: multiplechoice
required: true
choices: []  # Dynamically populated from cloudflare_platforms list
```

**Purpose:** Selects which platform configuration to load from inventory

**Inventory Integration:**
- Values come from `cloudflare_platforms` list in defaults/main.yml
- Each value must have corresponding file in `inventories/{ENV}/group_vars/cloudflare/platforms/`
- Selected value becomes `platform_id` variable passed to Cloudflare role
- Cloudflare role uses this to load: `platforms/{platform_id}.yml`

**User Experience:** Dropdown showing all 26 platforms

### Question 2: Configuration Scope

**Configuration:**
```yaml
variable: cloudflare_scope
type: multiplechoice
required: true
default: "all"
choices: []  # Dynamically populated from cloudflare_scopes list
```

**Purpose:** Controls which configuration files are loaded and applied

**Inventory Integration:**
- Values come from `cloudflare_scopes` list in defaults/main.yml
- Each scope maps to specific configuration files in inventory
- Selected value determines which tasks execute in Cloudflare role
- Controls which inventory config files are loaded and applied

**User Experience:** Dropdown showing 7 scope options with descriptions

### Question 3: Zone Override

**Configuration:**
```yaml
variable: cloudflare_zone_override
type: text
required: false
default: ""
```

**Purpose:** Override automatic zone selection from platform configuration

**Inventory Integration:**
- Overrides `platform_domain` from platform file
- Overrides `effective_zone_name` computed in validate.yml
- Must match zone defined in `zone.yml`
- Useful for testing or cross-domain operations

**User Experience:** Optional text field for domain name (e.g., game-flex.eu)

### Question 4: Ticket Number

**Configuration:**
```yaml
variable: ticket_number
type: text
required: true
default: ""
```

**Purpose:** Change management tracking and compliance

**Inventory Integration:**
- Required by Cloudflare role validate.yml
- Used for audit logging and change tracking
- Not tied to specific inventory configuration
- Recorded in execution logs

**User Experience:** Required text field (e.g., JIRA-1234)

### Question 5: DNS Records Override

**Configuration:**
```yaml
variable: cloudflare_dns_records_override
type: textarea
required: false
default: ""
```

**Purpose:** Override DNS records from platform file for testing

**Inventory Integration:**
- Overrides `cloudflare_dns_records` from platform file
- Must be valid YAML list format
- Bypasses inventory platform configuration
- Used for testing without modifying inventory

**User Experience:** Optional multiline YAML input

---

## Execution Flow

### 1. Survey Generation

**Steps:**
- Load platform list from defaults/main.yml
- Load scope list from defaults/main.yml
- Render survey specification from Jinja2 template
- Build JSON with 5 question definitions
- Set validation rules and constraints
- Generate choice lists for dropdowns

**Inventory Integration:**
- Reads `cloudflare_platforms` list
- Reads `cloudflare_scopes` list
- Verifies platform files exist (optional validation)

### 2. AWX Connection

**Steps:**
- Read AWX credentials from inventory
- Connect to AWX API endpoint
- Authenticate with username/password
- Verify connection and permissions

**Inventory Integration:**
- Reads `awx_host` from credentials.yml
- Reads `awx_username` from credentials.yml
- Reads `awx_password` from credentials.yml
- Reads `awx_validate_certs` from credentials.yml

### 3. Template Location

**Steps:**
- Search for job template by name
- Verify template exists
- Get template ID for API operations
- Check current survey configuration

**Variables Used:**
- `awx_job_template_name` - Template to configure
- `awx_organization` - Organization filter

### 4. Survey Application

**Steps:**
- POST survey specification to template
- Enable survey mode on template
- Verify survey applied successfully
- Display confirmation message

**API Endpoint:**
```
POST /api/v2/job_templates/{id}/survey_spec/
```

### 5. Template Update

**Steps:**
- PATCH template to enable survey
- Set survey_enabled = true
- Verify template configuration
- Test survey accessibility

**API Endpoint:**
```
PATCH /api/v2/job_templates/{id}/
```

---

## Platform Management

### Adding New Platforms

When new platforms are added to inventory:

1. **Create Platform File**
   ```bash
   # Example: Adding platform L026
   cat > inventories/TEST/group_vars/cloudflare/platforms/L026.yml <<EOF
   ---
   platform_id: "L026"
   platform_number: "026"
   env_type: "production"
   platform_domain: "game-flex.eu"
   location: "LON"
   region: "London"
   cloudflare_dns_records:
     - name: "api-l26"
       type: "A"
       content: "192.0.2.1"
       ttl: 1
       proxied: false
   EOF
   ```

2. **Update Survey Defaults**
   ```yaml
   # In roles/linux/awx_survey_setup/defaults/main.yml
   cloudflare_platforms:
     # ... existing platforms ...
     - L026  # Add new platform
   ```

3. **Regenerate Survey**
   ```bash
   ansible-playbook awx_setup.yml \
     -i inventories/TEST/hosts \
     -e "awx_job_template_name='Cloudflare Configuration'"
   ```

### Removing Platforms

When platforms are decommissioned:

1. **Remove from Survey Defaults**
   ```yaml
   # In roles/linux/awx_survey_setup/defaults/main.yml
   cloudflare_platforms:
     # Remove decommissioned platform from list
   ```

2. **Optionally Archive Platform File**
   ```bash
   # Move instead of delete for historical reference
   mkdir -p inventories/TEST/group_vars/cloudflare/platforms/archived/
   mv inventories/TEST/group_vars/cloudflare/platforms/OLD.yml \
      inventories/TEST/group_vars/cloudflare/platforms/archived/
   ```

3. **Regenerate Survey**
   ```bash
   ansible-playbook awx_setup.yml \
     -i inventories/TEST/hosts \
     -e "awx_job_template_name='Cloudflare Configuration'"
   ```

### Platform Naming Convention

**Pattern:** `{PREFIX}{NUMBER}`

**Prefixes:**
- `L` - London/EU production platforms
- `P` - Production IOM platforms  
- `S` - Staging platforms
- `T` - Test platforms
- `G` - Global platforms

**Numbers:**
- 000-999 - Platform identifier
- Must be unique within prefix

**Domain Mapping:**
- L### (EU) → game-flex.eu
- L### (US 020-025) → game-flex.us
- P###, S###, T###, G### → iforium.com

---

## Usage Examples

### Create survey for Cloudflare job template
```bash
ansible-playbook awx_setup.yml \
  -i inventories/TEST/hosts \
  -e "awx_job_template_name='Cloudflare Configuration'" \
  -e "awx_organization='Default'"
```

**What happens:**
1. Connects to AWX using credentials from `inventories/TEST/group_vars/all/credentials.yml`
2. Loads platform list (26 platforms) from `roles/linux/awx_survey_setup/defaults/main.yml`
3. Generates survey JSON with 5 questions
4. Applies survey to "Cloudflare Configuration" job template
5. Enables survey mode on template

### Update survey with new platform list
```bash
ansible-playbook awx_setup.yml \
  -i inventories/TEST/hosts \
  -e "awx_job_template_name='Cloudflare Configuration'" \
  --tags survey_update
```

**What happens:**
1. Reads updated platform list from defaults/main.yml
2. Regenerates survey JSON
3. Updates existing survey specification
4. Platform dropdown now shows updated list

### Validate survey without changes
```bash
ansible-playbook awx_setup.yml \
  -i inventories/TEST/hosts \
  --check \
  -e "awx_job_template_name='Cloudflare Configuration'"
```

**What happens:**
1. Loads configuration from inventory
2. Validates AWX connectivity
3. Checks template exists
4. Shows what would be changed without applying

---

## Survey Template Structure

### Jinja2 Template (survey_spec.json.j2)

The template dynamically generates survey JSON:

```json
{
  "name": "{{ awx_survey_name }}",
  "description": "{{ awx_survey_description }}",
  "spec": [
    {
      "question_name": "Platform ID",
      "question_description": "Select the platform to configure",
      "required": true,
      "type": "multiplechoice",
      "variable": "platform_id",
      "choices": {{ cloudflare_platforms | to_json }},
      "default": ""
    },
    {
      "question_name": "Configuration Scope",
      "question_description": "Select what to configure",
      "required": true,
      "type": "multiplechoice",
      "variable": "cloudflare_scope",
      "choices": {{ cloudflare_scopes | map(attribute='value') | list | to_json }},
      "default": "all"
    }
    // ... additional questions ...
  ]
}
```

**Inventory Integration:**
- `cloudflare_platforms` list from defaults/main.yml populates platform choices
- `cloudflare_scopes` list from defaults/main.yml populates scope choices
- Template ensures survey stays synchronized with available platforms
- Changes to defaults/main.yml automatically update survey on next run

---

## Best Practices

### Survey Design
- Keep platform list synchronized with inventory platform files
- Use descriptive choice labels for clarity
- Set sensible defaults for optional fields
- Enforce required fields for compliance tracking
- Provide help text for complex questions
- Test survey in AWX UI after generation

### Platform Management
- Update survey defaults when adding/removing platforms
- Verify platform file exists before adding to survey
- Group platforms by environment in defaults for readability
- Document platform purpose in platform file comments
- Maintain naming convention consistency

### Inventory Synchronization
- Run survey setup after inventory changes
- Validate platform files exist before regenerating survey
- Test new platforms in TEST environment first
- Keep defaults/main.yml as source of truth for platforms
- Version control all survey configuration changes

### Change Control
- Version control survey template changes
- Test survey updates in non-production AWX first
- Maintain audit trail of survey modifications
- Coordinate survey updates with platform deployments
- Document survey changes in commit messages

### Security
- Store AWX credentials in Ansible Vault
- Use dedicated service account for automation
- Limit API token scope to minimum required
- Enable certificate validation in production
- Rotate credentials regularly
- Restrict survey editing permissions in AWX

---

## Integration with Cloudflare Role

### Variable Flow

Survey submission creates variables that flow through inventory to Cloudflare role:

```
AWX Survey Submission
    ↓
Survey Variables (platform_id, cloudflare_scope, ticket_number, etc.)
    ↓
Job Template Extra Vars
    ↓
Ansible Playbook Execution
    ↓
Cloudflare Role (validate.yml)
    ↓
Dynamic Platform File Loading
    ↓
inventories/{ENV}/group_vars/cloudflare/platforms/{platform_id}.yml
    ↓
Configuration Application
```

### Example Flow

**User Action:** Selects P016 from survey, scope=dns, ticket=JIRA-1234

**Variable Passing:**
```yaml
platform_id: "P016"
cloudflare_scope: "dns"
ticket_number: "JIRA-1234"
```

**Inventory Loading:**
1. Playbook starts with IOM inventory
2. Loads credentials from `inventories/IOM/group_vars/all/credentials.yml`
3. Loads zone config from `inventories/IOM/group_vars/cloudflare/vars/zone.yml`
4. validate.yml dynamically loads `inventories/IOM/group_vars/cloudflare/platforms/production/P016.yml`

**Configuration Extracted:**
```yaml
platform_domain: "iforium.com"
cloudflare_dns_records:
  - name: "api-p16"
    type: "A"
    content: "195.68.198.50"
    ttl: 1
    proxied: false
```

**Execution:**
1. DNS records created on iforium.com zone
2. Only DNS scope runs (other scopes skipped)
3. Ticket JIRA-1234 logged for audit

---

## Troubleshooting

### Survey Not Appearing in AWX

**Symptoms:** Template exists but survey not visible

**Causes:**
- survey_enabled flag not set
- JSON structure invalid
- Template permissions issue

**Solutions:**
```bash
# Verify template exists
curl -u awxcloudflare:password http://localhost:8081/api/v2/job_templates/ | jq '.results[] | select(.name=="Cloudflare Configuration")'

# Check survey_enabled
curl -u awxcloudflare:password http://localhost:8081/api/v2/job_templates/{ID}/ | jq '.survey_enabled'

# Validate JSON structure
cat roles/linux/awx_survey_setup/templates/survey_spec.json.j2 | jq .
```

### Platform List Out of Sync

**Symptoms:** Survey shows platforms that don't exist in inventory

**Causes:**
- defaults/main.yml not updated
- Platform files removed but not from survey
- Survey not regenerated after changes

**Solutions:**
```bash
# List all platform files
find inventories/TEST/group_vars/cloudflare/platforms/ -name "*.yml" -exec basename {} .yml \;

# Compare with survey defaults
grep "^  - " roles/linux/awx_survey_setup/defaults/main.yml

# Regenerate survey
ansible-playbook awx_setup.yml -i inventories/TEST/hosts -e "awx_job_template_name='Cloudflare Configuration'"
```

### API Connection Failures

**Symptoms:** Cannot connect to AWX API

**Causes:**
- AWX service not running
- Wrong host/port in credentials
- Authentication failure
- Network/firewall issues

**Solutions:**
```bash
# Test AWX connectivity
curl -s http://localhost:8081/api/v2/ping/ | jq .

# Verify credentials
grep -A3 "awx_" inventories/TEST/group_vars/all/credentials.yml

# Check port forward (if using k3d)
kubectl port-forward -n awx svc/awx-service 8081:80 &
```

### Survey Validation Errors

**Symptoms:** Survey fails to apply, validation errors

**Causes:**
- Required fields missing
- Invalid variable names
- Choice values malformed
- JSON syntax errors

**Solutions:**
```bash
# Validate JSON syntax
ansible-playbook awx_setup.yml -i inventories/TEST/hosts --syntax-check

# Test template rendering
ansible localhost -m template -a "src=roles/linux/awx_survey_setup/templates/survey_spec.json.j2 dest=/tmp/survey.json" -e "@roles/linux/awx_survey_setup/defaults/main.yml"

# Validate generated JSON
jq . /tmp/survey.json
```

### Platform File Not Found Error

**Symptoms:** Cloudflare role fails when loading platform config

**Causes:**
- Platform in survey but file doesn't exist
- Typo in platform_id
- Platform file in wrong directory
- Platform not in inventory being used

**Solutions:**
```bash
# Check if platform file exists
ls -la inventories/IOM/group_vars/cloudflare/platforms/production/P016.yml

# Verify platform directory structure
tree inventories/IOM/group_vars/cloudflare/platforms/

# Check which inventory is being used
ansible-inventory -i inventories/IOM/hosts --list | grep -A20 cloudflare
```

---

## Related Documentation

- Cloudflare Role: `roles/linux/cloudflare/README.md`
- Main README: `/README.md`
- AWX Setup Guide: `/README-awx-k3d.md`
- Validation Framework: `/README-validation.md`

---
