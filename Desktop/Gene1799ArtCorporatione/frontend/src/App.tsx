import React from 'react';
import './App.css';

interface AppProps {}

const App: React.FC<AppProps> = () => {
  const [status, setStatus] = React.useState<string>('Caricamento...');

  React.useEffect(() => {
    // Prova a connettersi al backend
    fetchStatus();
  }, []);

  const fetchStatus = async () => {
    try {
      const response = await fetch('http://localhost:3000/api/health');
      const data = await response.json();
      setStatus(data.status);
    } catch (error) {
      setStatus('Errore di connessione');
      console.error('Errore:', error);
    }
  };

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>🎨 Gene1799 Art Corporation</h1>
        <p>Sistema Integrato AI</p>
      </header>

      <main className="app-main">
        <section className="status-section">
          <h2>Status Backend</h2>
          <p>API Status: <strong>{status}</strong></p>
          <button onClick={fetchStatus}>Aggiorna</button>
        </section>

        <section className="info-section">
          <h2>Componenti</h2>
          <ul>
            <li>✅ Frontend Web (React)</li>
            <li>✅ Backend API (Express.js)</li>
            <li>✅ AI Agent (Python)</li>
            <li>✅ Desktop App (Electron)</li>
          </ul>
        </section>
      </main>

      <footer className="app-footer">
        <p>&copy; 2026 Gene1799. Tutti i diritti riservati.</p>
      </footer>
    </div>
  );
};

export default App;
