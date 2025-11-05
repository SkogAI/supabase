"use strict";
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
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.App = exports.Dashboard = exports.ProtectedRoute = exports.LoginPage = exports.useAuth = exports.AuthProvider = void 0;
var react_1 = require("react");
var supabase_js_1 = require("@supabase/supabase-js");
// Configuration
var SUPABASE_URL = process.env.REACT_APP_SUPABASE_URL || 'http://localhost:8000';
var SUPABASE_ANON_KEY = process.env.REACT_APP_SUPABASE_ANON_KEY || 'your-anon-key';
// Create Supabase client
var supabase = (0, supabase_js_1.createClient)(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
    }
});
// ===== Auth Context =====
var AuthContext = (0, react_1.createContext)(undefined);
var AuthProvider = function (_a) {
    var children = _a.children;
    var _b = (0, react_1.useState)(null), user = _b[0], setUser = _b[1];
    var _c = (0, react_1.useState)(null), session = _c[0], setSession = _c[1];
    var _d = (0, react_1.useState)(true), loading = _d[0], setLoading = _d[1];
    (0, react_1.useEffect)(function () {
        // Get initial session
        supabase.auth.getSession().then(function (_a) {
            var _b;
            var session = _a.data.session;
            setSession(session);
            setUser((_b = session === null || session === void 0 ? void 0 : session.user) !== null && _b !== void 0 ? _b : null);
            setLoading(false);
        });
        // Listen for auth changes
        var subscription = supabase.auth.onAuthStateChange(function (_event, session) {
            var _a;
            setSession(session);
            setUser((_a = session === null || session === void 0 ? void 0 : session.user) !== null && _a !== void 0 ? _a : null);
            setLoading(false);
        }).data.subscription;
        return function () { return subscription.unsubscribe(); };
    }, []);
    var signInWithSSO = function (domain) { return __awaiter(void 0, void 0, void 0, function () {
        return __generator(this, function (_a) {
            try {
                setLoading(true);
                // Redirect to SAML SSO
                window.location.href = "".concat(SUPABASE_URL, "/auth/v1/sso?domain=").concat(domain);
            }
            catch (error) {
                console.error('Error signing in with SSO:', error);
                setLoading(false);
                throw error;
            }
            return [2 /*return*/];
        });
    }); };
    var signOut = function () { return __awaiter(void 0, void 0, void 0, function () {
        var error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, 3, 4]);
                    setLoading(true);
                    return [4 /*yield*/, supabase.auth.signOut()];
                case 1:
                    _a.sent();
                    return [3 /*break*/, 4];
                case 2:
                    error_1 = _a.sent();
                    console.error('Error signing out:', error_1);
                    throw error_1;
                case 3:
                    setLoading(false);
                    return [7 /*endfinally*/];
                case 4: return [2 /*return*/];
            }
        });
    }); };
    var value = {
        user: user,
        session: session,
        loading: loading,
        signInWithSSO: signInWithSSO,
        signOut: signOut,
    };
    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
