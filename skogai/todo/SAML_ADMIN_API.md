# SAML Admin API Reference

Complete API reference for managing SAML SSO providers in self-hosted Supabase via the GoTrue Admin API.

> **Important**: This API requires admin-level authentication using the Service Role key. Never expose this key in client-side code.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Endpoints](#endpoints)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Examples](#examples)
- [Rate Limiting](#rate-limiting)

---

## Overview

The SAML Admin API allows you to programmatically manage SAML Identity Provider configurations in your self-hosted Supabase instance. All operations require admin authentication via Service Role key.

### Base URL

```
http://localhost:8000/auth/v1    # Local development
https://your-domain.com/auth/v1  # Production
```

### Content Type

All requests must use JSON:

```
Content-Type: application/json
```

---

## Authentication

All Admin API requests must include the Service Role key in the Authorization header.

### Service Role Key

```bash
# Set your service role key
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Include in all requests
Authorization: Bearer ${SERVICE_ROLE_KEY}
```

### Finding Your Service Role Key

**Local Development:**
```bash
# In your Supabase project
cat .env | grep SERVICE_ROLE_KEY

# OR from config
supabase status
```

**Production:**
- Located in your secure secret management system
- Never commit to version control
- Rotate periodically for security

---

## Endpoints

### List SSO Providers

Get all configured SSO providers (SAML and OIDC).

**Endpoint:**
```
GET /admin/sso/providers
```

**Headers:**
```
Authorization: Bearer {service_role_key}
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `per_page` | integer | No | Items per page (default: 50, max: 100) |

**Response:**

```json
{
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000001",
      "type": "saml",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "domains": ["example.com"],
      "metadata_url": "https://idp.example.com/saml/metadata",
      "attribute_mapping": {
        "keys": {
          "email": "Email",
          "name": "FullName"
        }
      }
    }
  ],
  "total": 1,
  "page": 1,
  "per_page": 50
}
```

**cURL Example:**

```bash
curl -X GET "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json"
```

---

### Get SSO Provider

Retrieve details of a specific SSO provider.

**Endpoint:**
```
GET /admin/sso/providers/{provider_id}
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider_id` | UUID | Yes | Unique provider identifier |

**Headers:**
```
Authorization: Bearer {service_role_key}
```

**Response:**

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "type": "saml",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "domains": ["example.com", "subdomain.example.com"],
  "metadata_url": "https://idp.example.com/saml/metadata",
  "metadata_xml": "<?xml version=\"1.0\"?>...",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  },
  "idp_entity_id": "https://idp.example.com/saml/metadata",
  "idp_sso_url": "https://idp.example.com/saml/SSO"
}
```

**cURL Example:**

```bash
PROVIDER_ID="00000000-0000-0000-0000-000000000001"

curl -X GET "http://localhost:8000/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json"
```

---

### Create SSO Provider

Register a new SAML Identity Provider.

**Endpoint:**
```
POST /admin/sso/providers
```

**Headers:**
```
Authorization: Bearer {service_role_key}
Content-Type: application/json
```

**Request Body:**

```json
{
  "type": "saml",
  "domains": ["example.com"],
  "metadata_url": "https://idp.example.com/saml/metadata",
  "metadata_xml": "<?xml version=\"1.0\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\"...",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  }
}
```

**Required Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Must be `"saml"` |
| `domains` | array | Email domains for this provider |
| `metadata_url` OR `metadata_xml` | string | IdP metadata (one required) |
| `attribute_mapping` | object | SAML attribute mapping configuration |

**Optional Fields:**

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `name_id_format` | string | SAML NameID format | `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress` |
| `skip_url_validation` | boolean | Skip metadata URL validation | `false` |

**Response:**

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "type": "saml",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "domains": ["example.com"],
  "metadata_url": "https://idp.example.com/saml/metadata",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  },
  "idp_entity_id": "https://idp.example.com/saml/metadata",
  "idp_sso_url": "https://idp.example.com/saml/SSO"
}
```

**cURL Example:**

```bash
# With metadata URL
curl -X POST "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "domains": ["example.com"],
    "metadata_url": "https://instance.zitadel.cloud/saml/v2/metadata",
    "attribute_mapping": {
      "keys": {
        "email": "Email",
        "name": "FullName"
      }
    }
  }'

