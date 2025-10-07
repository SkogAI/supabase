# SSL/TLS Setup Guide for MCP Servers

## Overview

Secure Socket Layer (SSL) / Transport Layer Security (TLS) encryption is essential for securing connections between MCP servers and Supabase databases. This guide covers SSL configuration, certificate management, and troubleshooting.

## Why SSL Matters

- **Data Encryption**: Protects sensitive data in transit
- **Authentication**: Verifies server identity
- **Compliance**: Required for production environments
- **Security**: Prevents man-in-the-middle attacks

## SSL Modes

Supabase supports multiple SSL modes for different security requirements:

| Mode | Encryption | Certificate Validation | Use Case |
|------|-----------|----------------------|----------|
| `disable` | ❌ None | ❌ None | **Never use** (dev only, not recommended) |
| `require` | ✅ Yes | ❌ No | Quick testing, not production |
| `verify-ca` | ✅ Yes | ⚠️ Partial | Verify certificate authority |
| `verify-full` | ✅ Yes | ✅ Full | **Production recommended** |

## Recommended Configuration

### Production (verify-full)

```bash
PGSSLMODE=verify-full
PGSSLROOTCERT=/path/to/supabase-ca.crt
```

**MCP Configuration:**
```json
{
  "mcpServers": {
    "supabase": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${DATABASE_URL}"],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "${SSL_CERT_PATH}"
      }
    }
  }
}
```

### Development (require)

```bash
PGSSLMODE=require
```

**Note**: Only use `require` for local development. Always use `verify-full` in production.

## Getting SSL Certificates

### Option 1: Download from Supabase Dashboard

1. **Navigate to Project Settings**
   ```
   https://app.supabase.com/project/[PROJECT-REF]/settings/database
   ```

2. **Find SSL Certificate Section**
   - Scroll to "Connection string"
   - Click "Download certificate"
   - Save as `supabase-ca.crt`

3. **Store Certificate Securely**
   ```bash
   # Create certs directory
   mkdir -p ~/.supabase/certs
   
   # Move certificate
   mv ~/Downloads/supabase-ca.crt ~/.supabase/certs/
   
   # Set permissions
   chmod 600 ~/.supabase/certs/supabase-ca.crt
   ```

### Option 2: Use System CA Bundle

Most systems include CA certificates for public CAs:

**Linux:**
```bash
PGSSLROOTCERT=/etc/ssl/certs/ca-certificates.crt
```

**macOS:**
```bash
PGSSLROOTCERT=/etc/ssl/cert.pem
```

**Windows:**
```powershell
# Windows uses system certificate store automatically
# No manual configuration needed
```

### Option 3: Download Certificate via Command Line

```bash
# Get certificate from Supabase
curl -o ~/.supabase/certs/supabase-ca.crt \
  https://supabase.com/docs/guides/platform/ssl-certificates/supabase-ca.crt

# Verify certificate
openssl x509 -in ~/.supabase/certs/supabase-ca.crt -text -noout
```

## Configuration by Connection Type

### Direct Connection (IPv6)

```json
{
  "mcpServers": {
    "supabase-direct": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "postgresql://postgres.[PROJECT]:[PASS]@[PROJECT].supabase.co:5432/postgres?sslmode=verify-full"
      ],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "~/.supabase/certs/supabase-ca.crt"
      }
    }
  }
}
```

### Session Mode Pooler

```json
{
  "mcpServers": {
    "supabase-session": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "postgresql://postgres.[PROJECT]:[PASS]@aws-0-[REGION].pooler.supabase.com:5432/postgres"
      ],
      "env": {
        "PGSSLMODE": "verify-full",
        "PGSSLROOTCERT": "~/.supabase/certs/supabase-ca.crt"
      }
    }
  }
}
```

### Transaction Mode Pooler

```json
{
  "mcpServers": {
    "supabase-transaction": {
      "command": "mcp-server-postgres",
      "args": [
        "--connection-string",
        "postgresql://postgres.[PROJECT]:[PASS]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=verify-full&prepareStatement=false"
      ],
      "env": {
        "PGSSLMODE": "verify-full"
      }
    }
  }
}
```

## Language-Specific SSL Configuration

### Node.js (pg)

```javascript
const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('~/.supabase/certs/supabase-ca.crt').toString()
  }
});
```

**Alternative (using environment variable):**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true }
  // Uses PGSSLROOTCERT from environment
});
```

### Python (psycopg2)

```python
import psycopg2
import os

conn = psycopg2.connect(
    os.environ['DATABASE_URL'],
    sslmode='verify-full',
    sslrootcert=os.path.expanduser('~/.supabase/certs/supabase-ca.crt')
)
```

**Alternative (SQLAlchemy):**
```python
from sqlalchemy import create_engine

engine = create_engine(
    os.environ['DATABASE_URL'],
    connect_args={
        'sslmode': 'verify-full',
        'sslrootcert': os.path.expanduser('~/.supabase/certs/supabase-ca.crt')
    }
)
```

### Python (asyncpg)

```python
import asyncpg
import os