exports.AuthProvider = AuthProvider;
var useAuth = function () {
    var context = (0, react_1.useContext)(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
exports.useAuth = useAuth;
// ===== Components =====
// Login Component
var LoginPage = function () {
    var _a = (0, exports.useAuth)(), signInWithSSO = _a.signInWithSSO, loading = _a.loading;
    var _b = (0, react_1.useState)(''), email = _b[0], setEmail = _b[1];
    var _c = (0, react_1.useState)(null), error = _c[0], setError = _c[1];
    var handleEmailSubmit = function (e) { return __awaiter(void 0, void 0, void 0, function () {
        var domain, err_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    e.preventDefault();
                    setError(null);
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 3, , 4]);
                    domain = email.split('@')[1];
                    if (!domain) {
                        setError('Please enter a valid email address');
                        return [2 /*return*/];
                    }
                    return [4 /*yield*/, signInWithSSO(domain)];
                case 2:
                    _a.sent();
                    return [3 /*break*/, 4];
                case 3:
                    err_1 = _a.sent();
                    setError('Failed to initiate SSO login. Please try again.');
                    console.error(err_1);
                    return [3 /*break*/, 4];
                case 4: return [2 /*return*/];
            }
        });
    }); };
    var handleDirectSSO = function () { return __awaiter(void 0, void 0, void 0, function () {
        var err_2;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, signInWithSSO('yourcompany.com')];
                case 1:
                    _a.sent(); // Replace with your domain
                    return [3 /*break*/, 3];
                case 2:
                    err_2 = _a.sent();
                    setError('Failed to initiate SSO login. Please try again.');
                    console.error(err_2);
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    }); };
    return (<div className="login-page">
      <h1>Sign In</h1>

      {error && (<div className="error-message" role="alert">
          {error}
        </div>)}

      {/* Method 1: Email-based SSO detection */}
      <form onSubmit={handleEmailSubmit}>
        <div className="form-group">
          <label htmlFor="email">Email Address</label>
          <input id="email" type="email" value={email} onChange={function (e) { return setEmail(e.target.value); }} placeholder="user@yourcompany.com" required disabled={loading}/>
        </div>
        <button type="submit" disabled={loading}>
          {loading ? 'Signing in...' : 'Continue with SSO'}
        </button>
      </form>

      <div className="divider">OR</div>

      {/* Method 2: Direct SSO button */}
      <button onClick={handleDirectSSO} disabled={loading} className="sso-button">
        Sign in with Company SSO
      </button>

      <style jsx>{"\n        .login-page {\n          max-width: 400px;\n          margin: 50px auto;\n          padding: 20px;\n        }\n        .form-group {\n          margin-bottom: 15px;\n        }\n        label {\n          display: block;\n          margin-bottom: 5px;\n          font-weight: 500;\n        }\n        input {\n          width: 100%;\n          padding: 10px;\n          border: 1px solid #ccc;\n          border-radius: 4px;\n        }\n        button {\n          width: 100%;\n          padding: 12px;\n          background: #0070f3;\n          color: white;\n          border: none;\n          border-radius: 4px;\n          cursor: pointer;\n          font-size: 16px;\n        }\n        button:disabled {\n          background: #ccc;\n          cursor: not-allowed;\n        }\n        .sso-button {\n          background: #24292e;\n        }\n        .divider {\n          text-align: center;\n          margin: 20px 0;\n          color: #666;\n        }\n        .error-message {\n          background: #fee;\n          color: #c00;\n          padding: 10px;\n          border-radius: 4px;\n          margin-bottom: 15px;\n        }\n      "}</style>
    </div>);
};
exports.LoginPage = LoginPage;
// Protected Route Component
var ProtectedRoute = function (_a) {
    var children = _a.children;
    var _b = (0, exports.useAuth)(), user = _b.user, loading = _b.loading;
    if (loading) {
        return <LoadingSpinner />;
    }
    if (!user) {
        return <exports.LoginPage />;
    }
    return <>{children}</>;
};
exports.ProtectedRoute = ProtectedRoute;
// Dashboard Component (example protected page)
var Dashboard = function () {
    var _a, _b, _c;
    var _d = (0, exports.useAuth)(), user = _d.user, signOut = _d.signOut;
    var _e = (0, react_1.useState)(null), profile = _e[0], setProfile = _e[1];
    (0, react_1.useEffect)(function () {
        if (user) {
            // Load user profile from database
            loadProfile();
        }
    }, [user]);
    var loadProfile = function () { return __awaiter(void 0, void 0, void 0, function () {
        var _a, data, error, error_2;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _b.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, supabase
                            .from('profiles')
                            .select('*')
                            .eq('id', user === null || user === void 0 ? void 0 : user.id)
                            .single()];
                case 1:
                    _a = _b.sent(), data = _a.data, error = _a.error;
                    if (error)
                        throw error;
                    setProfile(data);
                    return [3 /*break*/, 3];
                case 2:
                    error_2 = _b.sent();
                    console.error('Error loading profile:', error_2);
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    }); };
    var handleSignOut = function () { return __awaiter(void 0, void 0, void 0, function () {
        var error_3;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 2, , 3]);
                    return [4 /*yield*/, signOut()];
                case 1:
                    _a.sent();
                    return [3 /*break*/, 3];
                case 2:
                    error_3 = _a.sent();
                    console.error('Error signing out:', error_3);
                    return [3 /*break*/, 3];
                case 3: return [2 /*return*/];
            }
        });
    }); };
    return (<div className="dashboard">
      <header>
        <h1>Dashboard</h1>
        <button onClick={handleSignOut}>Sign Out</button>
      </header>

      <main>
        <div className="user-info">
          <h2>Welcome, {((_a = user === null || user === void 0 ? void 0 : user.user_metadata) === null || _a === void 0 ? void 0 : _a.name) || (user === null || user === void 0 ? void 0 : user.email)}!</h2>
          
          <div className="info-grid">
            <div className="info-item">
              <strong>Email:</strong>
              <span>{user === null || user === void 0 ? void 0 : user.email}</span>
            </div>
            
            <div className="info-item">
              <strong>User ID:</strong>
              <span>{user === null || user === void 0 ? void 0 : user.id}</span>
            </div>
            
            <div className="info-item">
              <strong>Provider:</strong>
              <span>SAML SSO</span>
            </div>

            {((_b = user === null || user === void 0 ? void 0 : user.user_metadata) === null || _b === void 0 ? void 0 : _b.first_name) && (<div className="info-item">
                <strong>First Name:</strong>
                <span>{user.user_metadata.first_name}</span>
              </div>)}

            {((_c = user === null || user === void 0 ? void 0 : user.user_metadata) === null || _c === void 0 ? void 0 : _c.last_name) && (<div className="info-item">
                <strong>Last Name:</strong>
                <span>{user.user_metadata.last_name}</span>
              </div>)}
          </div>
        </div>

        {profile && (<div className="profile-data">
            <h3>Profile Data</h3>
            <pre>{JSON.stringify(profile, null, 2)}</pre>
          </div>)}
      </main>

      <style jsx>{"\n        .dashboard {\n          max-width: 1200px;\n          margin: 0 auto;\n          padding: 20px;\n        }\n        header {\n          display: flex;\n          justify-content: space-between;\n          align-items: center;\n          margin-bottom: 30px;\n        }\n        .user-info {\n          background: white;\n          padding: 20px;\n          border-radius: 8px;\n          box-shadow: 0 2px 4px rgba(0,0,0,0.1);\n          margin-bottom: 20px;\n        }\n        .info-grid {\n          display: grid;\n          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));\n          gap: 15px;\n          margin-top: 20px;\n        }\n        .info-item {\n          display: flex;\n          flex-direction: column;\n          gap: 5px;\n        }\n        .info-item strong {\n          color: #666;\n          font-size: 14px;\n        }\n        .info-item span {\n          font-size: 16px;\n        }\n        .profile-data {\n          background: #f5f5f5;\n          padding: 20px;\n          border-radius: 8px;\n        }\n        pre {\n          overflow-x: auto;\n        }\n      "}</style>
    </div>);
};
exports.Dashboard = Dashboard;
// Loading Spinner Component
var LoadingSpinner = function () { return (<div className="loading-spinner">
    <div className="spinner"></div>
    <p>Loading...</p>
    
    <style jsx>{"\n      .loading-spinner {\n        display: flex;\n        flex-direction: column;\n        align-items: center;\n        justify-content: center;\n        min-height: 100vh;\n      }\n      .spinner {\n        width: 50px;\n        height: 50px;\n        border: 4px solid #f3f3f3;\n        border-top: 4px solid #0070f3;\n        border-radius: 50%;\n        animation: spin 1s linear infinite;\n      }\n      @keyframes spin {\n        0% { transform: rotate(0deg); }\n        100% { transform: rotate(360deg); }\n      }\n    "}</style>
  </div>); };
// ===== Main App =====
var App = function () {
    return (<exports.AuthProvider>
      <exports.ProtectedRoute>
        <exports.Dashboard />
      </exports.ProtectedRoute>
    </exports.AuthProvider>);
};
exports.App = App;
exports.default = exports.App;
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