# With metadata XML (full example)
cat > /tmp/provider.json <<'EOF'
{
  "type": "saml",
  "domains": ["example.com"],
  "metadata_xml": "<?xml version=\"1.0\"?>\n<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" entityID=\"https://idp.example.com\">\n  <IDPSSODescriptor>\n    <KeyDescriptor use=\"signing\">\n      <X509Certificate>MIIDXTCCAkWgAwIB...</X509Certificate>\n    </KeyDescriptor>\n    <SingleSignOnService Binding=\"urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST\" Location=\"https://idp.example.com/saml/SSO\"/>\n  </IDPSSODescriptor>\n</EntityDescriptor>",
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "first_name": "FirstName",
      "last_name": "SurName"
    }
  }
}
EOF

curl -X POST "http://localhost:8000/auth/v1/admin/sso/providers" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d @/tmp/provider.json
```

---

### Update SSO Provider

Update an existing SAML provider configuration.

**Endpoint:**
```
PUT /admin/sso/providers/{provider_id}
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider_id` | UUID | Yes | Provider identifier |

**Headers:**
```
Authorization: Bearer {service_role_key}
Content-Type: application/json
```

**Request Body:**

```json
{
  "domains": ["example.com", "another.com"],
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "department": "Department"
    }
  }
}
```

**Updatable Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `domains` | array | Email domains |
| `metadata_url` | string | New metadata URL |
| `metadata_xml` | string | Updated metadata XML |
| `attribute_mapping` | object | Updated attribute mapping |

**Response:**

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "type": "saml",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-02T00:00:00Z",
  "domains": ["example.com", "another.com"],
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "department": "Department"
    }
  }
}
```

**cURL Example:**

```bash
PROVIDER_ID="00000000-0000-0000-0000-000000000001"

curl -X PUT "http://localhost:8000/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "attribute_mapping": {
      "keys": {
        "email": "Email",
        "name": "FullName",
        "groups": "Groups"
      }
    }
  }'
```

---

### Delete SSO Provider

Remove a SAML provider configuration.

**Endpoint:**
```
DELETE /admin/sso/providers/{provider_id}
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `provider_id` | UUID | Yes | Provider identifier |

**Headers:**
```
Authorization: Bearer {service_role_key}
```

**Response:**

```
204 No Content
```

**cURL Example:**

```bash
PROVIDER_ID="00000000-0000-0000-0000-000000000001"

curl -X DELETE "http://localhost:8000/auth/v1/admin/sso/providers/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

**Note:** Deleting a provider does not delete existing users authenticated via this provider. They will remain in the database but cannot authenticate via SSO until a new provider is configured.

---

## Data Models

### SSO Provider Object

```typescript
interface SSOProvider {
  id: string;                    // UUID
  type: "saml";                  // Provider type
  created_at: string;            // ISO 8601 timestamp
  updated_at: string;            // ISO 8601 timestamp
  domains: string[];             // Email domains
  metadata_url?: string;         // IdP metadata URL
  metadata_xml?: string;         // IdP metadata XML
  attribute_mapping: AttributeMapping;
  idp_entity_id?: string;        // Extracted from metadata
  idp_sso_url?: string;          // Extracted from metadata
}
```

### Attribute Mapping Object

```typescript
interface AttributeMapping {
  keys: {
    email: string;               // Required - user email
    name?: string;               // Optional - full name
    first_name?: string;         // Optional - first name
    last_name?: string;          // Optional - last name
    [key: string]: string;       // Custom attributes
  };
}
```

**Standard SAML Attributes:**

| Supabase Field | ZITADEL Attribute | Description |
|----------------|-------------------|-------------|
| `email` | `Email` | User email address (required) |
| `name` | `FullName` | Full display name |
| `first_name` | `FirstName` | Given name |
| `last_name` | `SurName` | Family name |
| `phone` | `PhoneNumber` | Phone number |

**Custom Attributes:**

You can map any SAML assertion attribute to user metadata:

```json
{
  "attribute_mapping": {
    "keys": {
      "email": "Email",
      "name": "FullName",
      "department": "Department",
      "employee_id": "EmployeeID",
      "manager": "Manager"
    }
  }
}
```

Custom attributes are stored in `auth.users.raw_user_meta_data`.

---

## Error Handling

### Error Response Format

```json
{
  "error": "error_code",
  "error_description": "Human-readable error message",
  "status": 400
}
```

### Common Error Codes

| Status | Error Code | Description | Solution |
|--------|------------|-------------|----------|
| 400 | `bad_request` | Invalid request body | Check JSON syntax and required fields |
| 401 | `unauthorized` | Missing/invalid authentication | Verify Service Role key |
| 404 | `not_found` | Provider not found | Check provider ID |
| 409 | `conflict` | Duplicate domain | Domain already assigned to another provider |
| 422 | `unprocessable_entity` | Invalid metadata | Verify metadata URL/XML is valid SAML |
| 500 | `internal_server_error` | Server error | Check server logs |

