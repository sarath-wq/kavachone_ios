import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  componentDidCatch(error, errorInfo) {
    console.error("Uncaught React Error:", error, errorInfo);
    this.setState({ errorInfo });
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: '24px 16px', textAlign: 'center', backgroundColor: '#f8fafc', color: '#0f172a', minHeight: '100vh', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', boxSizing: 'border-box' }}>
          <div style={{ fontSize: '3rem', marginBottom: '12px' }}>⚠️</div>
          <h2 style={{ fontSize: '1.2rem', margin: '0 0 8px 0', color: '#0f172a' }}>KavachOne Session Error</h2>
          <p style={{ color: '#64748b', fontSize: '0.8rem', margin: '0 0 16px 0', maxWidth: '320px' }}>
            An unexpected error occurred. Tap below to refresh your session.
          </p>
          <div style={{ backgroundColor: '#fef2f2', border: '1px solid #fca5a5', padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', maxWidth: '400px', width: '100%', wordBreak: 'break-word', fontSize: '0.72rem', color: '#dc2626', textAlign: 'left', maxHeight: '200px', overflowY: 'auto', fontFamily: 'monospace' }}>
            {this.state.error?.stack || this.state.error?.toString()}
          </div>
          <button
            onClick={async () => {
              try {
                localStorage.clear();
                sessionStorage.clear();
                if ('caches' in window) {
                  const keys = await caches.keys();
                  await Promise.all(keys.map(key => caches.delete(key)));
                }
                if ('serviceWorker' in navigator) {
                  const registrations = await navigator.serviceWorker.getRegistrations();
                  for (let registration of registrations) {
                    await registration.unregister();
                  }
                }
              } catch (e) {}
              window.location.reload();
            }}
            style={{ padding: '12px 24px', borderRadius: '10px', backgroundColor: '#008ca8', color: '#ffffff', border: 'none', fontWeight: 'bold', fontSize: '0.85rem', cursor: 'pointer', boxShadow: '0 4px 12px rgba(0,140,168,0.3)' }}
          >
            Clear Cache & Reload
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
);
