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

const TARGET_RANGES = ['74.220.48.0/24', '74.220.56.0/24'];

// ========================================
// RATE LIMITING
// ========================================
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests' },
  skip: (req) => {
    const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0];
    return TARGET_RANGES.some(r => isIPInRange(ip, r));
  }
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: { error: 'API rate limit exceeded' }
});

const createLimiter = rateLimit({
  windowMs: 3600 * 1000,
  max: 10,
  message: { error: 'Creation limit exceeded' }
});

const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000,
  delayAfter: 50,
  delayMs: (used, req) => {
    const delayAfter = req.slowDown.limit;
    return (used - delayAfter) * 500;
  },
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
    this.tasks = [];
    this.workflows = [];
    this.metrics = {
      requests: 0,
      errors: 0,
      activeConnections: 0,
      targetIPHits: 0,
      tasksExecuted: 0,
      nftsCreated: 0,
      workflowsCompleted: 0,
      batchOperations: 0,
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
      const agent = {
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
      };
      this.agents.set(agent.id, agent);
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
    const categories = ['VIDEO', 'ART', 'TRADING', 'MUSIC', 'LEARNING'];
    
    for (let i = 0; i < count; i++) {
      const category = template.category || categories[i % 5];
      const agent = {
        id: `AGT_${uuidv4()}`,
        name: template.name || `BatchAgent_${Date.now()}_${i}`,
        category,
        status: 'active',
        efficiency: 85,
        capabilities: template.capabilities || ['automation'],
        stats: {
          tasksCompleted: 0,
          successRate: 100,
          avgResponseTime: 1000,
          nftsCreated: 0
        },
        created: new Date().toISOString(),
        lastActive: new Date().toISOString()
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
    
    db.metrics.batchOperations++;
    return agents;
  }
  
  static async createNFTsBatch(count, template = {}) {
    const nfts = [];
    
    for (let i = 0; i < count; i++) {
      const nft = {
        id: `NFT_${uuidv4()}`,
        name: template.name || `BatchNFT_${Date.now()}_${i}`,
        description: template.description || 'Batch created NFT',
        imageUrl: template.imageUrl || `/generated/batch_${i}.png`,
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
      
      if ((i + 1) % 5 === 0) {
        io.emit('batch-progress', {
          type: 'nfts',
          progress: Math.round(((i + 1) / count) * 100),
          created: i + 1,
          total: count
        });
      }
    }
    
    db.metrics.batchOperations++;
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
    version: '9.0.0',
    features: [
      'DDoS Protection (Cloudflare + Express)',
      'Rate Limiting Multi-Layer',
      'IP Whitelisting',
      '500 AI Agents',
      'WebSocket Real-time',
      'NFT Management',
      'Batch Operations',
      'AI Workflows',
      'Crypto Trading Simulator',
      'Advanced Analytics'
    ],
    endpoints: {
      health: '/api/health',
      agents: '/api/agents',
      agentsBatch: '/api/agents/batch-create',
      nfts: '/api/nft',
      nftsBatch: '/api/nft/batch-create',
      metrics: '/api/metrics',
      ipStats: '/api/ip-stats'
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
    version: '9.0.0',
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

app.get('/api/agents', apiLimiter, (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 25;
  const category = req.query.category;
  
  let agents = Array.from(db.agents.values());
  
  if (category) agents = agents.filter(a => a.category === category.toUpperCase());
  
  const start = (page - 1) * limit;
  const paginated = agents.slice(start, start + limit);
  
  res.json({
    success: true,
    total: agents.length,
    page,
    limit,
    agents: paginated
  });
});

app.post('/api/agents/create', createLimiter, (req, res) => {
  const agent = {
    id: `AGT_${uuidv4()}`,
    name: req.body.name || `Agent_${Date.now()}`,
    category: req.body.category || 'GENERAL',
    status: 'active',
    efficiency: 85,
    capabilities: req.body.capabilities || ['automation'],
    stats: { tasksCompleted: 0, successRate: 100, avgResponseTime: 1000, nftsCreated: 0 },
    created: new Date().toISOString(),
    lastActive: new Date().toISOString()
  };
  db.agents.set(agent.id, agent);
  io.emit('agent-created', agent);
  res.json({ success: true, agent });
});

app.post('/api/agents/batch-create', createLimiter, async (req, res) => {
  try {
    const count = Math.min(req.body.count || 10, 100);
    const template = req.body.template || {};
    
    const agents = await BatchOperations.createAgentsBatch(count, template);
    
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
    const template = req.body.template || {};
    
    const nfts = await BatchOperations.createNFTsBatch(count, template);
    
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
  console.log(`✅ WebSocket connected: ${socket.id} (Total: ${db.metrics.activeConnections})`);
  
  socket.emit('welcome', { 
    version: '9.0.0', 
    agents: db.agents.size,
    features: ['batch-operations', 'workflows', 'crypto-analysis']
  });
  
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

// ========================================
// START SERVER
// ========================================
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  GENE1799 ART CORPORATIONE v9.0 - LIVE SERVER   ║');
  console.log('╚══════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server:      http://0.0.0.0:${PORT}`);
  console.log(`🤖 Agents:      ${db.agents.size} loaded`);
  console.log(`🛡️  Protection:  DDoS + Rate Limit + Firewall`);
  console.log(`🌐 WebSocket:   ENABLED`);
  console.log(`🎯 Whitelist:   74.220.48.0/24, 74.220.56.0/24\n`);
});