### Example Error Responses

**Missing Email in Attribute Mapping:**

```json
{
  "error": "bad_request",
  "error_description": "attribute_mapping.keys.email is required",
  "status": 400
}
```

**Invalid Metadata URL:**

```json
{
  "error": "unprocessable_entity",
  "error_description": "Failed to fetch metadata from URL: connection timeout",
  "status": 422
}
```

**Unauthorized:**

```json
{
  "error": "unauthorized",
  "error_description": "Invalid authorization token",
  "status": 401
}
```

---

## Examples

### Complete Workflow Example

```bash
#!/bin/bash
# complete-saml-setup.sh

# Configuration
SERVICE_ROLE_KEY="your-service-role-key"
SUPABASE_URL="http://localhost:8000"
API_BASE="${SUPABASE_URL}/auth/v1/admin/sso/providers"

# Step 1: List existing providers
echo "=== Listing existing providers ==="
curl -s -X GET "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" | jq

# Step 2: Create new SAML provider
echo -e "\n=== Creating SAML provider ==="
PROVIDER_ID=$(curl -s -X POST "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "domains": ["example.com"],
    "metadata_url": "https://instance.zitadel.cloud/saml/v2/metadata",
    "attribute_mapping": {
      "keys": {
        "email": "Email",
        "name": "FullName",
        "first_name": "FirstName",
        "last_name": "SurName"
      }
    }
  }' | jq -r '.id')

echo "Created provider: $PROVIDER_ID"

# Step 3: Get provider details
echo -e "\n=== Getting provider details ==="
curl -s -X GET "${API_BASE}/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" | jq

# Step 4: Update provider (add domain)
echo -e "\n=== Updating provider ==="
curl -s -X PUT "${API_BASE}/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "domains": ["example.com", "subdomain.example.com"]
  }' | jq

# Step 5: Verify update
echo -e "\n=== Verifying update ==="
curl -s -X GET "${API_BASE}/${PROVIDER_ID}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" | jq '.domains'
```

### Python Example

```python
#!/usr/bin/env python3
"""SAML Admin API Example in Python"""

import requests
import json

# Configuration
SERVICE_ROLE_KEY = "your-service-role-key"
SUPABASE_URL = "http://localhost:8000"
API_BASE = f"{SUPABASE_URL}/auth/v1/admin/sso/providers"

# Headers
headers = {
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def list_providers():
    """List all SSO providers"""
    response = requests.get(API_BASE, headers=headers)
    response.raise_for_status()
    return response.json()

def create_provider(domains, metadata_url, attribute_mapping):
    """Create new SAML provider"""
    data = {
        "type": "saml",
        "domains": domains,
        "metadata_url": metadata_url,
        "attribute_mapping": attribute_mapping
    }
    response = requests.post(API_BASE, headers=headers, json=data)
    response.raise_for_status()
    return response.json()

def update_provider(provider_id, updates):
    """Update existing provider"""
    url = f"{API_BASE}/{provider_id}"
    response = requests.put(url, headers=headers, json=updates)
    response.raise_for_status()
    return response.json()

def delete_provider(provider_id):
    """Delete provider"""
    url = f"{API_BASE}/{provider_id}"
    response = requests.delete(url, headers=headers)
    response.raise_for_status()

# Example usage
if __name__ == "__main__":
    # Create provider
    provider = create_provider(
        domains=["example.com"],
        metadata_url="https://instance.zitadel.cloud/saml/v2/metadata",
        attribute_mapping={
            "keys": {
                "email": "Email",
                "name": "FullName"
            }
        }
    )
    print(f"Created provider: {provider['id']}")
    
    # List providers
    providers = list_providers()
    print(f"Total providers: {providers['total']}")
    
    # Update provider
    updated = update_provider(
        provider['id'],
        {"domains": ["example.com", "another.com"]}
    )
    print(f"Updated domains: {updated['domains']}")
```

### Node.js Example