conn = await asyncpg.connect(
    os.environ['DATABASE_URL'],
    ssl='require',  # asyncpg uses 'require' for full verification
    server_settings={
        'ssl_ca_file': os.path.expanduser('~/.supabase/certs/supabase-ca.crt')
    }
)
```

### Deno (postgres)

```typescript
import { Pool } from "https://deno.land/x/postgres/mod.ts";

const pool = new Pool({
  connectionString: Deno.env.get("DATABASE_URL"),
  tls: {
    enabled: true,
    enforce: true,
    caCertificates: [
      await Deno.readTextFile(Deno.env.get("SSL_CERT_PATH")!)
    ]
  }
}, 10);
```

### Go (lib/pq)

```go
import (
    "database/sql"
    _ "github.com/lib/pq"
)

connStr := os.Getenv("DATABASE_URL") + 
    "?sslmode=verify-full&sslrootcert=" + 
    os.Getenv("SSL_CERT_PATH")

db, err := sql.Open("postgres", connStr)
```

### Rust (tokio-postgres)

```rust
use tokio_postgres::{Config, NoTls};

let mut config = Config::from_str(&env::var("DATABASE_URL")?)?;
config.ssl_mode(SslMode::Require);

let (client, connection) = config.connect(NoTls).await?;
```

## Environment-Specific Configuration

### Local Development

**Relaxed SSL for testing (NOT for production):**

```bash
# .env.development
PGSSLMODE=require
# No certificate needed
```

```json
{
  "mcpServers": {
    "supabase-dev": {
      "command": "mcp-server-postgres",
      "args": ["--connection-string", "${DATABASE_URL}"],
      "env": {
        "PGSSLMODE": "require"
      }
    }
  }
}
```

### Staging Environment

**Full verification with staging certificate:**

```bash
# .env.staging
PGSSLMODE=verify-full
PGSSLROOTCERT=/etc/ssl/certs/staging-ca.crt
```

### Production Environment

**Strict verification with production certificate:**

```bash
# .env.production
PGSSLMODE=verify-full
PGSSLROOTCERT=/etc/ssl/certs/supabase-ca.crt
# Never use PGSSLMODE=disable or require in production
```

## Docker Configuration

### Dockerfile

```dockerfile
FROM node:20-alpine

# Install SSL certificates
RUN apk add --no-cache ca-certificates

# Copy application
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .

# Copy SSL certificate
COPY certs/supabase-ca.crt /etc/ssl/certs/supabase-ca.crt

# Set SSL environment variables
ENV PGSSLMODE=verify-full
ENV PGSSLROOTCERT=/etc/ssl/certs/supabase-ca.crt

