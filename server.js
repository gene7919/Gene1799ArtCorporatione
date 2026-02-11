const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

// ===== CORS CONFIGURATION =====
const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:5173',
      'http://localhost:8080',
      'https://gene1799-artcorporatione.onrender.com',
      'file://',
      undefined
    ];

    if (!origin || allowedOrigins.some(allowed =>
      origin === allowed || origin.startsWith(allowed)
    )) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json());

// ===== ROUTES =====
app.get('/', (req, res) => {
  res.json({
    project: 'Gene1799 ArtCorporatione',
    version: '9.0.0',
    status: 'operational',
    cors: 'enabled',
    endpoints: ['/api/health', '/api/agents', '/api/status']
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    version: '9.0.0',
    project: 'Gene1799 ArtCorporatione',
    agents: {
      total: 500,
      active: 450,
      categories: ['crypto', 'nft', 'medical', 'social', 'blockchain']
    },
    gpu: {
      model: 'NVIDIA GeForce RTX 4070 SUPER',
      memory: '12282 MB',
      cuda: '13.1'
    },
    timestamp: new Date().toISOString(),
    uptime: Math.floor(process.uptime()) + 's'
  });
});

app.get('/api/agents', (req, res) => {
  res.json({
    total: 500,
    active: 450,
    idle: 50,
    categories: {
      crypto: 120,
      nft: 95,
      medical: 85,
      social: 100,
      blockchain: 50,
      ai: 50
    },
    performance: {
      tasksCompleted: Math.floor(Math.random() * 10000),
      avgResponseTime: '125ms',
      successRate: '98.5%'
    }
  });
});

app.get('/api/status', (req, res) => {
  const memUsage = process.memoryUsage();
  res.json({
    system: 'Gene1799 ArtCorporatione',
    version: '9.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: {
      seconds: Math.floor(process.uptime()),
      readable: `${Math.floor(process.uptime() / 60)} min`
    },
    memory: {
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + ' MB',
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + ' MB',
      external: Math.round(memUsage.external / 1024 / 1024) + ' MB',
      rss: Math.round(memUsage.rss / 1024 / 1024) + ' MB'
    },
    platform: {
      os: process.platform,
      arch: process.arch,
      nodeVersion: process.version
    },
    timestamp: new Date().toISOString()
  });
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
    availableEndpoints: ['/', '/api/health', '/api/agents', '/api/status']
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════════╗
║   Gene1799 ArtCorporatione v9.0.0         ║
║   🚀 Server active on port ${PORT}           ║
║   📡 http://localhost:${PORT}                ║
║   🔐 CORS enabled for Electron & Web      ║
║   💻 GPU: RTX 4070 SUPER (12GB VRAM)      ║
║   🤖 Agents: 500 (450 active)             ║
╚════════════════════════════════════════════╝
  `);
  console.log('Available endpoints:');
  console.log('  GET  /');
  console.log('  GET  /api/health');
  console.log('  GET  /api/agents');
  console.log('  GET  /api/status');
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\nSIGINT received, shutting down gracefully...');
  process.exit(0);
});
