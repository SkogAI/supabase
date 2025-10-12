# ZITADEL SAML Production Deployment Guide

Complete guide for deploying ZITADEL SAML SSO to production with self-hosted Supabase.

> **Important**: This is Phase 4 of the SAML integration. Complete Phases 1-3 (ZITADEL setup, Supabase configuration, and testing) before proceeding.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Production Environment Setup](#production-environment-setup)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Production ZITADEL Configuration](#production-zitadel-configuration)
- [Production Supabase Configuration](#production-supabase-configuration)
- [Security Hardening](#security-hardening)
- [Monitoring & Alerting](#monitoring--alerting)
- [Deployment Procedure](#deployment-procedure)
- [Post-Deployment Validation](#post-deployment-validation)
- [Rollback Plan](#rollback-plan)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Overview

This guide covers deploying a production-ready ZITADEL SAML SSO integration with self-hosted Supabase, including:

- Infrastructure provisioning
- SSL/TLS certificate configuration
- Production environment variables
- Security hardening
- Monitoring and logging
- Deployment procedures
- Rollback procedures

### Architecture

```
Internet
    ↓
[Reverse Proxy (nginx/Traefik)]
    ↓ HTTPS (443)
[Docker Network]
    ├── Kong Gateway
    ├── GoTrue (Auth Service)
    ├── PostgreSQL
    └── Other Supabase Services
    
SAML Flow:
    ↓
Production ZITADEL Instance (IdP)
```

---

## Prerequisites

### Completed Phases

- ✅ **Phase 1**: ZITADEL IdP setup completed ([docs/ZITADEL_SAML_IDP_SETUP.md](ZITADEL_SAML_IDP_SETUP.md))
- ✅ **Phase 2**: Supabase SAML configuration completed (Issue #70)
- ✅ **Phase 3**: Testing & validation completed (Issue #71)

### Infrastructure Requirements

- **Server**: Production server with Docker support
  - Minimum: 4 CPU cores, 8GB RAM, 50GB disk
  - Recommended: 8 CPU cores, 16GB RAM, 100GB SSD
- **Docker**: Docker Engine 20.10+ and Docker Compose 2.x+
- **Network**: Static IP or domain name with DNS access
- **Certificates**: SSL/TLS certificates (Let's Encrypt or commercial)
- **Backups**: Automated backup solution for PostgreSQL

### Access Requirements

- Root/sudo access to production server
- DNS management access for domain configuration
- Production ZITADEL instance admin access
- Certificate authority access (if using commercial certs)

### Security Review Completed

- [ ] Security review of SAML configuration
- [ ] Penetration testing completed (if required)
- [ ] Compliance requirements verified
- [ ] Data protection policies reviewed
- [ ] Incident response plan documented

---

## Production Environment Setup

### 1. Server Provisioning

#### Install Docker and Docker Compose

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose (if not included)
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### Configure System Limits

```bash
# Edit /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Edit /etc/sysctl.conf
sudo tee -a /etc/sysctl.conf <<EOF
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
vm.max_map_count = 262144
EOF

# Apply sysctl changes
sudo sysctl -p
```

### 2. Firewall Configuration

```bash
# Install UFW (if not installed)
sudo apt install ufw -y

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp   # HTTP (for Let's Encrypt)
sudo ufw allow 443/tcp  # HTTPS

# Optional: Allow direct access to Supabase Studio
# sudo ufw allow 8000/tcp

# Enable firewall
sudo ufw enable
sudo ufw status
```

### 3. Directory Structure

```bash
# Create production directory structure
sudo mkdir -p /opt/supabase/production
sudo mkdir -p /opt/supabase/config
sudo mkdir -p /opt/supabase/volumes/{db,storage,logs}
sudo mkdir -p /opt/supabase/backups
sudo mkdir -p /opt/supabase/certs

# Set ownership
sudo chown -R $USER:$USER /opt/supabase

# Set secure permissions
chmod 750 /opt/supabase/config
chmod 750 /opt/supabase/certs
```

---

## SSL/TLS Configuration

### Option 1: Let's Encrypt (Recommended)

#### Using Certbot

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificates (DNS challenge)
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email admin@your-domain.com \
  --agree-tos \
  --non-interactive

# Certificates will be saved to:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

#### Copy Certificates

```bash
# Copy to Supabase directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem \
  /opt/supabase/certs/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem \
  /opt/supabase/certs/key.pem

# Set permissions
sudo chmod 644 /opt/supabase/certs/cert.pem
sudo chmod 600 /opt/supabase/certs/key.pem
```

### Option 2: Commercial SSL Certificate

```bash
# Place your certificate files
sudo cp your-cert.crt /opt/supabase/certs/cert.pem
sudo cp your-key.key /opt/supabase/certs/key.pem
sudo cp your-ca-bundle.crt /opt/supabase/certs/ca-bundle.pem

# Set permissions
sudo chmod 644 /opt/supabase/certs/cert.pem
sudo chmod 600 /opt/supabase/certs/key.pem
sudo chmod 644 /opt/supabase/certs/ca-bundle.pem
```

### Nginx Reverse Proxy Configuration

Create `/opt/supabase/config/nginx.conf`:

```nginx
upstream supabase_api {
    server localhost:54321;
}

upstream supabase_studio {
    server localhost:8000;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Configuration
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL Configuration
    ssl_certificate /opt/supabase/certs/cert.pem;
    ssl_certificate_key /opt/supabase/certs/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy to Supabase API
    location /auth/ {
        proxy_pass http://supabase_api/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }
    
    location /rest/ {
        proxy_pass http://supabase_api/rest/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /realtime/ {
        proxy_pass http://supabase_api/realtime/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /storage/ {
        proxy_pass http://supabase_api/storage/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 50M;
    }
    
    # Supabase Studio (Optional - restrict to admin IPs)
    location / {
        # Allow only from specific IPs (optional)
        # allow 1.2.3.4;
        # deny all;
        
        proxy_pass http://supabase_studio/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Start Nginx

```bash
# Install nginx
sudo apt install nginx -y

# Copy configuration
sudo cp /opt/supabase/config/nginx.conf /etc/nginx/sites-available/supabase
sudo ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/

# Remove default configuration
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
```

---

## Production ZITADEL Configuration

### 1. Create Production SAML Application

1. Log in to **production** ZITADEL instance
2. Navigate to your Organization → Projects → Select Project
3. Create new SAML application:
   - **Name**: `Supabase Production SSO`
   - **Entity ID**: `https://your-domain.com/auth/v1/sso/saml/metadata`
   - **ACS URL**: `https://your-domain.com/auth/v1/sso/saml/acs`

### 2. Configure Attribute Mapping

Configure the same attribute mapping as development:

| ZITADEL Attribute | SAML Attribute | Required |
|------------------|----------------|----------|
| `user.email` | `Email` | Yes |
| `user.firstName` | `FirstName` | No |
| `user.lastName` | `SurName` | No |
| `user.displayName` | `FullName` | No |
| `user.username` | `UserName` | No |
| `user.id` | `UserID` | No |

### 3. Export Production Metadata

```bash
# Download production metadata
curl -o /opt/supabase/config/zitadel-prod-metadata.xml \
  https://your-zitadel-instance.com/saml/v2/metadata

# Set secure permissions
chmod 600 /opt/supabase/config/zitadel-prod-metadata.xml
```

### 4. Configure Production Users

- Assign real users to the production SAML application
- Remove or disable test users
- Set up user groups/roles if needed
- Configure MFA policies (recommended)

---

## Production Supabase Configuration

### 1. Generate Production SAML Keys

```bash
# Generate RSA private key for SAML
openssl genpkey -algorithm rsa -outform DER -out /opt/supabase/config/prod_saml_key.der

# Convert to base64 for environment variable
base64 -w 0 /opt/supabase/config/prod_saml_key.der > /opt/supabase/config/prod_saml_key.base64

# Store the base64 key securely
PROD_SAML_KEY=$(cat /opt/supabase/config/prod_saml_key.base64)

# Secure the files
chmod 600 /opt/supabase/config/prod_saml_key.*
```

### 2. Generate Production Service Keys

```bash
# Generate JWT secret (at least 32 characters)
PROD_JWT_SECRET=$(openssl rand -base64 32)

# Generate Anon key (use Supabase JWT generator or online tool)
# Visit: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

# Generate Service Role key
# Visit: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

# Store in secure location
echo "JWT_SECRET=$PROD_JWT_SECRET" > /opt/supabase/config/prod_secrets.txt
echo "ANON_KEY=$PROD_ANON_KEY" >> /opt/supabase/config/prod_secrets.txt
echo "SERVICE_ROLE_KEY=$PROD_SERVICE_ROLE_KEY" >> /opt/supabase/config/prod_secrets.txt

# Secure the file
chmod 600 /opt/supabase/config/prod_secrets.txt
```

### 3. Production Environment Variables

Create `/opt/supabase/.env.production`:

```bash
# Supabase Configuration
SUPABASE_URL=https://your-domain.com
SUPABASE_PUBLIC_URL=https://your-domain.com

# API Keys (GENERATE NEW KEYS - DO NOT USE DEFAULTS!)
ANON_KEY=<your-production-anon-key>
SERVICE_ROLE_KEY=<your-production-service-role-key>

# Database
POSTGRES_PASSWORD=<strong-random-password>
POSTGRES_HOST=db
POSTGRES_DB=postgres
POSTGRES_PORT=5432

# JWT Configuration
JWT_SECRET=<your-production-jwt-secret>
JWT_EXPIRY=3600

# SAML Configuration
GOTRUE_SAML_ENABLED=true
GOTRUE_SAML_PRIVATE_KEY=<base64-encoded-saml-private-key>

# Site URLs (HTTPS only)
GOTRUE_SITE_URL=https://your-domain.com
GOTRUE_URI_ALLOW_LIST=https://your-domain.com,https://www.your-domain.com

# Additional Auth Settings
GOTRUE_JWT_EXP=3600
GOTRUE_REFRESH_TOKEN_ROTATION_ENABLED=true
GOTRUE_SECURITY_REFRESH_TOKEN_REUSE_INTERVAL=10

# Session Configuration
GOTRUE_COOKIE_KEY=<random-32-char-string>
GOTRUE_COOKIE_DOMAIN=your-domain.com

# Email Configuration (optional)
SMTP_ADMIN_EMAIL=admin@your-domain.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=<your-smtp-password>
SMTP_SENDER_NAME=Your Company

# Storage Configuration
STORAGE_BACKEND=file
FILE_SIZE_LIMIT=52428800
FILE_STORAGE_BACKEND_PATH=/var/lib/storage

# Studio (disable in production or restrict access)
STUDIO_PORT=8000
STUDIO_PG_META_PORT=54321

# Kong Configuration
KONG_HTTP_PORT=80
KONG_HTTPS_PORT=443

# Logging
LOG_LEVEL=info
GOTRUE_LOG_LEVEL=info
```

**Secure the environment file:**

```bash
chmod 600 /opt/supabase/.env.production
```

### 4. Production Docker Compose

Create `/opt/supabase/docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  studio:
    image: supabase/studio:20231123-64a766a
    restart: unless-stopped
    ports:
      - "8000:3000"
    environment:
      SUPABASE_URL: ${SUPABASE_PUBLIC_URL}
      SUPABASE_ANON_KEY: ${ANON_KEY}
      SUPABASE_SERVICE_KEY: ${SERVICE_ROLE_KEY}
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  kong:
    image: kong:2.8.1
    restart: unless-stopped
    ports:
      - "54321:8000"
      - "54323:8443"
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /var/lib/kong/kong.yml
      KONG_DNS_ORDER: LAST,A,CNAME
      KONG_PLUGINS: request-transformer,cors,key-auth,acl,basic-auth
    volumes:
      - ./volumes/api:/var/lib/kong
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "kong", "health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G

  auth:
    image: supabase/gotrue:v2.132.3
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://supabase_auth_admin:${POSTGRES_PASSWORD}@db:5432/postgres
      
      GOTRUE_SITE_URL: ${GOTRUE_SITE_URL}
      GOTRUE_URI_ALLOW_LIST: ${GOTRUE_URI_ALLOW_LIST}
      GOTRUE_DISABLE_SIGNUP: false
      
      GOTRUE_JWT_ADMIN_ROLES: service_role
      GOTRUE_JWT_AUD: authenticated
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_JWT_EXP: ${GOTRUE_JWT_EXP}
      GOTRUE_JWT_SECRET: ${JWT_SECRET}
      
      # SAML Configuration
      GOTRUE_SAML_ENABLED: ${GOTRUE_SAML_ENABLED}
      GOTRUE_SAML_PRIVATE_KEY: ${GOTRUE_SAML_PRIVATE_KEY}
      
      # Security
      GOTRUE_SECURITY_REFRESH_TOKEN_ROTATION_ENABLED: ${GOTRUE_REFRESH_TOKEN_ROTATION_ENABLED}
      GOTRUE_SECURITY_REFRESH_TOKEN_REUSE_INTERVAL: ${GOTRUE_SECURITY_REFRESH_TOKEN_REUSE_INTERVAL}
      
      # Logging
      GOTRUE_LOG_LEVEL: ${GOTRUE_LOG_LEVEL}
      
      # External Email
      GOTRUE_EXTERNAL_EMAIL_ENABLED: true
      GOTRUE_MAILER_AUTOCONFIRM: false
      GOTRUE_SMTP_HOST: ${SMTP_HOST}
      GOTRUE_SMTP_PORT: ${SMTP_PORT}
      GOTRUE_SMTP_USER: ${SMTP_USER}
      GOTRUE_SMTP_PASS: ${SMTP_PASS}
      GOTRUE_SMTP_ADMIN_EMAIL: ${SMTP_ADMIN_EMAIL}
      GOTRUE_MAILER_URLPATHS_CONFIRMATION: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_INVITE: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_RECOVERY: /auth/v1/verify
      GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE: /auth/v1/verify
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:9999/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  rest:
    image: postgrest/postgrest:v12.0.2
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PGRST_DB_URI: postgres://authenticator:${POSTGRES_PASSWORD}@db:5432/postgres
      PGRST_DB_SCHEMAS: public,storage,graphql_public
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: ${JWT_SECRET}
      PGRST_DB_USE_LEGACY_GUCS: "false"
      PGRST_APP_SETTINGS_JWT_SECRET: ${JWT_SECRET}
      PGRST_APP_SETTINGS_JWT_EXP: ${JWT_EXPIRY}
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G

  realtime:
    image: supabase/realtime:v2.25.35
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PORT: 4000
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: supabase_admin
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      DB_NAME: postgres
      DB_AFTER_CONNECT_QUERY: 'SET search_path TO _realtime'
      DB_ENC_KEY: supabaserealtime
      API_JWT_SECRET: ${JWT_SECRET}
      FLY_ALLOC_ID: fly123
      FLY_APP_NAME: realtime
      SECRET_KEY_BASE: ${JWT_SECRET}
      ERL_AFLAGS: -proto_dist inet_tcp
      ENABLE_TAILSCALE: "false"
      DNS_NODES: "''"
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:4000/"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M

  storage:
    image: supabase/storage-api:v0.43.11
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      rest:
        condition: service_started
    environment:
      ANON_KEY: ${ANON_KEY}
      SERVICE_KEY: ${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://rest:3000
      PGRST_JWT_SECRET: ${JWT_SECRET}
      DATABASE_URL: postgres://supabase_storage_admin:${POSTGRES_PASSWORD}@db:5432/postgres
      FILE_SIZE_LIMIT: ${FILE_SIZE_LIMIT}
      STORAGE_BACKEND: ${STORAGE_BACKEND}
      FILE_STORAGE_BACKEND_PATH: ${FILE_STORAGE_BACKEND_PATH}
      TENANT_ID: stub
      REGION: stub
      GLOBAL_S3_BUCKET: stub
    volumes:
      - /opt/supabase/volumes/storage:/var/lib/storage
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5000/status"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  db:
    image: supabase/postgres:17.0.0.64
    restart: unless-stopped
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: postgres
    volumes:
      - /opt/supabase/volumes/db:/var/lib/postgresql/data
      - ./supabase/migrations:/docker-entrypoint-initdb.d
    networks:
      - supabase_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 4G
    ports:
      - "54322:5432"

networks:
  supabase_network:
    driver: bridge

volumes:
  db-data:
  storage-data:
```

### 5. Add SAML SSO Provider via API

After deploying, add the SAML provider:

```bash
# Read the metadata file
METADATA_XML=$(cat /opt/supabase/config/zitadel-prod-metadata.xml)

# Or use metadata URL
METADATA_URL="https://your-zitadel-instance.com/saml/v2/metadata"

# Add SSO provider using Service Role Key
curl -X POST https://your-domain.com/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"saml\",
    \"metadata_url\": \"${METADATA_URL}\",
    \"domains\": [\"yourcompany.com\"],
    \"attribute_mapping\": {
      \"keys\": {
        \"email\": \"Email\",
        \"name\": \"FullName\",
        \"first_name\": \"FirstName\",
        \"last_name\": \"SurName\"
      }
    }
  }"
```

---

## Security Hardening

### 1. Change Default Passwords

```bash
# Generate strong passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

# Update .env.production with new passwords
```

### 2. Configure Rate Limiting

Update Kong configuration to add rate limiting:

```yaml
# In volumes/api/kong.yml
plugins:
  - name: rate-limiting
    config:
      minute: 100
      hour: 5000
      policy: local
```

### 3. Session Timeouts

Already configured in `.env.production`:

```bash
GOTRUE_JWT_EXP=3600                                    # 1 hour
GOTRUE_REFRESH_TOKEN_ROTATION_ENABLED=true
GOTRUE_SECURITY_REFRESH_TOKEN_REUSE_INTERVAL=10       # 10 seconds
```

### 4. Enable Audit Logging

#### ZITADEL Audit Logging

1. In ZITADEL Console → Settings → Audit Trail
2. Enable audit logging
3. Configure log retention (90 days minimum)
4. Set up log export to SIEM if required

#### Supabase Logging

```bash
# Create logging directory
mkdir -p /opt/supabase/logs

# Update docker-compose to add logging
# Add to each service:
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "10"
```

### 5. Database Security

```sql
-- Connect to production database
psql postgres://postgres:${POSTGRES_PASSWORD}@localhost:54322/postgres

-- Enable SSL for database connections (if using external connections)
ALTER SYSTEM SET ssl = on;

-- Restrict database user permissions
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Enable row level security on all tables
-- (Should already be enabled from previous phases)

-- Set password policies
ALTER ROLE postgres WITH PASSWORD '${POSTGRES_PASSWORD}' VALID UNTIL 'infinity';
```

### 6. Firewall Rules

```bash
# Additional security: restrict database access
sudo ufw deny 54322/tcp  # Block external PostgreSQL access
sudo ufw status

# Only allow from specific IPs if needed
# sudo ufw allow from 1.2.3.4 to any port 54322
```

### 7. Secrets Management

```bash
# Use environment-specific .env files
# Never commit .env files to git
# Consider using HashiCorp Vault or AWS Secrets Manager

# Rotate secrets regularly (every 90 days)
# Document secret rotation procedures
```

---

## Monitoring & Alerting

### 1. Infrastructure Monitoring

```bash
# Install monitoring tools
sudo apt install prometheus node-exporter -y

# Install Docker monitoring
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  gcr.io/cadvisor/cadvisor:latest
```

### 2. Application Monitoring

#### Monitor SAML Authentication

```bash
# View GoTrue logs for SAML activity
docker compose -f docker-compose.production.yml logs -f auth | grep -i saml

# Monitor authentication success/failure
docker compose -f docker-compose.production.yml logs auth | \
  grep -E "(success|error|fail)" | tail -100
```

### 3. Health Check Script

Create `/opt/supabase/scripts/health-check.sh`:

```bash
#!/bin/bash

# Health check script for Supabase services
DOMAIN="https://your-domain.com"

echo "=== Supabase Health Check ==="
echo "Date: $(date)"

# Check API
if curl -sf "${DOMAIN}/rest/v1/" > /dev/null; then
    echo "✅ API: OK"
else
    echo "❌ API: FAILED"
fi

# Check Auth
if curl -sf "${DOMAIN}/auth/v1/health" > /dev/null; then
    echo "✅ Auth: OK"
else
    echo "❌ Auth: FAILED"
fi

# Check SAML Metadata
if curl -sf "${DOMAIN}/auth/v1/sso/saml/metadata" > /dev/null; then
    echo "✅ SAML Metadata: OK"
else
    echo "❌ SAML Metadata: FAILED"
fi

# Check Database
if docker exec supabase-db pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ Database: OK"
else
    echo "❌ Database: FAILED"
fi

# Check Docker containers
echo ""
echo "=== Container Status ==="
docker compose -f /opt/supabase/docker-compose.production.yml ps
```

Make executable and add to cron:

```bash
chmod +x /opt/supabase/scripts/health-check.sh

# Add to crontab (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/supabase/scripts/health-check.sh >> /opt/supabase/logs/health-check.log 2>&1") | crontab -
```

### 4. Log Aggregation

```bash
# Install Promtail and Loki for log aggregation (optional)
# Or configure rsyslog to forward to centralized logging

# Configure log rotation
cat > /etc/logrotate.d/supabase <<EOF
/opt/supabase/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 $USER $USER
    sharedscripts
}
EOF
```

### 5. Alerting Configuration

Create `/opt/supabase/scripts/alert.sh`:

```bash
#!/bin/bash

# Simple alert script (customize for your notification service)
SERVICE=$1
STATUS=$2
MESSAGE=$3

if [ "$STATUS" == "FAILED" ]; then
    # Send email alert
    echo "$MESSAGE" | mail -s "ALERT: Supabase $SERVICE Failed" admin@your-domain.com
    
    # Or send to Slack/Discord webhook
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"ALERT: Supabase $SERVICE Failed - $MESSAGE\"}" \
    #   YOUR_WEBHOOK_URL
fi
```

---

## Deployment Procedure

### Pre-Deployment Checklist

- [ ] Backup current production data (if applicable)
- [ ] Maintenance window scheduled and communicated
- [ ] All SSL certificates obtained and configured
- [ ] DNS records configured and propagated
- [ ] Environment variables configured and verified
- [ ] SAML keys generated and secured
- [ ] Production ZITADEL configuration complete
- [ ] Rollback plan documented and understood
- [ ] Team members notified and available

### Deployment Steps

#### 1. Prepare Deployment

```bash
# Clone repository to production server
cd /opt/supabase
git clone https://github.com/yourorg/supabase.git production
cd production

# Copy environment file
cp /opt/supabase/.env.production .env

# Verify configuration
cat .env | grep -v "PASSWORD\|KEY\|SECRET"
```

#### 2. Initialize Database

```bash
# Start database only first
docker compose -f docker-compose.production.yml up -d db

# Wait for database to be ready
docker compose -f docker-compose.production.yml logs db

# Run migrations
docker compose -f docker-compose.production.yml run --rm \
  -v $(pwd)/supabase/migrations:/migrations \
  db psql -U postgres -d postgres -f /migrations/*.sql
```

#### 3. Deploy Services

```bash
# Start all services
docker compose -f docker-compose.production.yml up -d

# Verify all containers are running
docker compose -f docker-compose.production.yml ps

# Check logs for errors
docker compose -f docker-compose.production.yml logs --tail=100
```

#### 4. Configure SAML Provider

```bash
# Add SAML provider via API
curl -X POST https://your-domain.com/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"saml\",
    \"metadata_url\": \"https://your-zitadel-instance.com/saml/v2/metadata\",
    \"domains\": [\"yourcompany.com\"],
    \"attribute_mapping\": {
      \"keys\": {
        \"email\": \"Email\",
        \"name\": \"FullName\",
        \"first_name\": \"FirstName\",
        \"last_name\": \"SurName\"
      }
    }
  }"

# Verify provider was added
curl https://your-domain.com/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
```

#### 5. Verify Deployment

```bash
# Run health check
/opt/supabase/scripts/health-check.sh

# Test SAML metadata endpoint
curl https://your-domain.com/auth/v1/sso/saml/metadata

# Test from browser
# Navigate to: https://your-domain.com
```

---

## Post-Deployment Validation

### 1. Smoke Tests

#### Test SAML Metadata

```bash
# Verify metadata is accessible
curl -v https://your-domain.com/auth/v1/sso/saml/metadata

# Verify metadata structure
curl -s https://your-domain.com/auth/v1/sso/saml/metadata | \
  xmllint --format -
```

#### Test Authentication Flow

1. Navigate to your application login page
2. Click "Sign in with SSO" or enter company email
3. Verify redirect to ZITADEL
4. Log in with production user credentials
5. Verify redirect back to application
6. Check user profile is correctly populated

### 2. Verify User Provisioning

```sql
-- Connect to database
psql postgres://postgres:${POSTGRES_PASSWORD}@localhost:54322/postgres

-- Check auth users table
SELECT id, email, created_at, last_sign_in_at 
FROM auth.users 
WHERE email = 'test.user@yourcompany.com';

-- Verify user metadata
SELECT raw_user_meta_data 
FROM auth.users 
WHERE email = 'test.user@yourcompany.com';
```

### 3. Check Logs

```bash
# Check for any errors
docker compose -f docker-compose.production.yml logs --tail=200 | grep -i error

# Monitor SAML authentication
docker compose -f docker-compose.production.yml logs -f auth | grep -i saml
```

### 4. Verify Existing Authentication

Test that non-SSO authentication methods still work:

- Email/password login
- Magic link login
- OAuth providers (if configured)

### 5. Monitor for 24-48 Hours

```bash
# Set up continuous monitoring
watch -n 60 '/opt/supabase/scripts/health-check.sh'

# Check error rates
docker compose -f docker-compose.production.yml logs auth | \
  grep -c error

# Check successful authentications
docker compose -f docker-compose.production.yml logs auth | \
  grep -i "authentication successful" | wc -l
```

---

## Rollback Plan

### When to Rollback

Rollback if you encounter:

- Critical authentication failures (>5% error rate)
- Database corruption or data loss
- Service unavailability (>10 minutes)
- Security vulnerabilities discovered
- Inability to authenticate any users

### Rollback Procedure

#### 1. Immediate Rollback (Service Issues)

```bash
# Stop current deployment
cd /opt/supabase/production
docker compose -f docker-compose.production.yml down

# Restore previous version
cd /opt/supabase/previous-version
docker compose up -d

# Verify services are running
docker compose ps
```

#### 2. Database Rollback

```bash
# Stop all services
docker compose down

# Restore database from backup
docker run --rm \
  -v /opt/supabase/backups:/backups \
  -v /opt/supabase/volumes/db:/var/lib/postgresql/data \
  postgres:17 \
  pg_restore -U postgres -d postgres /backups/pre-deployment-backup.sql

# Restart services
docker compose up -d
```

#### 3. SAML Rollback

```bash
# Remove SAML provider via API
curl -X DELETE https://your-domain.com/auth/v1/admin/sso/providers/{provider-id} \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Remove SAML environment variables
# Edit .env and remove GOTRUE_SAML_* variables

# Restart auth service
docker compose restart auth
```

#### 4. DNS Rollback

```bash
# If needed, revert DNS to previous infrastructure
# Update A/CNAME records to point to previous server
# Wait for DNS propagation (up to 24 hours)
```

### Post-Rollback Actions

1. Document what went wrong
2. Notify users of the rollback
3. Conduct post-mortem meeting
4. Plan remediation for issues
5. Schedule new deployment attempt

---

## Troubleshooting

### Common Issues

#### 1. SAML Metadata Not Accessible

**Symptom**: 404 error when accessing `/auth/v1/sso/saml/metadata`

**Solutions**:

```bash
# Check GoTrue container is running
docker compose ps auth

# Check GoTrue logs
docker compose logs auth | tail -50

# Verify SAML is enabled
docker compose exec auth env | grep SAML

# Restart auth service
docker compose restart auth
```

#### 2. SSL Certificate Errors

**Symptom**: Browser shows SSL certificate error

**Solutions**:

```bash
# Verify certificate files exist
ls -la /opt/supabase/certs/

# Check certificate expiration
openssl x509 -in /opt/supabase/certs/cert.pem -noout -dates

# Verify certificate matches domain
openssl x509 -in /opt/supabase/certs/cert.pem -noout -text | grep DNS

# Restart nginx
sudo systemctl restart nginx
```

#### 3. Authentication Fails After SAML Login

**Symptom**: User redirected to ZITADEL, logs in, but gets error on redirect back

**Solutions**:

```bash
# Check GoTrue logs for SAML errors
docker compose logs auth | grep -i "saml\|error"

# Verify ACS URL in ZITADEL matches
# https://your-domain.com/auth/v1/sso/saml/acs

# Verify metadata_url in SSO provider configuration
curl https://your-domain.com/auth/v1/admin/sso/providers \
  -H "APIKey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

# Check JWT secret matches
docker compose exec auth env | grep JWT_SECRET
```

#### 4. Database Connection Issues

**Symptom**: Services can't connect to database

**Solutions**:

```bash
# Check database is running
docker compose ps db

# Check database logs
docker compose logs db | tail -50

# Test database connection
docker compose exec db pg_isready -U postgres

# Verify connection string
docker compose exec auth env | grep DATABASE_URL

# Restart database
docker compose restart db
```

#### 5. High Memory Usage

**Symptom**: Server running out of memory

**Solutions**:

```bash
# Check container memory usage
docker stats

# Adjust resource limits in docker-compose.production.yml
# Reduce container memory limits or upgrade server

# Enable swap if not already enabled
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Getting Help

- **Documentation**: Review [Supabase Self-Hosting Docs](https://supabase.com/docs/guides/self-hosting)
- **ZITADEL Docs**: Check [ZITADEL Documentation](https://zitadel.com/docs)
- **Community**: Join [Supabase Discord](https://discord.supabase.com)
- **Support**: Open issue in your repository with logs and error details

---

## References

### Internal Documentation

- [ZITADEL SAML IdP Setup Guide](ZITADEL_SAML_IDP_SETUP.md) - Phase 1 configuration
- [DevOps Setup Guide](../DEVOPS.md) - CI/CD and deployment workflows
- [README](../README.md) - Project overview and authentication setup

### External Documentation

- [Supabase Self-Hosting](https://supabase.com/docs/guides/self-hosting)
- [Supabase Docker Setup](https://supabase.com/docs/guides/self-hosting/docker)
- [ZITADEL Documentation](https://zitadel.com/docs)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
- [Docker Production Best Practices](https://docs.docker.com/config/containers/resource_constraints/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

### Tools & Resources

- [SAML Tracer Browser Extension](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
- [JWT.io Debugger](https://jwt.io/)
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)
- [Online SAML Metadata Validator](https://www.samltool.com/validate_xml.php)

---

**Document Version**: 1.0.0  
**Last Updated**: 2024-01-09  
**Phase**: 4 - Production Deployment  
**Status**: ✅ Complete

For questions or issues with this guide, please open an issue in the repository.
