/**
 * React SAML Authentication Example
 * 
 * Complete React component for SAML SSO authentication with Supabase
 * Features:
 * - SAML login/logout
 * - Session management
 * - Protected routes
 * - Error handling
 * - Loading states
 */

import React, { useState, useEffect, createContext, useContext } from 'react';
import { createClient, Session, User, SupabaseClient } from '@supabase/supabase-js';

// Configuration
const SUPABASE_URL = process.env.REACT_APP_SUPABASE_URL || 'http://localhost:8000';
const SUPABASE_ANON_KEY = process.env.REACT_APP_SUPABASE_ANON_KEY || 'your-anon-key';

// Create Supabase client
const supabase: SupabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  }
});

// ===== Types =====

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signInWithSSO: (domain: string) => Promise<void>;
  signOut: () => Promise<void>;
}

// ===== Auth Context =====

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signInWithSSO = async (domain: string) => {
    try {
      setLoading(true);
      // Redirect to SAML SSO
      window.location.href = `${SUPABASE_URL}/auth/v1/sso?domain=${domain}`;
    } catch (error) {
      console.error('Error signing in with SSO:', error);
      setLoading(false);
      throw error;
    }
  };

  const signOut = async () => {
    try {
      setLoading(true);
      await supabase.auth.signOut();
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const value = {
    user,
    session,
    loading,
    signInWithSSO,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// ===== Components =====

// Login Component
export const LoginPage: React.FC = () => {
  const { signInWithSSO, loading } = useAuth();
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    try {
      // Extract domain from email
      const domain = email.split('@')[1];
      if (!domain) {
        setError('Please enter a valid email address');
        return;
      }

      await signInWithSSO(domain);
    } catch (err) {
      setError('Failed to initiate SSO login. Please try again.');
      console.error(err);
    }
  };

  const handleDirectSSO = async () => {
    try {
      await signInWithSSO('yourcompany.com'); // Replace with your domain
    } catch (err) {
      setError('Failed to initiate SSO login. Please try again.');
      console.error(err);
    }
  };

  return (
    <div className="login-page">
      <h1>Sign In</h1>

      {error && (
        <div className="error-message" role="alert">
          {error}
        </div>
      )}

      {/* Method 1: Email-based SSO detection */}
      <form onSubmit={handleEmailSubmit}>
        <div className="form-group">
          <label htmlFor="email">Email Address</label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@yourcompany.com"
            required
            disabled={loading}
          />
        </div>
        <button type="submit" disabled={loading}>
          {loading ? 'Signing in...' : 'Continue with SSO'}
        </button>
      </form>

      <div className="divider">OR</div>

      {/* Method 2: Direct SSO button */}
      <button 
        onClick={handleDirectSSO} 
        disabled={loading}
        className="sso-button"
      >
        Sign in with Company SSO
      </button>

      <style jsx>{`
        .login-page {
          max-width: 400px;
          margin: 50px auto;
          padding: 20px;
        }
        .form-group {
          margin-bottom: 15px;
        }
        label {
          display: block;
          margin-bottom: 5px;
          font-weight: 500;
        }
        input {
          width: 100%;
          padding: 10px;
          border: 1px solid #ccc;
          border-radius: 4px;
        }
        button {
          width: 100%;
          padding: 12px;
          background: #0070f3;
          color: white;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-size: 16px;
        }
        button:disabled {
          background: #ccc;
          cursor: not-allowed;
        }
        .sso-button {
          background: #24292e;
        }
        .divider {
          text-align: center;
          margin: 20px 0;
          color: #666;
        }
        .error-message {
          background: #fee;
          color: #c00;
          padding: 10px;
          border-radius: 4px;
          margin-bottom: 15px;
        }
      `}</style>
    </div>
  );
};

// Protected Route Component
export const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingSpinner />;
  }

  if (!user) {
    return <LoginPage />;
  }

  return <>{children}</>;
};

// Dashboard Component (example protected page)
export const Dashboard: React.FC = () => {
  const { user, signOut } = useAuth();
  const [profile, setProfile] = useState<any>(null);

  useEffect(() => {
    if (user) {
      // Load user profile from database
      loadProfile();
    }
  }, [user]);

  const loadProfile = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user?.id)
        .single();

      if (error) throw error;
      setProfile(data);
    } catch (error) {
      console.error('Error loading profile:', error);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <div className="dashboard">
      <header>
        <h1>Dashboard</h1>
        <button onClick={handleSignOut}>Sign Out</button>
      </header>

      <main>
        <div className="user-info">
          <h2>Welcome, {user?.user_metadata?.name || user?.email}!</h2>
          
          <div className="info-grid">
            <div className="info-item">
              <strong>Email:</strong>
              <span>{user?.email}</span>
            </div>
            
            <div className="info-item">
              <strong>User ID:</strong>
              <span>{user?.id}</span>
            </div>
            
            <div className="info-item">
              <strong>Provider:</strong>
              <span>SAML SSO</span>
            </div>

            {user?.user_metadata?.first_name && (
              <div className="info-item">
                <strong>First Name:</strong>
                <span>{user.user_metadata.first_name}</span>
              </div>
            )}

            {user?.user_metadata?.last_name && (
              <div className="info-item">
                <strong>Last Name:</strong>
                <span>{user.user_metadata.last_name}</span>
              </div>
            )}
          </div>
        </div>

        {profile && (
          <div className="profile-data">
            <h3>Profile Data</h3>
            <pre>{JSON.stringify(profile, null, 2)}</pre>
          </div>
        )}
      </main>

      <style jsx>{`
        .dashboard {
          max-width: 1200px;
          margin: 0 auto;
          padding: 20px;
        }
        header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 30px;
        }
        .user-info {
          background: white;
          padding: 20px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin-bottom: 20px;
        }
        .info-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 15px;
          margin-top: 20px;
        }
        .info-item {
          display: flex;
          flex-direction: column;
          gap: 5px;
        }
        .info-item strong {
          color: #666;
          font-size: 14px;
        }
        .info-item span {
          font-size: 16px;
        }
        .profile-data {
          background: #f5f5f5;
          padding: 20px;
          border-radius: 8px;
        }
        pre {
          overflow-x: auto;
        }
      `}</style>
    </div>
  );
};

// Loading Spinner Component
const LoadingSpinner: React.FC = () => (
  <div className="loading-spinner">
    <div className="spinner"></div>
    <p>Loading...</p>
    
    <style jsx>{`
      .loading-spinner {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
      }
      .spinner {
        width: 50px;
        height: 50px;
        border: 4px solid #f3f3f3;
        border-top: 4px solid #0070f3;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    `}</style>
  </div>
);

// ===== Main App =====

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <ProtectedRoute>
        <Dashboard />
      </ProtectedRoute>
    </AuthProvider>
  );
};

export default App;

// ===== Usage Example =====

/*
// index.tsx or App.tsx

import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './react-saml-auth';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// .env file:
// REACT_APP_SUPABASE_URL=http://localhost:8000
// REACT_APP_SUPABASE_ANON_KEY=your-anon-key

// package.json:
{
  "dependencies": {
    "@supabase/supabase-js": "^2.38.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
*/