CMD ["node", "server.js"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  mcp-server:
    build: .
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - PGSSLMODE=verify-full
      - PGSSLROOTCERT=/etc/ssl/certs/supabase-ca.crt
    volumes:
      - ./certs/supabase-ca.crt:/etc/ssl/certs/supabase-ca.crt:ro
```

## Kubernetes Configuration

### Secret for Certificate

```bash
# Create Kubernetes secret
kubectl create secret generic supabase-ssl-cert \
  --from-file=ca.crt=./supabase-ca.crt
```

### Deployment with SSL

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server
spec:
  template:
    spec:
      containers:
      - name: mcp-server
        image: mcp-server:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secrets
              key: connection-string
        - name: PGSSLMODE
          value: "verify-full"
        - name: PGSSLROOTCERT
          value: "/etc/ssl/certs/supabase-ca.crt"
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs
          readOnly: true
      volumes:
      - name: ssl-certs
        secret:
          secretName: supabase-ssl-cert
```

## Verifying SSL Connection

### Using psql

```bash
# Test connection with SSL
psql "$DATABASE_URL?sslmode=verify-full" \
  -c "SELECT version();"

# Check SSL status
psql "$DATABASE_URL" \
  -c "SHOW ssl;" \
  -c "SELECT * FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
```

### Using openssl

```bash
# Test SSL handshake
openssl s_client -connect [PROJECT-REF].supabase.co:5432 \
  -starttls postgres \
  -CAfile ~/.supabase/certs/supabase-ca.crt

# Check certificate details
openssl x509 -in ~/.supabase/certs/supabase-ca.crt -text -noout
```

### Programmatic Verification (Node.js)

```javascript
const { Pool } = require('pg');
const fs = require('fs');

async function verifySSL() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: true,
      ca: fs.readFileSync(process.env.SSL_CERT_PATH).toString()
    }
  });

  try {
    const client = await pool.connect();
    
    // Check SSL status
    const result = await client.query(`
      SELECT 
        ssl.pid,
        ssl.ssl,
        ssl.version,
        ssl.cipher,
        ssl.bits
      FROM pg_stat_ssl ssl
      WHERE ssl.pid = pg_backend_pid()
    `);
    
    console.log('✅ SSL Connection verified:');
    console.log(result.rows[0]);
    
    client.release();
  } catch (err) {
    console.error('❌ SSL verification failed:', err.message);
  } finally {
    await pool.end();
  }
}

verifySSL();
```

## Troubleshooting SSL Issues

### Issue 1: "SSL connection error"

**Error:**
```
Error: unable to get local issuer certificate
```

**Solutions:**

1. **Verify certificate path:**
   ```bash
   ls -la ~/.supabase/certs/supabase-ca.crt
   ```

2. **Check file permissions:**
   ```bash
   chmod 600 ~/.supabase/certs/supabase-ca.crt
   ```

3. **Verify certificate content:**
   ```bash
   openssl x509 -in ~/.supabase/certs/supabase-ca.crt -text -noout
   ```

4. **Use system CA bundle:**
   ```bash
   # Linux
   export PGSSLROOTCERT=/etc/ssl/certs/ca-certificates.crt
   
   # macOS
   export PGSSLROOTCERT=/etc/ssl/cert.pem
   ```

### Issue 2: "certificate verify failed"

**Error:**
```
Error: certificate verify failed: unable to verify the first certificate
```

**Solutions:**

1. **Download latest certificate:**
   ```bash
   curl -o ~/.supabase/certs/supabase-ca.crt \
     https://supabase.com/docs/guides/platform/ssl-certificates/supabase-ca.crt
   ```

2. **Use correct SSL mode:**
   ```bash
   # Ensure using verify-full
   export PGSSLMODE=verify-full
   ```

3. **Check certificate expiration:**
   ```bash
   openssl x509 -in ~/.supabase/certs/supabase-ca.crt -noout -dates
   ```

### Issue 3: "SSL is not supported"

**Error:**
```
Error: connection requires a password; password authentication failed
```

**Solutions:**

1. **Verify SSL is enabled:**
   ```bash
   psql "$DATABASE_URL" -c "SHOW ssl;"
   ```

2. **Add sslmode to connection string:**
   ```bash
   export DATABASE_URL="${DATABASE_URL}?sslmode=require"
   ```

3. **Update PostgreSQL client library:**
   ```bash
   npm update pg
   # or
   pip install --upgrade psycopg2-binary
   ```

### Issue 4: "self-signed certificate"

**Error:**
```
Error: self signed certificate in certificate chain
```

**Solutions:**

1. **For development only (NOT production):**
   ```bash
   export PGSSLMODE=require  # Less strict
   ```

2. **Or in code (NOT recommended for production):**
   ```javascript
   ssl: { rejectUnauthorized: false }  // NEVER use in production
   ```

3. **Proper solution - Use correct CA certificate:**
   ```bash
   export PGSSLROOTCERT=/path/to/correct/ca.crt
   ```

## Security Best Practices

### ✅ DO

1. **Always use SSL in production**
   ```bash
   PGSSLMODE=verify-full
   ```

2. **Store certificates securely**
   ```bash
   chmod 600 ~/.supabase/certs/supabase-ca.crt
   ```

3. **Use environment variables**
   ```bash
   export PGSSLROOTCERT=~/.supabase/certs/supabase-ca.crt
   ```

4. **Rotate certificates regularly**
   - Check expiration dates
   - Update before expiry
   - Test new certificates in staging first

5. **Monitor SSL connections**
   ```sql
   SELECT * FROM pg_stat_ssl;
   ```

### ❌ DON'T

1. **Never disable SSL in production**
   ```bash
   # NEVER do this in production:
   PGSSLMODE=disable
   ```

2. **Never commit certificates to Git**
   ```gitignore
   # .gitignore
   *.crt
   *.pem
   *.key
   certs/
   ```

3. **Never use rejectUnauthorized: false in production**
   ```javascript
   // NEVER in production:
   ssl: { rejectUnauthorized: false }
   ```

4. **Never share certificates publicly**
   - Keep certificates in secure storage
   - Use secrets management (AWS Secrets Manager, etc.)
   - Limit file permissions

## Certificate Management

### Checking Certificate Expiration

```bash
# Check certificate validity period
openssl x509 -in ~/.supabase/certs/supabase-ca.crt -noout -dates

# Output:
# notBefore=Jan  1 00:00:00 2024 GMT
# notAfter=Dec 31 23:59:59 2034 GMT
```

### Automated Certificate Renewal

```bash
#!/bin/bash
# renew-cert.sh

CERT_PATH="~/.supabase/certs/supabase-ca.crt"
CERT_URL="https://supabase.com/docs/guides/platform/ssl-certificates/supabase-ca.crt"

# Check days until expiration
EXPIRY_DATE=$(openssl x509 -in "$CERT_PATH" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
  echo "Certificate expires in $DAYS_UNTIL_EXPIRY days. Renewing..."
  curl -o "$CERT_PATH" "$CERT_URL"
  chmod 600 "$CERT_PATH"
  echo "Certificate renewed successfully"
fi
```

## Next Steps

- **Configuration Templates**: [MCP Configuration](./configuration-templates.md)
- **Connection Types**: [Connection Methods](./connection-types.md)
- **Troubleshooting**: [Common Issues](./troubleshooting.md)
- **Monitoring**: [Setup Monitoring](./monitoring.md)

---

**Last Updated**: 2025-01-07  
**Version**: 1.0.0
