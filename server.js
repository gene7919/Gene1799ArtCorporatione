const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const http = require('http');
const socketIo = require('socket.io');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: '*' } });

const PORT = process.env.PORT || 3000;

// ========================================
// SECURITY MIDDLEWARE
// ========================================
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"]
    }
  }
}));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// IP Range Checker
function isIPInRange(ip, range) {
  try {
    const cleanIP = ip.replace('::ffff:', '');
    const [rangeIP, mask] = range.split('/');
    const ipParts = cleanIP.split('.');
    const rangeParts = rangeIP.split('.');
    if (ipParts.length !== 4 || rangeParts.length !== 4) return false;
    const ipLong = ipParts.reduce((acc, o) => (acc << 8) + parseInt(o), 0) >>> 0;
    const rangeLong = rangeParts.reduce((acc, o) => (acc << 8) + parseInt(o), 0) >>> 0;
    const maskBits = -1 << (32 - parseInt(mask));
    return (ipLong & maskBits) === (rangeLong & maskBits);
  } catch (e) { return false; }
}

// Whitelist IP ranges
const TARGET_RANGES = ['74.220.48.0/24', '74.220.56.0/24'];

// ========================================
// RATE LIMITING
// ========================================
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later' },
  skip: (req) => {
    const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0];
    return TARGET_RANGES.some(r => isIPInRange(ip, r));
  }
});

const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: 60,
  message: { error: 'API rate limit exceeded' }
});

const createLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { error: 'Creation limit exceeded - max 10/hour' }
});

const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 50,
  delayMs: 500,
  maxDelayMs: 20000
});

app.use(globalLimiter);
app.use(speedLimiter);

// ========================================
// SECURITY HEADERS & IP LOGGING
// ========================================
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000');
  
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0].trim();
  const inTarget = TARGET_RANGES.some(r => isIPInRange(ip, r));
  const cfRay = req.headers['cf-ray'];
  const cfCountry = req.headers['cf-ipcountry'];
  
  const icon = inTarget ? '🎯' : (cfRay ? '☁️' : '📍');
  const cfInfo = cfRay ? ` | CF-Ray: ${cfRay} | Country: ${cfCountry}` : '';
  
  console.log(`${icon} ${req.method.padEnd(6)} ${req.path.padEnd(30)} | IP: ${ip}${cfInfo}`);
  
  if (inTarget) db.metrics.targetIPHits++;
  
  next();
});

// ========================================
// DATABASE
// ========================================
class Database {
  constructor() {
    this.agents = new Map();
    this.nfts = new Map();
    this.tasks = [];
    this.metrics = {
      requests: 0,
      errors: 0,
      activeConnections: 0,
      targetIPHits: 0,
      startTime: Date.now()
    };
    this.initAgents();
  }
  
  initAgents() {
    const categories = ['VIDEO', 'ART', 'TRADING', 'MUSIC', 'LEARNING'];
    for (let i = 0; i < 500; i++) {
      const agent = {
        id: `GAC_${i.toString().padStart(4, '0')}`,
        name: `${categories[i % 5]}_AGENT_${i}`,
        category: categories[i % 5],
        status: Math.random() > 0.9 ? 'training' : 'active',
        efficiency: (85 + Math.random() * 15).toFixed(1),
        gpu: Math.random() > 0.6,
        tasksCompleted: Math.floor(Math.random() * 1000),
        created: new Date().toISOString()
      };
      this.agents.set(agent.id, agent);
    }
  }
  
  getMetrics() {
    return {
      ...this.metrics,
      uptime: Math.floor((Date.now() - this.metrics.startTime) / 1000),
      agents: this.agents.size,
      nfts: this.nfts.size,
      memory: Math.round(process.memoryUsage().heapUsed / 1024 / 1024)
    };
  }
}

const db = new Database();

// ========================================
// MIDDLEWARE COUNTER
// ========================================
app.use((req, res, next) => {
  db.metrics.requests++;
  next();
});

