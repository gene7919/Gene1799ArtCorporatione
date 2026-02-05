const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const http = require('http');
const socketIo = require('socket.io');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const { v4: uuidv4 } = require('uuid');
const _ = require('lodash');
const moment = require('moment');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: '*' } });

const PORT = process.env.PORT || 3000;
const VERSION = '9.0.0';

// ========================================
// SECURITY MIDDLEWARE
// ========================================
app.set('trust proxy', 1);

app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
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

const TARGET_RANGES = ['74.220.48.0/24', '74.220.56.0/24'];

// ========================================
// RATE LIMITING (FIXED)
// ========================================
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests' },
  skip: (req) => {
    const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').split(',')[0];
    return TARGET_RANGES.some(r => isIPInRange(ip, r));
  }
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  message: { error: 'API rate limit exceeded' }
});

const createLimiter = rateLimit({
  windowMs: 3600 * 1000,
  max: 100,
  message: { error: 'Creation limit exceeded' }
});

// FIXED: express-slow-down v2.0.3
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 100,
  delayMs: (used, req) => {
    const delayAfter = req.slowDown.limit;
    return (used - delayAfter) * 500;
  },
  maxDelayMs: 20000
});

app.use(globalLimiter);
app.use(speedLimiter);

// ========================================
// IP LOGGING
// ========================================
app.use((req, res, next) => {
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').split(',')[0].trim();
  const inTarget = TARGET_RANGES.some(r => isIPInRange(ip, r));
  const cfRay = req.headers['cf-ray'];
  const cfCountry = req.headers['cf-ipcountry'];

  const icon = inTarget ? '🎯' : (cfRay ? '☁️' : '📍');
  const cfInfo = cfRay ? ` | CF: ${cfRay} | ${cfCountry}` : '';

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
    this.workflows = [];
    this.metrics = {
      requests: 0,
      errors: 0,
      activeConnections: 0,
      targetIPHits: 0,
      tasksExecuted: 0,
      nftsCreated: 0,
      workflowsCompleted: 0,
      startTime: Date.now()
    };
    this.initAgents();
  }

  initAgents() {
    const categories = ['VIDEO', 'ART', 'TRADING', 'MUSIC', 'LEARNING'];
    const capabilities = {
      VIDEO: ['video_generation', 'editing', 'effects'],
      ART: ['image_generation', 'nft_creation', '3d_modeling'],
      TRADING: ['crypto_analysis', 'portfolio', 'alerts'],
      MUSIC: ['music_generation', 'mixing', 'mastering'],
      LEARNING: ['training', 'optimization', 'research']
    };

    for (let i = 0; i < 500; i++) {
      const category = categories[i % 5];
      this.agents.set(`GAC_${i.toString().padStart(4, '0')}`, {
        id: `GAC_${i.toString().padStart(4, '0')}`,
        name: `${category}_AGENT_${i}`,
        category,
        status: Math.random() > 0.9 ? 'training' : 'active',
        efficiency: parseFloat((85 + Math.random() * 15).toFixed(1)),
        gpu: Math.random() > 0.6,
        capabilities: capabilities[category],
        stats: {
          tasksCompleted: Math.floor(Math.random() * 1000),
          successRate: parseFloat((90 + Math.random() * 10).toFixed(2)),
          avgResponseTime: Math.floor(Math.random() * 3000),
          nftsCreated: category === 'ART' ? Math.floor(Math.random() * 50) : 0
        },
        created: moment().subtract(Math.floor(Math.random() * 90), 'days').toISOString(),
        lastActive: moment().subtract(Math.floor(Math.random() * 24), 'hours').toISOString()
      });
    }
    console.log(`✅ Initialized ${this.agents.size} agents`);
  }

  getMetrics() {
    return {
      ...this.metrics,
      uptime: Math.floor((Date.now() - this.metrics.startTime) / 1000),
      agents: this.agents.size,
      nfts: this.nfts.size,
      memory: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      avgEfficiency: _.meanBy(Array.from(this.agents.values()), 'efficiency').toFixed(2)
    };
  }
}

const db = new Database();

app.use((req, res, next) => {
  db.metrics.requests++;
  next();
});

// ========================================
// BATCH OPERATIONS
// ========================================
class BatchOperations {
  static async createAgentsBatch(count, template = {}) {
    const agents = [];
    for (let i = 0; i < count; i++) {
      const agent = {
        id: `AGT_${uuidv4()}`,
        name: template.name || `BatchAgent_${Date.now()}_${i}`,
        category: template.category || 'GENERAL',
        status: 'active',
        efficiency: 85,
        stats: { tasksCompleted: 0, successRate: 100, avgResponseTime: 1000 },
        created: new Date().toISOString()
      };
      db.agents.set(agent.id, agent);
      agents.push(agent);

      if ((i + 1) % 10 === 0) {
        io.emit('batch-progress', {
          type: 'agents',
          progress: Math.round(((i + 1) / count) * 100),
          created: i + 1,
          total: count
        });
      }
    }
    return agents;
  }

