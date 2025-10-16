# SAML Authentication Examples

Example implementations for SAML SSO authentication with ZITADEL and self-hosted Supabase.

## Contents

- [Frontend Examples](#frontend-examples)
- [Backend Examples](#backend-examples)
- [Testing](#testing)
- [Integration Patterns](#integration-patterns)

---

## Frontend Examples

### React with Supabase Client

See: [frontend/react-saml-auth.tsx](frontend/react-saml-auth.tsx)

**Features:**
- SAML SSO login button
- Session management
- Automatic token refresh
- Protected routes
- Error handling

**Usage:**
```bash
cd frontend
npm install @supabase/supabase-js react react-dom
```

### Vue.js Example

See: [frontend/vue-saml-auth.vue](frontend/vue-saml-auth.vue)

**Features:**
- Composition API
- TypeScript support
- SAML authentication flow
- User state management

### Vanilla JavaScript

See: [frontend/vanilla-saml-auth.html](frontend/vanilla-saml-auth.html)

**Features:**
- No framework dependencies
- Simple integration
- Works in any HTML page

---

## Backend Examples

### Node.js / Express

See: [backend/node-express-saml.js](backend/node-express-saml.js)

**Features:**
- SAML provider management
- Admin API integration
- Session validation
- API route protection

**Usage:**
```bash
cd backend
npm install express @supabase/supabase-js
node node-express-saml.js
```

### Python / Flask

See: [backend/python-flask-saml.py](backend/python-flask-saml.py)

**Features:**
- Admin API calls
- Provider CRUD operations
- User authentication
- JWT validation

**Usage:**
```bash
cd backend
pip install flask requests
python python-flask-saml.py
```

### Deno / Supabase Edge Function

See: [backend/deno-edge-saml.ts](backend/deno-edge-saml.ts)

**Features:**
- Serverless SAML handling
- Zero-config deployment
- TypeScript native

---

## Integration Patterns

### Pattern 1: Domain-Based SSO Detection

Automatically detect and redirect users based on email domain:

```typescript
async function loginWithEmail(email: string) {
  const domain = email.split('@')[1];
  
  // Check if domain has SSO configured
  const { data: provider } = await supabase.rpc('get_sso_provider_by_domain', {
    email_domain: domain
  });
  
  if (provider) {
    // Redirect to SSO
    window.location.href = `${SUPABASE_URL}/auth/v1/sso?domain=${domain}`;
  } else {
    // Use email/password login
    await supabase.auth.signInWithPassword({ email, password });
  }
}
```

### Pattern 2: Explicit SSO Button

Provide dedicated SSO login button:

```typescript
function LoginPage() {
  const loginWithSSO = () => {
    const domain = 'yourcompany.com'; // Or get from user input
    window.location.href = `${SUPABASE_URL}/auth/v1/sso?domain=${domain}`;
  };
  
  return (
    <div>
      <button onClick={loginWithSSO}>
        Sign in with Company SSO
      </button>
    </div>
  );
}
```

### Pattern 3: Provider ID Direct Link

Use specific provider ID for multi-tenant applications:

```typescript
function LoginWithProvider({ providerId }: { providerId: string }) {
  const handleLogin = () => {
    window.location.href = `${SUPABASE_URL}/auth/v1/sso?provider_id=${providerId}`;
  };
  
  return <button onClick={handleLogin}>Sign in with ZITADEL</button>;
}
```

---

## Testing

### Manual Testing

1. **Start Local Supabase:**
   ```bash
   npm run db:start
   ```

2. **Configure SAML Provider:**
   ```bash
   export SERVICE_ROLE_KEY="your-key"
   ./scripts/saml-setup.sh
   ```

3. **Run Example:**
   ```bash
   cd examples/saml-auth/frontend
   npm install
   npm run dev
   ```

4. **Test Login:**
   - Open http://localhost:3000
   - Click "Sign in with SSO"
   - Complete ZITADEL authentication
   - Verify redirect back and session created

### Automated Testing

```bash
# Run integration tests
cd examples/saml-auth
npm test

# Test SAML flow with Playwright
npx playwright test saml-auth.spec.ts
```

### Test Users

Use the test users from your ZITADEL instance:
- testuser1@yourcompany.com
- testuser2@yourcompany.com

---

## Common Issues

### Issue: Redirect URI Mismatch

**Error:** "Redirect URI does not match"

**Solution:**
- Verify ACS URL in ZITADEL matches Supabase URL
- Check for http vs https mismatch
- Ensure no trailing slashes

### Issue: CORS Errors

**Error:** "Cross-origin request blocked"

**Solution:**
```typescript
// In Supabase, CORS is handled automatically
// For custom domains, update Kong configuration
```

### Issue: Session Not Persisting

**Error:** User logged out after page refresh

**Solution:**
```typescript
// Enable session persistence
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  }
});
```

---

## Best Practices

### Security

1. **Never expose Service Role Key in frontend**
   ```typescript
   // ❌ BAD - Never in frontend
   const supabase = createClient(url, SERVICE_ROLE_KEY);
   
   // ✅ GOOD - Use anon key in frontend
   const supabase = createClient(url, ANON_KEY);
   ```

2. **Validate sessions on backend**
   ```typescript
   // Backend API route
   const token = req.headers.authorization?.replace('Bearer ', '');
   const { data: { user }, error } = await supabase.auth.getUser(token);
   if (error || !user) {
     return res.status(401).json({ error: 'Unauthorized' });
   }
   ```

3. **Use HTTPS in production**
   ```typescript
   const SUPABASE_URL = process.env.NODE_ENV === 'production'
     ? 'https://your-domain.com'
     : 'http://localhost:8000';
   ```

### User Experience

1. **Handle loading states**
   ```typescript
   const [loading, setLoading] = useState(false);
   
   const login = async () => {
     setLoading(true);
     try {
       window.location.href = ssoUrl;
     } finally {
       setLoading(false);
     }
   };
   ```

2. **Show clear error messages**
   ```typescript
   const [error, setError] = useState<string | null>(null);
   
   // Display user-friendly errors
   if (error === 'email_not_found') {
     return <p>Your organization hasn't enabled SSO yet.</p>;
   }
   ```

3. **Provide fallback authentication**
   ```typescript
   <div>
     <button onClick={loginWithSSO}>Sign in with SSO</button>
     <button onClick={loginWithPassword}>Sign in with Password</button>
   </div>
   ```

---

## Additional Resources

- **Main Guide**: [docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md](../../docs/AUTH_ZITADEL_SAML_SELF_HOSTED.md)
- **API Reference**: [docs/SAML_ADMIN_API.md](../../docs/SAML_ADMIN_API.md)
- **User Guide**: [docs/USER_GUIDE_SAML.md](../../docs/USER_GUIDE_SAML.md)
- **Troubleshooting**: [docs/runbooks/saml-troubleshooting-self-hosted.md](../../docs/runbooks/saml-troubleshooting-self-hosted.md)

---

## Contributing

Found an issue or have an improvement? Please open a GitHub issue or submit a pull request.

---

**Version**: 1.0.0  
**Last Updated**: 2024-01-01
