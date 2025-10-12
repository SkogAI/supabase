# MCP Server SSL/TLS Security Guide

## Overview

This guide covers SSL/TLS encryption configuration for all AI agent database connections to Supabase. SSL/TLS is essential for securing database connections and protecting sensitive data in transit.

## Table of Contents

- [Why SSL/TLS is Critical](#why-ssl-tls-is-critical)
- [Certificate Management](#certificate-management)
- [SSL Modes](#ssl-modes)
- [Configuration Examples](#configuration-examples)
- [Certificate Rotation](#certificate-rotation)
- [Troubleshooting](#troubleshooting)
- [Verification Utilities](#verification-utilities)
- [Best Practices](#best-practices)

## Why SSL/TLS is Critical

### Security Benefits

SSL/TLS encryption provides:

- **Encryption in Transit**: All data between AI agent and database is encrypted
- **Man-in-the-Middle (MITM) Protection**: Prevents attackers from intercepting or modifying data
- **Authentication**: Verifies you're connecting to the genuine Supabase server
- **Compliance**: Required for SOC 2, HIPAA, PCI-DSS, and other security standards
- **Credential Protection**: Protects database passwords and API keys during transmission

### Threats Prevented

Without SSL/TLS, your AI agents are vulnerable to:

- **Data Interception**: Attackers can read all queries and results
- **Credential Theft**: Database passwords transmitted in plaintext
- **Session Hijacking**: Attackers can impersonate your agent
- **Data Tampering**: Query results can be modified in transit
- **AI Query Exposure**: Sensitive AI prompts and context visible to attackers

## Certificate Management

### Downloading Supabase SSL Certificate

#### From Supabase Dashboard

1. Navigate to your project in [Supabase Dashboard](https://app.supabase.com)
2. Go to **Settings** → **Database**
3. Scroll to **Connection Info** section
4. Click **Download SSL Certificate**
5. Save as `prod-ca-2021.crt` or `server-ca.pem`

#### Using cURL

```bash
# Download production root certificate (global)
curl -o prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt

# Alternative: Download from AWS (Supabase uses AWS RDS)
curl -o rds-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Verify certificate format
openssl x509 -in prod-ca-2021.crt -text -noout
```

### Certificate Storage Structure

Store certificates securely in your project:

```
your-project/
├── certs/                          # Certificate directory
│   ├── .gitignore                  # Exclude from version control
│   ├── README.md                   # Certificate management guide
│   ├── prod-ca-2021.crt           # Production root CA (Supabase)
│   ├── staging-ca.crt             # Staging root CA (if different)
│   └── development-ca.crt         # Development root CA (optional)
├── .env                            # Environment variables (excluded from git)
└── .env.example                    # Template with certificate paths
```

### Securing Certificate Files

```bash
# Create certificate directory
mkdir -p certs

# Download certificate
curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt

# Set restrictive permissions (Linux/macOS)
chmod 600 certs/prod-ca-2021.crt
chmod 700 certs

# Verify permissions
ls -la certs/
```

### .gitignore Configuration

Add to your `.gitignore`:

```gitignore
# SSL Certificates (never commit actual certificates)
certs/*.crt
certs/*.pem
certs/*.key

# Allow certificate README
!certs/README.md
!certs/.gitignore
```

## SSL Modes

PostgreSQL and Supabase support multiple SSL modes with different security levels:

### SSL Mode Comparison

| Mode | Description | Encryption | Server Auth | MITM Protection | Use Case |
|------|-------------|-----------|-------------|-----------------|----------|
| `disable` | No SSL | ❌ | ❌ | ❌ | **Never use in production** |
| `allow` | SSL if available | ⚠️ | ❌ | ❌ | Not recommended |
| `prefer` | Prefer SSL | ⚠️ | ❌ | ❌ | Not recommended |
| `require` | SSL required | ✅ | ❌ | ❌ | Minimum for production |
| `verify-ca` | Verify CA certificate | ✅ | ✅ | ⚠️ | Good for production |
| `verify-full` | Full verification | ✅ | ✅ | ✅ | **Recommended for production** |

### Mode Details

#### `disable` - No SSL (Development Only)

```bash
# ⚠️ ONLY for local development
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres?sslmode=disable
```

**Use when:**
- Local Supabase development environment
- Testing on localhost
- No sensitive data involved

**Never use when:**
- Production environment
- Staging environment
- Connecting over the internet
- Handling sensitive data

#### `require` - SSL Required (Minimum)

```bash
# Minimum SSL - encrypts but doesn't verify server
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=require
```

**Provides:**
- ✅ Encryption in transit
- ❌ No server verification
- ❌ Vulnerable to MITM with fake certificates

**Use when:**
- Quick setup needed
- Certificate management not yet configured
- Better than no SSL

#### `verify-ca` - Verify Certificate Authority (Recommended)

```bash
# Verify CA certificate
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-ca&sslrootcert=/path/to/prod-ca-2021.crt
```

**Provides:**
- ✅ Encryption in transit
- ✅ Verifies server certificate is signed by trusted CA
- ⚠️ Doesn't verify hostname

**Use when:**
- Production environment
- Certificate management in place
- Need strong security

#### `verify-full` - Full Verification (Most Secure)

```bash
# Full SSL verification - RECOMMENDED
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=/path/to/prod-ca-2021.crt
```

**Provides:**
- ✅ Encryption in transit
- ✅ Verifies server certificate is signed by trusted CA
- ✅ Verifies hostname matches certificate
- ✅ Maximum MITM protection

**Use when:**
- Production environment (always)
- Handling sensitive data (always)
- Compliance requirements (SOC 2, HIPAA, etc.)

### Selecting the Right Mode

**Decision Tree:**

```
Is this production? 
├─ Yes → Use verify-full
└─ No → Is this staging/testing over internet?
    ├─ Yes → Use verify-ca or verify-full
    └─ No → Is this localhost development?
        ├─ Yes → Can use disable (optional)
        └─ No → Use require (minimum)
```

## Configuration Examples

### Environment Variables

#### .env Configuration

```bash
# SSL Certificate Paths
SSL_CERT_PATH=/path/to/certs/prod-ca-2021.crt
STAGING_SSL_CERT_PATH=/path/to/certs/staging-ca.crt

# Production Database URL with SSL
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=${SSL_CERT_PATH}

# Staging Database URL with SSL
STAGING_DATABASE_URL=postgresql://postgres:[PASSWORD]@db.yyy.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=${STAGING_SSL_CERT_PATH}

# Development (local Supabase)
DEV_DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres?sslmode=disable
```

#### .env.example Template

```bash
# SSL/TLS Configuration
# Copy this file to .env and update with your values

# SSL Certificate Paths
# Download from: Supabase Dashboard → Settings → Database → SSL Certificate
SSL_CERT_PATH=./certs/prod-ca-2021.crt
STAGING_SSL_CERT_PATH=./certs/staging-ca.crt

# Production Database Connection
# Get from: Supabase Dashboard → Settings → Database → Connection String
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=${SSL_CERT_PATH}

# SSL Mode Options:
# - disable: No SSL (development only)
# - require: SSL required, no verification
# - verify-ca: Verify certificate authority
# - verify-full: Full verification (RECOMMENDED)

# Connection Pool SSL Settings
DB_SSL_ENABLED=true
DB_SSL_MODE=verify-full
DB_SSL_REJECT_UNAUTHORIZED=true
DB_SSL_CA=${SSL_CERT_PATH}
```

### MCP Server Configuration with SSL

#### JSON Configuration (Claude Desktop, Cline, etc.)

```json
{
  "mcpServers": {
    "supabase-secure": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${SUPABASE_CONNECTION}"],
      "env": {
        "POSTGRES_CONNECTION": "${SUPABASE_CONNECTION}",
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "/absolute/path/to/certs/prod-ca-2021.crt"
      }
    }
  }
}
```

#### Node.js Configuration

```typescript
// config/database.ts
import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';

// Load SSL certificate
const sslCertPath = path.join(process.cwd(), 'certs', 'prod-ca-2021.crt');
const sslCA = fs.readFileSync(sslCertPath, 'utf8');

// Production configuration with SSL
export const productionConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: sslCA,
  },
  max: 20,
  idleTimeoutMillis: 300000,
  connectionTimeoutMillis: 10000,
};

// Create connection pool
const pool = new Pool(productionConfig);

// Verify SSL connection
pool.on('connect', (client) => {
  client.query('SELECT version(), current_setting(\'ssl_version\') as ssl_version', (err, result) => {
    if (err) {
      console.error('SSL verification failed:', err);
    } else {
      console.log('✅ Connected with SSL:', result.rows[0].ssl_version);
    }
  });
});

export default pool;
```

#### Python Configuration

```python
# config/database.py
import os
import asyncpg
from pathlib import Path

# Load SSL certificate path
SSL_CERT_PATH = Path(__file__).parent.parent / 'certs' / 'prod-ca-2021.crt'

# Production configuration
DATABASE_URL = os.getenv('DATABASE_URL')

# asyncpg with SSL
async def create_pool():
    """Create database pool with SSL verification"""
    pool = await asyncpg.create_pool(
        DATABASE_URL,
        ssl='require',  # Can be 'require', 'verify-ca', or 'verify-full'
        server_settings={
            'application_name': 'ai-agent-production',
            'ssl_min_protocol_version': 'TLSv1.2'
        },
        min_size=5,
        max_size=20,
        command_timeout=30
    )
    
    # Verify SSL connection
    async with pool.acquire() as conn:
        ssl_info = await conn.fetchval(
            "SELECT current_setting('ssl_version')"
        )
        print(f"✅ Connected with SSL: {ssl_info}")
    
    return pool
```

#### Deno Configuration

```typescript
// config/database.ts
import { Client } from "https://deno.land/x/postgres@v0.17.0/mod.ts";

// Load SSL certificate
const sslCertPath = "./certs/prod-ca-2021.crt";
const sslCA = await Deno.readTextFile(sslCertPath);

// Production client with SSL
const client = new Client({
  hostname: "db.xxx.supabase.co",
  port: 5432,
  user: "postgres.xxx",
  password: Deno.env.get("DB_PASSWORD"),
  database: "postgres",
  tls: {
    enabled: true,
    enforce: true,
    caCertificates: [sslCA],
  },
  connection: {
    attempts: 3,
    interval: 2000,
  },
});

// Connect with SSL verification
await client.connect();
console.log("✅ Connected to database with SSL/TLS");

export default client;
```

### Connection String Formats

#### Complete Connection String with SSL

```bash
# Full verification with certificate
postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=/path/to/prod-ca-2021.crt

# Supavisor Transaction Mode with SSL (port 6543)
postgresql://postgres:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=verify-full&sslrootcert=/path/to/prod-ca-2021.crt

# Supavisor Session Mode with SSL (port 5432)
postgresql://postgres:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres?sslmode=verify-full&sslrootcert=/path/to/prod-ca-2021.crt
```

#### URL-Encoded Paths

For paths with spaces or special characters:

```bash
# URL encode the certificate path
sslrootcert=/home/user/My%20Documents/certs/prod-ca-2021.crt
```

### Docker Configuration

#### Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy SSL certificates
COPY certs/prod-ca-2021.crt /app/certs/
RUN chmod 600 /app/certs/prod-ca-2021.crt

# Set environment variables
ENV SSL_CERT_PATH=/app/certs/prod-ca-2021.crt
ENV PGSSLMODE=verify-full

# Copy application
COPY . .
RUN npm ci --production

CMD ["node", "dist/index.js"]
```

#### Docker Compose

```yaml
version: '3.8'

services:
  ai-agent:
    build: .
    environment:
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=/app/certs/prod-ca-2021.crt
      - SSL_CERT_PATH=/app/certs/prod-ca-2021.crt
      - PGSSLMODE=verify-full
    volumes:
      - ./certs:/app/certs:ro  # Mount certificates as read-only
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Kubernetes Configuration

#### ConfigMap for Certificate

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-ssl-cert
  namespace: ai-agents
data:
  prod-ca-2021.crt: |
    -----BEGIN CERTIFICATE-----
    [Certificate content here]
    -----END CERTIFICATE-----
```

#### Deployment with SSL

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: ai-agent
        image: your-registry/ai-agent:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: SSL_CERT_PATH
          value: /etc/ssl/certs/prod-ca-2021.crt
        - name: PGSSLMODE
          value: verify-full
        volumeMounts:
        - name: ssl-cert
          mountPath: /etc/ssl/certs
          readOnly: true
      volumes:
      - name: ssl-cert
        configMap:
          name: postgres-ssl-cert
```

## Certificate Rotation

### Why Certificate Rotation is Necessary

- **Security**: Limits impact of compromised certificates
- **Compliance**: Required by security standards (90-365 day rotation)
- **Best Practice**: Reduces attack window
- **Trust**: Ensures certificates haven't expired

### Certificate Rotation Procedure

#### 1. Download New Certificate

```bash
#!/bin/bash
# rotate-ssl-cert.sh

# Configuration
CERT_DIR="./certs"
BACKUP_DIR="./certs/backup"
NEW_CERT_URL="https://supabase.com/downloads/prod-ca-2021.crt"
CERT_NAME="prod-ca-2021.crt"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current certificate
if [ -f "$CERT_DIR/$CERT_NAME" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    cp "$CERT_DIR/$CERT_NAME" "$BACKUP_DIR/${CERT_NAME}.${TIMESTAMP}.bak"
    echo "✅ Backed up existing certificate"
fi

# Download new certificate
curl -o "$CERT_DIR/$CERT_NAME.new" "$NEW_CERT_URL"

# Verify new certificate
if openssl x509 -in "$CERT_DIR/$CERT_NAME.new" -text -noout > /dev/null 2>&1; then
    echo "✅ New certificate is valid"
    mv "$CERT_DIR/$CERT_NAME.new" "$CERT_DIR/$CERT_NAME"
    chmod 600 "$CERT_DIR/$CERT_NAME"
    echo "✅ Certificate rotated successfully"
else
    echo "❌ New certificate is invalid"
    rm "$CERT_DIR/$CERT_NAME.new"
    exit 1
fi
```

#### 2. Zero-Downtime Rotation

For production systems, use this approach:

```typescript
// ssl-cert-manager.ts
import fs from 'fs';
import { Pool } from 'pg';

class SSLCertManager {
  private certPath: string;
  private pool: Pool;
  private certWatcher: fs.FSWatcher;

  constructor(certPath: string) {
    this.certPath = certPath;
    this.initializePool();
    this.watchCertificate();
  }

  private initializePool() {
    const sslCA = fs.readFileSync(this.certPath, 'utf8');
    
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: true,
        ca: sslCA,
      },
      max: 20,
    });

    console.log('✅ Connection pool initialized with current certificate');
  }

  private watchCertificate() {
    // Watch for certificate file changes
    this.certWatcher = fs.watch(this.certPath, (eventType) => {
      if (eventType === 'change') {
        console.log('🔄 Certificate file changed, rotating...');
        this.rotateCertificate();
      }
    });
  }

  private async rotateCertificate() {
    try {
      // Read new certificate
      const newSSLCA = fs.readFileSync(this.certPath, 'utf8');

      // Create new pool with new certificate
      const newPool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: {
          rejectUnauthorized: true,
          ca: newSSLCA,
        },
        max: 20,
      });

      // Test new connection
      const client = await newPool.connect();
      await client.query('SELECT 1');
      client.release();

      // Gracefully drain old pool
      await this.pool.end();

      // Switch to new pool
      this.pool = newPool;

      console.log('✅ Certificate rotated successfully');
    } catch (error) {
      console.error('❌ Certificate rotation failed:', error);
      // Keep using old pool
    }
  }

  async close() {
    this.certWatcher.close();
    await this.pool.end();
  }
}

// Usage
const certManager = new SSLCertManager('./certs/prod-ca-2021.crt');
```

#### 3. Automated Rotation with Cron

```bash
# Add to crontab: rotate certificate weekly
0 2 * * 0 /path/to/rotate-ssl-cert.sh >> /var/log/ssl-rotation.log 2>&1
```

#### 4. Certificate Expiration Monitoring

```bash
#!/bin/bash
# check-cert-expiry.sh

CERT_PATH="./certs/prod-ca-2021.crt"
WARNING_DAYS=30

# Get certificate expiration date
EXPIRY_DATE=$(openssl x509 -in "$CERT_PATH" -enddate -noout | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

echo "Certificate expires on: $EXPIRY_DATE"
echo "Days until expiry: $DAYS_UNTIL_EXPIRY"

if [ $DAYS_UNTIL_EXPIRY -lt $WARNING_DAYS ]; then
    echo "⚠️  WARNING: Certificate expires in $DAYS_UNTIL_EXPIRY days!"
    # Send alert (email, Slack, PagerDuty, etc.)
    exit 1
else
    echo "✅ Certificate is valid"
    exit 0
fi
```

### Certificate Rotation Checklist

- [ ] Download new certificate from Supabase Dashboard
- [ ] Verify new certificate format and validity
- [ ] Backup current certificate with timestamp
- [ ] Update certificate file in deployment
- [ ] Test connection with new certificate
- [ ] Deploy to staging environment first
- [ ] Monitor for connection errors
- [ ] Deploy to production environment
- [ ] Update certificate in all environments (dev, staging, prod)
- [ ] Document rotation in changelog
- [ ] Schedule next rotation reminder

## Troubleshooting

### Common SSL Connection Errors

#### Error: "certificate verify failed"

```
Error: self signed certificate in certificate chain
    at TLSSocket.onConnectSecure
```

**Causes:**
- Missing or incorrect certificate file
- Certificate path not accessible
- Wrong certificate for the database

**Solutions:**

```bash
# 1. Verify certificate exists and is readable
ls -la certs/prod-ca-2021.crt
chmod 600 certs/prod-ca-2021.crt

# 2. Verify certificate is valid
openssl x509 -in certs/prod-ca-2021.crt -text -noout

# 3. Test with curl
curl --cacert certs/prod-ca-2021.crt https://db.xxx.supabase.co:5432

# 4. Try with require mode first (less strict)
DATABASE_URL=postgresql://...?sslmode=require

# 5. Ensure path is absolute
DATABASE_URL=postgresql://...?sslmode=verify-full&sslrootcert=/absolute/path/to/prod-ca-2021.crt
```

#### Error: "SSL connection has been closed unexpectedly"

```
Error: SSL connection has been closed unexpectedly
    at Connection.parseE
```

**Causes:**
- Certificate expired
- Certificate doesn't match server
- Network interruption during SSL handshake
- Firewall blocking SSL ports

**Solutions:**

```bash
# 1. Check certificate expiration
openssl x509 -in certs/prod-ca-2021.crt -enddate -noout

# 2. Test SSL connection
openssl s_client -connect db.xxx.supabase.co:5432 -CAfile certs/prod-ca-2021.crt

# 3. Check network connectivity
telnet db.xxx.supabase.co 5432

# 4. Increase connection timeout
connectionTimeoutMillis: 10000
```

#### Error: "no pg_hba.conf entry for host"

```
Error: no pg_hba.conf entry for host "x.x.x.x", user "postgres", database "postgres", SSL off
```

**Cause:**
- Server requires SSL but client isn't using it

**Solution:**

```bash
# Enable SSL mode
DATABASE_URL=postgresql://...?sslmode=require

# Or verify-full for production
DATABASE_URL=postgresql://...?sslmode=verify-full&sslrootcert=/path/to/cert.crt
```

#### Error: "hostname does not match certificate"

```
Error: Hostname/IP does not match certificate's altnames
```

**Causes:**
- Using IP address instead of hostname
- Certificate issued for different hostname
- Using wrong pooler address

**Solutions:**

```bash
# 1. Use hostname from Supabase Dashboard, not IP
# ✅ GOOD
db.xxx.supabase.co

# ❌ BAD
192.168.1.1

# 2. For verify-full mode, hostname must match certificate
sslmode=verify-full

# 3. If using pooler, use correct pooler hostname
aws-0-us-east-1.pooler.supabase.com
```

### Debugging SSL Connections

#### Enable SSL Debug Logging (Node.js)

```typescript
// debug-ssl.ts
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('./certs/prod-ca-2021.crt', 'utf8'),
  },
  // Enable debug logging
  log: (msg) => console.log('PG:', msg),
});

// Test connection with detailed logging
async function testConnection() {
  try {
    const client = await pool.connect();
    
    // Query SSL information
    const result = await client.query(`
      SELECT 
        version() as pg_version,
        current_setting('ssl_version') as ssl_version,
        current_setting('ssl_cipher') as ssl_cipher,
        inet_server_addr() as server_ip,
        inet_server_port() as server_port
    `);
    
    console.log('✅ SSL Connection Details:', result.rows[0]);
    client.release();
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('Stack:', error.stack);
  }
}

testConnection();
```

#### Test SSL with OpenSSL

```bash
# Test SSL connection to Supabase
openssl s_client -connect db.xxx.supabase.co:5432 \
  -CAfile certs/prod-ca-2021.crt \
  -showcerts \
  -state \
  -debug

# Check certificate details
openssl x509 -in certs/prod-ca-2021.crt -text -noout | grep -E "(Issuer|Subject|Not Before|Not After|DNS)"

# Verify certificate chain
openssl verify -CAfile certs/prod-ca-2021.crt certs/prod-ca-2021.crt
```

#### Python SSL Debugging

```python
# debug_ssl.py
import asyncpg
import ssl
import logging

# Enable SSL debugging
logging.basicConfig(level=logging.DEBUG)

async def test_ssl_connection():
    # Create SSL context with debugging
    ssl_context = ssl.create_default_context(
        cafile='./certs/prod-ca-2021.crt'
    )
    ssl_context.check_hostname = True
    ssl_context.verify_mode = ssl.CERT_REQUIRED
    
    # Enable SSL debug logging
    ssl_context.set_ciphers('DEFAULT')
    
    try:
        conn = await asyncpg.connect(
            DATABASE_URL,
            ssl=ssl_context
        )
        
        # Query SSL details
        ssl_version = await conn.fetchval(
            "SELECT current_setting('ssl_version')"
        )
        print(f"✅ Connected with SSL: {ssl_version}")
        
        await conn.close()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        import traceback
        traceback.print_exc()

import asyncio
asyncio.run(test_ssl_connection())
```

### Performance Impact

#### SSL Overhead Benchmarks

SSL/TLS adds minimal overhead to modern connections:

- **Handshake**: 10-50ms (one-time per connection)
- **Encryption**: <1% CPU overhead
- **Throughput**: 5-10% reduction (typically negligible)

**Recommendation:** Always use SSL in production - the security benefits far outweigh minimal performance cost.

#### Connection Pooling with SSL

```typescript
// Recommended: Reuse connections to avoid SSL handshake overhead
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: sslCA,
  },
  max: 20,                      // Reuse up to 20 connections
  idleTimeoutMillis: 300000,    // Keep connections alive 5 minutes
  connectionTimeoutMillis: 10000,
});
```

## Verification Utilities

### SSL Connection Test Script

```typescript
// verify-ssl-connection.ts
import { Pool } from 'pg';
import fs from 'fs';
import chalk from 'chalk';

interface SSLTestResult {
  success: boolean;
  sslMode: string;
  sslVersion?: string;
  cipher?: string;
  error?: string;
}

async function testSSLConnection(
  connectionString: string,
  sslMode: string,
  certPath?: string
): Promise<SSLTestResult> {
  const config: any = {
    connectionString: connectionString.replace(/sslmode=[^&]+/, `sslmode=${sslMode}`),
    connectionTimeoutMillis: 10000,
  };

  if (certPath && (sslMode === 'verify-ca' || sslMode === 'verify-full')) {
    config.ssl = {
      rejectUnauthorized: true,
      ca: fs.readFileSync(certPath, 'utf8'),
    };
  } else if (sslMode === 'require') {
    config.ssl = {
      rejectUnauthorized: false,
    };
  }

  const pool = new Pool(config);

  try {
    const client = await pool.connect();
    const result = await client.query(`
      SELECT 
        current_setting('ssl_version') as ssl_version,
        current_setting('ssl_cipher') as cipher
    `);
    
    client.release();
    await pool.end();

    return {
      success: true,
      sslMode,
      sslVersion: result.rows[0].ssl_version,
      cipher: result.rows[0].cipher,
    };
  } catch (error: any) {
    await pool.end();
    return {
      success: false,
      sslMode,
      error: error.message,
    };
  }
}

async function runSSLTests() {
  console.log(chalk.bold('\n🔒 SSL/TLS Connection Test Suite\n'));

  const connectionString = process.env.DATABASE_URL!;
  const certPath = process.env.SSL_CERT_PATH || './certs/prod-ca-2021.crt';

  const tests = [
    { mode: 'require', description: 'SSL Required (no verification)' },
    { mode: 'verify-ca', description: 'Verify Certificate Authority', useCert: true },
    { mode: 'verify-full', description: 'Full Verification (Recommended)', useCert: true },
  ];

  for (const test of tests) {
    process.stdout.write(`Testing ${test.description}... `);
    
    const result = await testSSLConnection(
      connectionString,
      test.mode,
      test.useCert ? certPath : undefined
    );

    if (result.success) {
      console.log(chalk.green('✅ PASS'));
      console.log(chalk.gray(`  SSL Version: ${result.sslVersion}`));
      console.log(chalk.gray(`  Cipher: ${result.cipher}\n`));
    } else {
      console.log(chalk.red('❌ FAIL'));
      console.log(chalk.red(`  Error: ${result.error}\n`));
    }
  }
}

// Run tests
runSSLTests().catch(console.error);
```

### Certificate Validation Script

```bash
#!/bin/bash
# validate-ssl-cert.sh

set -e

CERT_PATH="${1:-./certs/prod-ca-2021.crt}"
HOSTNAME="${2:-db.xxx.supabase.co}"

echo "🔍 Validating SSL Certificate"
echo "Certificate: $CERT_PATH"
echo "Hostname: $HOSTNAME"
echo ""

# Check if certificate file exists
if [ ! -f "$CERT_PATH" ]; then
    echo "❌ Certificate file not found: $CERT_PATH"
    exit 1
fi

# Validate certificate format
echo "1. Validating certificate format..."
if openssl x509 -in "$CERT_PATH" -text -noout > /dev/null 2>&1; then
    echo "   ✅ Certificate format is valid"
else
    echo "   ❌ Invalid certificate format"
    exit 1
fi

# Check certificate expiration
echo "2. Checking certificate expiration..."
EXPIRY=$(openssl x509 -in "$CERT_PATH" -enddate -noout | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)

if [ $EXPIRY_EPOCH -gt $NOW_EPOCH ]; then
    DAYS=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    echo "   ✅ Certificate valid for $DAYS more days"
    echo "   Expires: $EXPIRY"
else
    echo "   ❌ Certificate has expired!"
    exit 1
fi

# Check certificate details
echo "3. Certificate details:"
openssl x509 -in "$CERT_PATH" -noout -subject -issuer

# Test SSL connection to host
echo "4. Testing SSL connection to $HOSTNAME..."
if timeout 5 openssl s_client -connect "$HOSTNAME:5432" -CAfile "$CERT_PATH" < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "   ✅ SSL connection successful"
else
    echo "   ⚠️  SSL connection test inconclusive (may need actual database credentials)"
fi

echo ""
echo "✅ Certificate validation complete"
```

## Best Practices

### 1. Always Use SSL in Production

```typescript
// ✅ GOOD: Production configuration
const productionPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('./certs/prod-ca-2021.crt', 'utf8'),
  },
});

// ❌ BAD: No SSL in production
const badPool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false,  // NEVER DO THIS IN PRODUCTION
});
```

### 2. Use verify-full Mode in Production

```bash
# ✅ GOOD: Maximum security
DATABASE_URL=postgresql://...?sslmode=verify-full&sslrootcert=/path/to/cert.crt

# ⚠️ ACCEPTABLE: Minimum security
DATABASE_URL=postgresql://...?sslmode=require

# ❌ BAD: No security
DATABASE_URL=postgresql://...?sslmode=disable
```

### 3. Never Commit Certificates to Version Control

```gitignore
# .gitignore
certs/*.crt
certs/*.pem
certs/*.key
*.pem
*.crt
*.key

# Allow certificate templates
!certs/README.md
!certs/.gitignore
```

### 4. Rotate Certificates Regularly

```bash
# Set up automated rotation
# Run every 90 days
0 0 1 */3 * /path/to/rotate-ssl-cert.sh
```

### 5. Monitor Certificate Expiration

```typescript
// cert-expiry-monitor.ts
import fs from 'fs';
import { X509Certificate } from 'crypto';

function checkCertificateExpiry(certPath: string): number {
  const certPEM = fs.readFileSync(certPath, 'utf8');
  const cert = new X509Certificate(certPEM);
  
  const validTo = new Date(cert.validTo);
  const now = new Date();
  const daysUntilExpiry = Math.floor(
    (validTo.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
  );
  
  if (daysUntilExpiry < 30) {
    console.warn(`⚠️  Certificate expires in ${daysUntilExpiry} days!`);
    // Send alert
  }
  
  return daysUntilExpiry;
}

// Check on startup and periodically
setInterval(() => {
  checkCertificateExpiry('./certs/prod-ca-2021.crt');
}, 24 * 60 * 60 * 1000); // Daily
```

### 6. Use Environment-Specific Certificates

```
config/
├── certs/
│   ├── dev/
│   │   └── localhost.crt         # Development
│   ├── staging/
│   │   └── staging-ca.crt        # Staging
│   └── production/
│       └── prod-ca-2021.crt      # Production
```

### 7. Secure Certificate Storage

```bash
# Linux/macOS permissions
chmod 600 certs/*.crt
chmod 700 certs/

# Kubernetes secret
kubectl create secret generic postgres-ssl-cert \
  --from-file=ca.crt=./certs/prod-ca-2021.crt \
  --namespace=production

# Docker secrets
docker secret create postgres_ssl_cert ./certs/prod-ca-2021.crt
```

### 8. Test SSL Configuration Before Production

```typescript
// Run SSL tests in CI/CD
describe('SSL Configuration', () => {
  it('should connect with verify-full mode', async () => {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: true,
        ca: fs.readFileSync('./certs/prod-ca-2021.crt', 'utf8'),
      },
    });

    const client = await pool.connect();
    const result = await client.query('SELECT 1');
    expect(result.rows[0]['?column?']).toBe(1);
    client.release();
    await pool.end();
  });
});
```

### 9. Document SSL Configuration

Keep a `certs/README.md` with:
- Certificate download instructions
- Rotation procedures
- Emergency contacts
- Troubleshooting steps

### 10. Implement Health Checks

```typescript
// health-check.ts
export async function checkDatabaseSSL(): Promise<boolean> {
  try {
    const client = await pool.connect();
    const result = await client.query(
      "SELECT current_setting('ssl_version') as ssl_version"
    );
    client.release();
    
    const sslVersion = result.rows[0].ssl_version;
    return sslVersion && sslVersion !== '';
  } catch (error) {
    console.error('SSL health check failed:', error);
    return false;
  }
}
```

## Related Documentation

- [MCP Server Configuration](./MCP_SERVER_CONFIGURATION.md)
- [MCP Server Architecture](./MCP_SERVER_ARCHITECTURE.md)
- [MCP Connection Examples](./MCP_CONNECTION_EXAMPLES.md)
- [MCP Authentication](./MCP_AUTHENTICATION.md)

## External Resources

- [PostgreSQL SSL Documentation](https://www.postgresql.org/docs/current/libpq-ssl.html)
- [Supabase Security](https://supabase.com/docs/guides/platform/security)
- [SSL/TLS Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html)
- [Node.js TLS](https://nodejs.org/api/tls.html)

---

**Last Updated**: 2025-01-09  
**Version**: 1.0.0  
**Status**: ✅ Production Ready  
**Priority**: 🔴 Critical - Required for Production Security
