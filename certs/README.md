# SSL/TLS Certificates Directory

This directory stores SSL/TLS certificates for secure database connections.

## ⚠️ Security Notice

**NEVER commit actual certificates to version control!**

All certificate files (`.crt`, `.pem`, `.key`) are excluded via `.gitignore`.

## Certificate Management

### Downloading Supabase SSL Certificate

#### Method 1: Supabase Dashboard (Recommended)

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Settings** → **Database**
4. Scroll to **Connection Info** section
5. Click **Download SSL Certificate**
6. Save as `prod-ca-2021.crt` in this directory

#### Method 2: Direct Download via cURL

```bash
# Download Supabase production CA certificate
curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt

# Alternative: AWS RDS global bundle (Supabase uses AWS RDS)
curl -o certs/rds-ca-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

#### Method 3: Extract from Connection Info

Some Supabase projects may have the certificate embedded in connection info. Check your project's database settings.

### Certificate Files Structure

```
certs/
├── .gitignore              # Protects certificates from being committed
├── README.md               # This file
├── prod-ca-2021.crt       # Production certificate (download from Supabase)
├── staging-ca.crt         # Staging certificate (if different)
└── backup/                # Backup directory for rotated certificates
    └── prod-ca-2021.crt.20250109.bak
```

### Setting File Permissions

After downloading certificates, set restrictive permissions:

```bash
# Linux/macOS
chmod 600 certs/*.crt
chmod 700 certs

# Verify permissions
ls -la certs/
```

### Certificate Validation

Verify your certificate is valid:

```bash
# Check certificate format
openssl x509 -in certs/prod-ca-2021.crt -text -noout

# Check expiration date
openssl x509 -in certs/prod-ca-2021.crt -enddate -noout

# Verify certificate details
openssl x509 -in certs/prod-ca-2021.crt -noout -subject -issuer -dates
```

## Usage

### Environment Variables

Add to your `.env` file:

```bash
# SSL Certificate Path
SSL_CERT_PATH=./certs/prod-ca-2021.crt

# Database URL with SSL
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=./certs/prod-ca-2021.crt
```

### Connection String

```bash
# Full SSL verification (recommended for production)
postgresql://postgres:[PASSWORD]@db.xxx.supabase.co:5432/postgres?sslmode=verify-full&sslrootcert=/absolute/path/to/certs/prod-ca-2021.crt

# Session pooler with SSL
postgresql://postgres:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres?sslmode=verify-full&sslrootcert=/absolute/path/to/certs/prod-ca-2021.crt

# Transaction pooler with SSL
postgresql://postgres:[PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=verify-full&sslrootcert=/absolute/path/to/certs/prod-ca-2021.crt
```

### Code Examples

#### Node.js

```typescript
import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';

const sslCA = fs.readFileSync(
  path.join(__dirname, '../certs/prod-ca-2021.crt'),
  'utf8'
);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: sslCA,
  },
});
```

#### Python

```python
import asyncpg
from pathlib import Path

ssl_cert = Path(__file__).parent.parent / 'certs' / 'prod-ca-2021.crt'

pool = await asyncpg.create_pool(
    os.getenv('DATABASE_URL'),
    ssl='require',
    server_settings={
        'ssl_min_protocol_version': 'TLSv1.2'
    }
)
```

## Certificate Rotation

### When to Rotate

- **Regular schedule**: Every 90-365 days (recommended: 90 days)
- **Certificate expiration**: 30 days before expiry
- **Security incident**: Immediately if compromised
- **Compliance**: As required by security policies

### Rotation Procedure

1. **Backup current certificate**:
   ```bash
   mkdir -p certs/backup
   cp certs/prod-ca-2021.crt certs/backup/prod-ca-2021.crt.$(date +%Y%m%d).bak
   ```

2. **Download new certificate**:
   ```bash
   curl -o certs/prod-ca-2021.crt.new https://supabase.com/downloads/prod-ca-2021.crt
   ```

3. **Verify new certificate**:
   ```bash
   openssl x509 -in certs/prod-ca-2021.crt.new -text -noout
   ```

4. **Replace certificate**:
   ```bash
   mv certs/prod-ca-2021.crt.new certs/prod-ca-2021.crt
   chmod 600 certs/prod-ca-2021.crt
   ```

5. **Test connection**:
   ```bash
   psql "postgresql://...?sslmode=verify-full&sslrootcert=certs/prod-ca-2021.crt"
   ```

6. **Deploy to all environments**

### Automated Rotation Script

See `scripts/rotate-ssl-cert.sh` (if available) or create one:

```bash
#!/bin/bash
# rotate-ssl-cert.sh

CERT_DIR="./certs"
CERT_NAME="prod-ca-2021.crt"
CERT_URL="https://supabase.com/downloads/prod-ca-2021.crt"

# Backup
mkdir -p "$CERT_DIR/backup"
cp "$CERT_DIR/$CERT_NAME" "$CERT_DIR/backup/${CERT_NAME}.$(date +%Y%m%d_%H%M%S).bak"

# Download new certificate
curl -o "$CERT_DIR/$CERT_NAME" "$CERT_URL"

# Verify
if openssl x509 -in "$CERT_DIR/$CERT_NAME" -noout; then
    echo "✅ Certificate rotated successfully"
    chmod 600 "$CERT_DIR/$CERT_NAME"
else
    echo "❌ Certificate validation failed"
    exit 1
fi
```

## Troubleshooting

### Certificate Not Found

```bash
# Verify file exists
ls -la certs/prod-ca-2021.crt

# Check path in connection string
echo $DATABASE_URL

# Use absolute path
DATABASE_URL=postgresql://...?sslrootcert=/absolute/path/to/certs/prod-ca-2021.crt
```

### Permission Denied

```bash
# Fix permissions
chmod 600 certs/*.crt
chmod 700 certs

# Check current user
whoami

# Check file ownership
ls -la certs/
```

### Certificate Expired

```bash
# Check expiration
openssl x509 -in certs/prod-ca-2021.crt -enddate -noout

# Download fresh certificate
curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt
```

### Invalid Certificate Format

```bash
# Validate certificate
openssl x509 -in certs/prod-ca-2021.crt -text -noout

# Check for corruption
file certs/prod-ca-2021.crt

# Re-download if corrupted
curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt
```

## Security Best Practices

1. **Never commit certificates**: Always in `.gitignore`
2. **Restrict permissions**: `chmod 600` for certificate files
3. **Rotate regularly**: Every 90 days minimum
4. **Monitor expiration**: Set alerts 30 days before expiry
5. **Backup before rotation**: Keep timestamped backups
6. **Use absolute paths**: Avoid relative paths in production
7. **Separate by environment**: Different certs for dev/staging/prod
8. **Document rotation**: Keep changelog of certificate updates

## Emergency Procedures

### Certificate Compromised

1. **Immediate actions**:
   - Rotate certificate immediately
   - Review access logs
   - Notify security team
   - Update all environments

2. **Download new certificate**:
   ```bash
   curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt
   ```

3. **Deploy urgently** to all systems

### Certificate Expired

1. **Download current certificate**:
   ```bash
   curl -o certs/prod-ca-2021.crt https://supabase.com/downloads/prod-ca-2021.crt
   ```

2. **Verify expiration**:
   ```bash
   openssl x509 -in certs/prod-ca-2021.crt -enddate -noout
   ```

3. **Deploy immediately**

## Additional Resources

- [SSL/TLS Security Guide](../docs/MCP_SSL_TLS_SECURITY.md)
- [MCP Server Configuration](../docs/MCP_SERVER_CONFIGURATION.md)
- [Supabase Security Documentation](https://supabase.com/docs/guides/platform/security)
- [PostgreSQL SSL Documentation](https://www.postgresql.org/docs/current/libpq-ssl.html)

## Support

For issues with:
- **Certificate download**: Contact Supabase support
- **Connection issues**: See [MCP_SSL_TLS_SECURITY.md](../docs/MCP_SSL_TLS_SECURITY.md) troubleshooting
- **Security concerns**: Contact your security team

---

**Last Updated**: 2025-01-09  
**Maintenance**: Review quarterly  
**Owner**: DevOps/Security Team