  static async createNFTsBatch(count, template = {}) {
    const nfts = [];
    for (let i = 0; i < count; i++) {
      const nft = {
        id: `NFT_${uuidv4()}`,
        name: template.name || `BatchNFT_${Date.now()}_${i}`,
        description: template.description || 'Batch created NFT',
        imageUrl: `/generated/batch_${i}.png`,
        tokenId: Math.floor(Math.random() * 1000000),
        blockchain: template.blockchain || 'Ethereum',
        marketplace: template.marketplace || 'custom',
        price: template.price || parseFloat((0.1 + Math.random() * 2).toFixed(2)),
        status: 'minted',
        created: new Date().toISOString()
      };
      db.nfts.set(nft.id, nft);
      nfts.push(nft);
      db.metrics.nftsCreated++;
    }
    return nfts;
  }
}

// ========================================
// API ROUTES
// ========================================
app.get('/', (req, res) => {
  res.json({
    name: 'GENE1799 ART CORPORATIONE v9.0',
    domain: 'gene1799artcorporatione.mom',
    status: 'PRODUCTION',
    version: VERSION,
    features: [
      'DDoS Protection (Cloudflare + Express)',
      'Rate Limiting Multi-Layer',
      'IP Whitelisting (74.220.48/56.0/24)',
      '500 AI Agents',
      'Batch Operations (Agents/NFTs)',
      'WebSocket Real-time',
      'NFT Management',
      'Advanced Analytics'
    ],
    endpoints: {
      health: '/api/health',
      agents: '/api/agents',
      agentsBatch: '/api/agents/batch-create',
      nfts: '/api/nft',
      nftsBatch: '/api/nft/batch-create',
      metrics: '/api/metrics',
      ipStats: '/api/ip-stats',
      security: '/api/security-status'
    }
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    version: VERSION,
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
        global: '1000 req/15min',
        api: '300 req/min',
        create: '100 req/hour'
      },
      ipWhitelist: TARGET_RANGES
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
  let agents = Array.from(db.agents.values());
  if (req.query.category) agents = agents.filter(a => a.category === req.query.category.toUpperCase());
  const start = (page - 1) * limit;
  res.json({
    success: true,
    total: agents.length,
    page,
    limit,
    agents: agents.slice(start, start + limit)
  });
});

app.post('/api/agents/create', createLimiter, (req, res) => {
  const agent = {
    id: `AGT_${uuidv4()}`,
    name: req.body.name || `Agent_${Date.now()}`,
    category: req.body.category || 'GENERAL',
    status: 'active',
    efficiency: 85,
    stats: { tasksCompleted: 0, successRate: 100, avgResponseTime: 1000 },
    created: new Date().toISOString()
  };
  db.agents.set(agent.id, agent);
  io.emit('agent-created', agent);
  res.json({ success: true, agent });
});

app.post('/api/agents/batch-create', createLimiter, async (req, res) => {
  try {
    const count = Math.min(req.body.count || 10, 100);
    const agents = await BatchOperations.createAgentsBatch(count, req.body.template || {});
    res.json({
      success: true,
      created: agents.length,
      agents: agents.slice(0, 10),
      message: `${agents.length} agents created successfully`
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/nft', (req, res) => {
  const nfts = Array.from(db.nfts.values());
  res.json({ success: true, total: nfts.length, nfts });
});

app.post('/api/nft/create', createLimiter, (req, res) => {
  const nft = {
    id: `NFT_${uuidv4()}`,
    name: req.body.name || `NFT_${Date.now()}`,
    description: req.body.description || 'AI Generated NFT',
    imageUrl: req.body.imageUrl || '/generated/placeholder.png',
    tokenId: Math.floor(Math.random() * 1000000),
    blockchain: req.body.blockchain || 'Ethereum',
    marketplace: req.body.marketplace || 'custom',
    price: req.body.price || 0.1,
    status: 'minted',
    created: new Date().toISOString()
  };
  db.nfts.set(nft.id, nft);
  db.metrics.nftsCreated++;
  io.emit('nft-created', nft);
  res.json({ success: true, nft });
});

app.post('/api/nft/batch-create', createLimiter, async (req, res) => {
  try {
    const count = Math.min(req.body.count || 5, 50);
    const nfts = await BatchOperations.createNFTsBatch(count, req.body.template || {});
    res.json({
      success: true,
      created: nfts.length,
      nfts: nfts.slice(0, 10),
      message: `${nfts.length} NFTs created successfully`
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// WEBSOCKET
// ========================================
io.on('connection', (socket) => {
  db.metrics.activeConnections++;
  console.log(`✅ WebSocket: ${socket.id} (Total: ${db.metrics.activeConnections})`);

  socket.emit('welcome', { version: VERSION, agents: db.agents.size });

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
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing...');
  server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
  console.log('SIGINT received, closing...');
  server.close(() => process.exit(0));
});

// ========================================
// START SERVER
// ========================================
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  GENE1799 ART CORPORATIONE v9.0 - PRODUCTION    ║');
  console.log('╚══════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server:      http://0.0.0.0:${PORT}`);
  console.log(`🤖 Agents:      ${db.agents.size} loaded`);
  console.log(`🛡️  Protection:  DDoS + Rate Limit + Firewall`);
  console.log(`🌐 WebSocket:   ENABLED`);
  console.log(`🎯 Whitelist:   74.220.48.0/24, 74.220.56.0/24\n`);
});