```javascript
// saml-admin-api.js
const axios = require('axios');

const SERVICE_ROLE_KEY = 'your-service-role-key';
const SUPABASE_URL = 'http://localhost:8000';
const API_BASE = `${SUPABASE_URL}/auth/v1/admin/sso/providers`;

const headers = {
  'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
  'Content-Type': 'application/json'
};

// List providers
async function listProviders() {
  const response = await axios.get(API_BASE, { headers });
  return response.data;
}

// Create provider
async function createProvider(config) {
  const response = await axios.post(API_BASE, {
    type: 'saml',
    ...config
  }, { headers });
  return response.data;
}

// Update provider
async function updateProvider(providerId, updates) {
  const url = `${API_BASE}/${providerId}`;
  const response = await axios.put(url, updates, { headers });
  return response.data;
}

// Delete provider
async function deleteProvider(providerId) {
  const url = `${API_BASE}/${providerId}`;
  await axios.delete(url, { headers });
}

// Example usage
(async () => {
  try {
    // Create
    const provider = await createProvider({
      domains: ['example.com'],
      metadata_url: 'https://instance.zitadel.cloud/saml/v2/metadata',
      attribute_mapping: {
        keys: {
          email: 'Email',
          name: 'FullName'
        }
      }
    });
    console.log('Created:', provider.id);
    
    // List
    const providers = await listProviders();
    console.log('Total:', providers.total);
    
    // Update
    await updateProvider(provider.id, {
      domains: ['example.com', 'another.com']
    });
    console.log('Updated');
    
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
})();
```

---

## Rate Limiting

### Limits

| Operation | Rate Limit | Window |
|-----------|------------|--------|
| List providers | 100 requests | per minute |
| Get provider | 200 requests | per minute |
| Create provider | 10 requests | per minute |
| Update provider | 50 requests | per minute |
| Delete provider | 20 requests | per minute |

### Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

### Handling Rate Limits

```python
import time

def api_call_with_retry(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                retry_after = int(e.response.headers.get('Retry-After', 60))
                print(f"Rate limited. Retrying after {retry_after}s...")
                time.sleep(retry_after)
            else:
                raise
    raise Exception("Max retries exceeded")
```

---

## Best Practices

### 1. Secure Storage

```bash
# Never hardcode service role key
# Use environment variables
export SERVICE_ROLE_KEY="your-key"

# Or secret management
aws secretsmanager get-secret-value \
  --secret-id supabase-service-role-key \
  --query SecretString --output text
```

### 2. Error Handling

```bash
# Always check response status
response=$(curl -s -w "\n%{http_code}" -X GET "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")

body=$(echo "$response" | head -n -1)
status=$(echo "$response" | tail -n 1)

if [ "$status" -ne 200 ]; then
  echo "Error: $body"
  exit 1
fi
```

### 3. Idempotent Operations

```bash
# Check if provider exists before creating
existing=$(curl -s -X GET "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" | \
  jq -r ".items[] | select(.domains[] == \"example.com\") | .id")

if [ -z "$existing" ]; then
  # Create new provider
  curl -X POST "$API_BASE" ...
else
  # Update existing
  curl -X PUT "${API_BASE}/${existing}" ...
fi
```

### 4. Logging

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_provider(config):
    logger.info(f"Creating provider for domains: {config['domains']}")
    try:
        response = requests.post(API_BASE, headers=headers, json=config)
        response.raise_for_status()
        logger.info(f"Provider created: {response.json()['id']}")
        return response.json()
    except Exception as e:
        logger.error(f"Failed to create provider: {e}")
        raise
```

---

## Troubleshooting

### Debug Mode

```bash
# Enable verbose curl output
curl -v -X GET "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# View full request/response
curl -v --trace-ascii /dev/stdout \
  -X POST "$API_BASE" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -d '...'
```

### Common Issues

**401 Unauthorized:**
```bash
# Verify service role key
echo $SERVICE_ROLE_KEY

# Test with known-good key
SERVICE_ROLE_KEY=$(cat .env | grep SERVICE_ROLE_KEY | cut -d= -f2)
```

**422 Unprocessable Entity:**
```bash
# Validate metadata URL
curl -s "https://instance.zitadel.cloud/saml/v2/metadata" | \
  xmllint --format -

# Check metadata_xml syntax
echo "$METADATA_XML" | xmllint --format -
```

**500 Internal Server Error:**
```bash
# Check auth service logs
docker-compose logs auth | tail -100

# Check for SAML configuration errors
docker-compose exec auth env | grep SAML
```

---

## References

- **Main Integration Guide**: [AUTH_ZITADEL_SAML_SELF_HOSTED.md](AUTH_ZITADEL_SAML_SELF_HOSTED.md)
- **GoTrue Documentation**: https://github.com/supabase/gotrue
- **SAML 2.0 Specification**: https://docs.oasis-open.org/security/saml/v2.0/

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-01  
**Status**: Production Ready