// ========================================
// API ROUTES
// ========================================
app.get('/', (req, res) => {
  res.json({
    name: 'GENE1799 ART CORPORATIONE v8.0',
    domain: 'gene1799artcorporatione.mom',
    status: 'PRODUCTION',
    features: [
      'DDoS Protection (Cloudflare + Express)',
      'Rate Limiting Multi-Layer',
      'IP Whitelisting',
      '500 AI Agents',
      'WebSocket Real-time',
      'NFT Management'
    ],
    endpoints: {
      health: '/api/health',
      agents: '/api/agents',
      nfts: '/api/nft',
      metrics: '/api/metrics',
      ipStats: '/api/ip-stats',
      security: '/api/security-status'
    },
    protection: {
      cloudflare: 'Enabled',
      rateLimit: 'Active',
      ipWhitelist: TARGET_RANGES
    }
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    version: '8.0.0',
    timestamp: new Date().toISOString(),
    metrics: db.getMetrics()
  });
});

app.get('/api/metrics', apiLimiter, (req, res) => {
  res.json({ success: true, metrics: db.getMetrics() });
});

app.get('/api/ip-stats', (req, res) => {
  res.json({
    success: true,
    targetIPHits: db.metrics.targetIPHits,
    totalRequests: db.metrics.requests,
    targetRanges: TARGET_RANGES,
    percentage: ((db.metrics.targetIPHits / db.metrics.requests) * 100).toFixed(2)
  });
});

app.get('/api/security-status', (req, res) => {
  res.json({
    success: true,
    protection: {
      ddos: 'Cloudflare + Express Rate Limit',
      rateLimit: {
        global: '100 req/15min',
        api: '60 req/min',
        create: '10 req/hour'
      },
      ipWhitelist: TARGET_RANGES,
      headers: ['helmet', 'HSTS', 'CSP', 'X-Frame-Options']
    },
    cloudflare: {
      enabled: !!req.headers['cf-ray'],
      ray: req.headers['cf-ray'],
      country: req.headers['cf-ipcountry']
    }
  });
});

app.get('/api/agents', apiLimiter, (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 25;
  const agents = Array.from(db.agents.values());
  const start = (page - 1) * limit;
  res.json({
    success: true,
    total: agents.length,
    page,
    limit,
    agents: agents.slice(start, start + limit),
    stats: {
      active: agents.filter(a => a.status === 'active').length,
      gpuEnabled: agents.filter(a => a.gpu).length
    }
  });
});

app.post('/api/agents/create', createLimiter, (req, res) => {
  const agent = {
    id: `AGT_${Date.now()}`,
    name: req.body.name || `Agent_${Date.now()}`,
    status: 'active',
    created: new Date().toISOString()
  };
  db.agents.set(agent.id, agent);
  res.json({ success: true, agent });
});

// ========================================
// WEBSOCKET
// ========================================
io.on('connection', (socket) => {
  db.metrics.activeConnections++;
  console.log(`✅ WebSocket connected: ${socket.id} (Total: ${db.metrics.activeConnections})`);
  
  socket.emit('welcome', { version: '8.0.0', agents: db.agents.size });
  
  const interval = setInterval(() => {
    socket.emit('metrics-update', db.getMetrics());
  }, 5000);
  
  socket.on('disconnect', () => {
    db.metrics.activeConnections--;
    clearInterval(interval);
  });
});

// ========================================
// ERROR HANDLING
// ========================================
app.use((err, req, res, next) => {
  db.metrics.errors++;
  console.error('Error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing...');
  server.close(() => process.exit(0));
});

// ========================================
// START SERVER
// ========================================
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  GENE1799 ART CORPORATIONE v8.0 - LIVE SERVER   ║');
  console.log('╚══════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server:      http://0.0.0.0:${PORT}`);
  console.log(`🤖 Agents:      ${db.agents.size} loaded`);
  console.log(`🛡️  Protection:  DDoS + Rate Limit + Firewall`);
  console.log(`🌐 WebSocket:   ENABLED`);
  console.log(`🎯 Whitelist:   74.220.48.0/24, 74.220.56.0/24\n`);
});
