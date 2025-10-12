---
title: SAML Admin API Reference
type: note
permalink: guides/saml/saml-admin-api-reference
tags:
- saml
- admin-api
- management
- api
---

# SAML Admin API Reference

## Purpose

Complete API reference for managing SAML SSO providers programmatically via the GoTrue Admin API.

## Authentication

- [auth] Requires service role key for all operations
- [auth] Header: `Authorization: Bearer {SERVICE_ROLE_KEY}`
- [auth] Never expose service role key to clients
- [security] Use environment variables for keys
- [security] Rotate keys regularly

## Base Endpoint

- [endpoint] `/auth/v1/admin/sso/providers`
- [method] Supports GET, POST, PUT, DELETE
- [format] JSON request and response bodies
- [port] Default: 8000 (local), 443 (production with SSL)

## List Providers (GET)

- [operation] **GET** `/auth/v1/admin/sso/providers`
- [returns] Array of all configured SAML providers
- [fields] id, type, domains, created_at, updated_at
- [use-case] Audit existing providers
- [use-case] Verify provider configuration

## Create Provider (POST)

- [operation] **POST** `/auth/v1/admin/sso/providers`
- [body] type, domains, metadata_url OR metadata_xml
- [body] attribute_mapping (optional)
- [returns] Created provider object with generated ID
- [validates] Metadata format and signature
- [creates] Entry in auth.saml_providers table

## Update Provider (PUT)

- [operation] **PUT** `/auth/v1/admin/sso/providers/{id}`
- [body] domains, metadata_url, metadata_xml, attribute_mapping
- [returns] Updated provider object
- [use-case] Update metadata after certificate rotation
- [use-case] Modify attribute mapping

## Delete Provider (DELETE)

- [operation] **DELETE** `/auth/v1/admin/sso/providers/{id}`
- [returns] 204 No Content on success
- [warning] Existing user sessions remain valid
- [cleanup] Users retain access until re-authentication

## Get Provider (GET by ID)

- [operation] **GET** `/auth/v1/admin/sso/providers/{id}`
- [returns] Single provider object with full details
- [use-case] Retrieve specific provider configuration
- [use-case] Verify metadata synchronization

## Attribute Mapping Configuration

- [mapping] keys object maps SAML attributes to user fields
- [example] `{"email": "Email", "name": "FullName"}`
- [required] Email mapping is mandatory
- [optional] name, first_name, last_name, custom attributes
- [case-sensitive] Attribute names must match exactly

## Request Examples

- [example] Create provider with metadata URL
- [example] Create provider with inline metadata XML
- [example] Update attribute mapping
- [example] List all providers with curl
- [example] Delete provider by ID

## Response Codes

- [code] 200 OK - Successful GET/PUT
- [code] 201 Created - Successful POST
- [code] 204 No Content - Successful DELETE
- [code] 400 Bad Request - Invalid input
- [code] 401 Unauthorized - Missing/invalid service role key
- [code] 404 Not Found - Provider ID doesn't exist
- [code] 500 Internal Server Error - Server error

## Error Handling

- [error] Invalid metadata: Check XML format
- [error] Missing required fields: Verify request body
- [error] Duplicate domain: Check existing providers
- [error] Malformed attribute mapping: Verify JSON structure
- [debug] Check GoTrue logs for detailed errors

## Security Considerations

- [security] Service role key provides full database access
- [security] Implement IP allowlisting for admin API
- [security] Log all admin API operations
- [security] Rate limit admin endpoints
- [security] Validate metadata signatures
- [security] Sanitize user inputs

## Database Tables

- [table] **auth.saml_providers** - Provider configuration
- [table] **auth.saml_relay_states** - OAuth state tracking
- [table] **auth.users** - User accounts linked to SAML
- [query] Direct database queries as fallback

## Automation Use Cases

- [automation] Programmatic provider registration
- [automation] Bulk updates across environments
- [automation] Automated metadata synchronization
- [automation] CI/CD integration for deployments
- [automation] Multi-tenant provider management

## Best Practices

- [best-practice] Use metadata_url for automatic updates
- [best-practice] Version control provider configurations
- [best-practice] Test in staging before production
- [best-practice] Implement retry logic with exponential backoff
- [best-practice] Validate responses before processing
- [best-practice] Monitor API errors and rate limits

## Troubleshooting

- [issue] 401 Unauthorized: Verify service role key
- [issue] Invalid metadata: Validate XML structure
- [issue] Provider not appearing: Check database directly
- [issue] Attribute mapping not working: Verify case-sensitivity
- [diagnostic] Use curl -v for verbose output
- [diagnostic] Check GoTrue logs for API errors

## Relations

- part_of [[ZITADEL SAML Integration Guide]]
- manages [[SAML Providers]]
- documented_in [[SAML_ADMIN_API.md]]
- uses [[Service Role Authentication]]
- interacts_with [[PostgreSQL Database]]
- relates_to [[GoTrue Auth Server]]
