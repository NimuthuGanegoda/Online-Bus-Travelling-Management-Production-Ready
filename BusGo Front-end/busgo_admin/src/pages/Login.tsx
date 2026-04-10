import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, ArrowRight } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './Login.css';

export default function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username.trim(), password);
      navigate('/admin/dashboard');
    } catch (err: any) {
      setError(err?.response?.data?.message ?? 'Invalid email or password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      {/* Left Side - Logo Section */}
      <div className="login-left">
        <div className="login-logo-section">
          {/* Orbital rings */}
          <div className="orbital-container">
            <div className="orbital-ring orbital-ring-1"></div>
            <div className="orbital-ring orbital-ring-2"></div>
            <div className="orbital-ring orbital-ring-3"></div>
            <div className="orbital-dot orbital-dot-1"></div>
            <div className="orbital-dot orbital-dot-2"></div>
            <div className="orbital-dot orbital-dot-3"></div>
          </div>

          {/* Rotating Logo */}
          <div className="logo-wrapper">
            <div className="logo-glow"></div>
            <img
              src="/busgo-logo.jpeg"
              alt="BUSGO Logo"
              className="logo-image rotating"
            />
          </div>

          {/* Brand Text */}
          <div className="brand-text">
            <h1 className="brand-name">A X I S</h1>
            <div className="brand-dot"></div>
            <p className="brand-tagline">A D M I N &nbsp; U S E</p>
          </div>
        </div>

        {/* Footer */}
        <div className="login-copyright">
          &copy; 2025 BUSGO AXIS. All rights reserved.
        </div>
      </div>

      {/* Right Side - Sign In Form */}
      <div className="login-right">
        <div className="login-card-wrapper">
          {/* Neon traveling border */}
          <div className="neon-border">
            <div className="neon-light"></div>
          </div>

          <div className="login-card">
            {/* Card Header */}
            <div className="card-header">
              <div className="card-logo">
                <img src="/busgo-logo.jpeg" alt="" className="card-logo-img" />
                <span className="card-logo-text">BUSGO AXIS</span>
              </div>
              <h2 className="card-title">Sign In</h2>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="login-form">
              <div className="form-group">
                <label className="form-label">USERNAME</label>
                <div className="neon-input-wrapper">
                  <div className="neon-input-border">
                    <div className="neon-input-light"></div>
                  </div>
                  <div className="input-inner">
                    <Mail size={18} className="input-icon" />
                    <input
                      type="text"
                      placeholder="admin@busgo.lk"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      className="form-input"
                    />
                  </div>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">PASSWORD</label>
                <div className="neon-input-wrapper">
                  <div className="neon-input-border">
                    <div className="neon-input-light"></div>
                  </div>
                  <div className="input-inner">
                    <Lock size={18} className="input-icon" />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Enter password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="form-input"
                    />
                    <button
                      type="button"
                      className="password-toggle"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>
              </div>

              <div className="form-options">
                <label className="remember-me">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <span className="checkmark"></span>
                  <span>Remember me</span>
                </label>
                <a href="#" className="forgot-link">Forgot password?</a>
              </div>

              {error && (
                <div style={{ color: '#ef4444', fontSize: '13px', marginBottom: '8px', textAlign: 'center' }}>
                  {error}
                </div>
              )}

              <button type="submit" className="signin-btn" disabled={loading}>
                <span>{loading ? 'Signing in…' : 'Sign In'}</span>
                <ArrowRight size={20} />
              </button>
            </form>

            {/* Secured badge */}
            <div className="secured-badge">
              <span className="secured-dot"></span>
              <span>SECURED &middot; ENTERPRISE GRADE</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
