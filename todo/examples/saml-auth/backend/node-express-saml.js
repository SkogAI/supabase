/**
 * Node.js Express SAML SSO Example
 * 
 * Backend server demonstrating:
 * - SAML provider management via Admin API
 * - Session validation
 * - Protected API routes
 * - User profile retrieval
 */

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');

// Configuration
const PORT = process.env.PORT || 3001;
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://localhost:8000';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
  console.error('Error: SUPABASE_SERVICE_ROLE_KEY and SUPABASE_ANON_KEY must be set');
  process.exit(1);
}

// Create Supabase clients
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ===== Authentication Middleware =====

async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing authorization token' });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Verify token and get user
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    // Attach user to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

async function requireAdmin(req, res, next) {
  // In production, check if user has admin role
  // For this example, we'll use service role key presence
  if (!req.headers['x-admin-key'] || req.headers['x-admin-key'] !== process.env.ADMIN_KEY) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

// ===== Public Routes =====

app.get('/', (req, res) => {
  res.json({
    message: 'SAML SSO API Server',
    version: '1.0.0',
    endpoints: {
      public: [
        'GET  /',
        'GET  /health',
        'GET  /auth/sso-url',
      ],
      protected: [
        'GET  /api/me',
        'GET  /api/profile',
      ],
      admin: [
        'GET    /admin/providers',
        'POST   /admin/providers',
        'GET    /admin/providers/:id',
        'PUT    /admin/providers/:id',
        'DELETE /admin/providers/:id',
      ]
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Generate SSO URL for domain
app.get('/auth/sso-url', (req, res) => {
  const { domain } = req.query;
  
  if (!domain) {
    return res.status(400).json({ error: 'domain query parameter required' });
  }

  const ssoUrl = `${SUPABASE_URL}/auth/v1/sso?domain=${domain}`;
  res.json({ url: ssoUrl });
});

// ===== Protected Routes (User) =====

// Get current user info
app.get('/api/me', requireAuth, (req, res) => {
  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      metadata: req.user.user_metadata,
      created_at: req.user.created_at,
    }
  });
});

// Get user profile from database
app.get('/api/profile', requireAuth, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Profile not found' });
      }
      throw error;
    }

    res.json({ profile: data });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// ===== Admin Routes (SAML Provider Management) =====

// List all SAML providers
app.get('/admin/providers', requireAdmin, async (req, res) => {
  try {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to fetch providers');
    }

    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error('Error listing providers:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get single SAML provider
app.get('/admin/providers/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    
    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers/${id}`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      if (response.status === 404) {
        return res.status(404).json({ error: 'Provider not found' });
      }
      const error = await response.json();
      throw new Error(error.error || 'Failed to fetch provider');
    }

    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error('Error fetching provider:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create new SAML provider
app.post('/admin/providers', requireAdmin, async (req, res) => {
  try {
    const { type, domains, metadata_url, metadata_xml, attribute_mapping } = req.body;

    // Validation
    if (!type || type !== 'saml') {
      return res.status(400).json({ error: 'type must be "saml"' });
    }
    if (!domains || !Array.isArray(domains) || domains.length === 0) {
      return res.status(400).json({ error: 'domains array is required' });
    }
    if (!metadata_url && !metadata_xml) {
      return res.status(400).json({ error: 'Either metadata_url or metadata_xml is required' });
    }
    if (!attribute_mapping || !attribute_mapping.keys || !attribute_mapping.keys.email) {
      return res.status(400).json({ error: 'attribute_mapping.keys.email is required' });
    }

    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body)
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    const data = await response.json();
    res.status(201).json(data);
  } catch (error) {
    console.error('Error creating provider:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update SAML provider
app.put('/admin/providers/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers/${id}`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body)
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error('Error updating provider:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete SAML provider
app.delete('/admin/providers/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers/${id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json(error);
    }

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting provider:', error);
    res.status(500).json({ error: error.message });
  }
});

// ===== Helper Routes =====

// Get provider by domain
app.get('/api/provider-by-domain', async (req, res) => {
  try {
    const { domain } = req.query;
    
    if (!domain) {
      return res.status(400).json({ error: 'domain query parameter required' });
    }

    const response = await fetch(`${SUPABASE_URL}/auth/v1/admin/sso/providers`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      throw new Error('Failed to fetch providers');
    }

    const data = await response.json();
    const provider = data.items?.find(p => p.domains.includes(domain));

    if (!provider) {
      return res.status(404).json({ error: 'No SSO provider configured for this domain' });
    }

    res.json({ provider: { id: provider.id, domains: provider.domains } });
  } catch (error) {
    console.error('Error finding provider:', error);
    res.status(500).json({ error: error.message });
  }
});

// ===== Error Handling =====

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ===== Start Server =====

app.listen(PORT, () => {
  console.log(`\n🚀 SAML SSO API Server running on http://localhost:${PORT}`);
  console.log(`📖 API Documentation: http://localhost:${PORT}/`);
  console.log(`🔧 Supabase URL: ${SUPABASE_URL}\n`);
});

// ===== Example Usage =====

/*
// .env file:
SUPABASE_URL=http://localhost:8000
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
ADMIN_KEY=your-admin-key
PORT=3001

// Install dependencies:
npm install express @supabase/supabase-js cors

// Run server:
node node-express-saml.js

// Test endpoints:

# Get SSO URL
curl http://localhost:3001/auth/sso-url?domain=yourcompany.com

# Get current user (requires auth token)
curl http://localhost:3001/api/me \
  -H "Authorization: Bearer your-user-token"

# List providers (requires admin key)
curl http://localhost:3001/admin/providers \
  -H "X-Admin-Key: your-admin-key"

# Create provider
curl -X POST http://localhost:3001/admin/providers \
  -H "X-Admin-Key: your-admin-key" \
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
*/
