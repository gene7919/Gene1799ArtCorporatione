import React from 'react';
import './App.css';

const LOGO_URL = 'https://github.com/user-attachments/assets/94508ece-15be-44b0-a6eb-fcc306148814';
const LOGO_FILENAME = 'gene1799-logo.png';

interface AppProps {}

const App: React.FC<AppProps> = () => {
  const [status, setStatus] = React.useState<string>('Caricamento...');
  const [downloading, setDownloading] = React.useState<boolean>(false);

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

  const downloadLogo = async () => {
    setDownloading(true);
    try {
      const response = await fetch(LOGO_URL);
      const blob = await response.blob();
      const objectUrl = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = objectUrl;
      link.download = LOGO_FILENAME;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(objectUrl);
    } catch (error) {
      console.error('Errore durante il download:', error);
      window.open(LOGO_URL, '_blank');
    } finally {
      setDownloading(false);
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

        <section className="logo-section">
          <h2>Logo Gene1799</h2>
          <img
            src={LOGO_URL}
            alt="Gene1799 Art Corporation Logo"
            className="logo-preview"
          />
          <div className="download-container">
            <button onClick={downloadLogo} disabled={downloading} className="download-btn">
              {downloading ? '⏳ Download in corso...' : '⬇️ Scarica Immagine'}
            </button>
            <a href={LOGO_URL} download={LOGO_FILENAME} className="download-link">
              🔗 Link diretto download
            </a>
          </div>
        </section>
      </main>

      <footer className="app-footer">
        <p>&copy; 2026 Gene1799. Tutti i diritti riservati.</p>
      </footer>
    </div>
  );
};

export default App;
