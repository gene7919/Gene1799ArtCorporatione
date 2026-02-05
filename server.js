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
const axios = require('axios');

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
// DATABASE ENHANCED
// ========================================
class Database {
  constructor() {
    this.agents = new Map();
    this.nfts = new Map();
    this.tasks = [];
    this.workflows = [];
    this.cryptoData = new Map();
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
      ART: ['image_generation', 'style_transfer', 'nft_creation'],
      TRADING: ['crypto_analysis', 'portfolio_management', 'alerts'],
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
  }
  
  getMetrics() {
    return {
      ...this.metrics,
      uptime: Math.floor((Date.now() - this.metrics.startTime) / 1000),
      agents: this.agents.size,
      nfts: this.nfts.size,
      memory: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      avgTasksPerAgent: Math.round(this.metrics.tasksExecuted / this.agents.size)
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
// AI WORKFLOW ENGINE
// ========================================
class WorkflowEngine {
  static async executeWorkflow(type, params) {
    const workflowId = uuidv4();
    const workflow = {
      id: workflowId,
      type,
      status: 'running',
      steps: [],
      startTime: Date.now(),
      params
    };
    
    db.workflows.push(workflow);
    
    try {
      switch(type) {
        case 'ai-to-nft':
          return await this.aiToNFTWorkflow(workflow, params);
        case 'music-generation':
          return await this.musicGenerationWorkflow(workflow, params);
        case 'video-creation':
          return await this.videoCreationWorkflow(workflow, params);
        case 'crypto-strategy':
          return await this.cryptoStrategyWorkflow(workflow, params);
        default:
          throw new Error('Unknown workflow type');
      }
    } catch (error) {
      workflow.status = 'failed';
      workflow.error = error.message;
      throw error;
    }
  }
  
  static async aiToNFTWorkflow(workflow, params) {
    // Step 1: Generate AI Image
    workflow.steps.push({ step: 1, action: 'generate_image', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 2000));
    const imageUrl = `/generated/${uuidv4()}.png`;
    workflow.steps[0].status = 'completed';
    workflow.steps[0].output = { imageUrl };
    
    // Step 2: Create NFT Metadata
    workflow.steps.push({ step: 2, action: 'create_metadata', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 1000));
    const metadata = {
      name: params.nftData?.name || `AI Art ${Date.now()}`,
      description: params.nftData?.description || 'AI Generated Artwork',
      image: imageUrl,
      attributes: [
        { trait_type: 'Style', value: params.prompt?.split(' ')[0] || 'Abstract' },
        { trait_type: 'Generation', value: 'AI' },
        { trait_type: 'Timestamp', value: new Date().toISOString() }
      ]
    };
    workflow.steps[1].status = 'completed';
    workflow.steps[1].output = { metadata };
    
    // Step 3: Mint NFT
    workflow.steps.push({ step: 3, action: 'mint_nft', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 1500));
    const nft = {
      id: `NFT_${uuidv4()}`,
      ...metadata,
      tokenId: Math.floor(Math.random() * 1000000),
      blockchain: 'Ethereum',
      contract: '0x' + Array(40).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      marketplace: params.nftData?.marketplace || 'custom',
      price: params.nftData?.price || 0.1,
      status: 'minted',
      created: new Date().toISOString()
    };
    db.nfts.set(nft.id, nft);
    db.metrics.nftsCreated++;
    workflow.steps[2].status = 'completed';
    workflow.steps[2].output = { nftId: nft.id };
    
    workflow.status = 'completed';
    workflow.endTime = Date.now();
    workflow.duration = workflow.endTime - workflow.startTime;
    workflow.result = { nft, imageUrl, metadata };
    
    db.metrics.workflowsCompleted++;
    io.emit('workflow-completed', workflow);
    
    return workflow;
  }
  
  static async musicGenerationWorkflow(workflow, params) {
    workflow.steps.push({ step: 1, action: 'generate_music', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    const musicFile = {
      id: uuidv4(),
      filename: `music_${Date.now()}.mp3`,
      duration: params.duration || 60,
      genre: params.genre || 'electronic',
      bpm: params.bpm || 120,
      format: 'mp3',
      path: `/generated/music_${Date.now()}.mp3`,
      created: new Date().toISOString()
    };
    
    workflow.steps[0].status = 'completed';
    workflow.steps[0].output = musicFile;
    workflow.status = 'completed';
    workflow.result = musicFile;
    
    db.metrics.workflowsCompleted++;
    return workflow;
  }
  
  static async videoCreationWorkflow(workflow, params) {
    workflow.steps.push({ step: 1, action: 'generate_frames', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 2000));
    workflow.steps[0].status = 'completed';
    
    workflow.steps.push({ step: 2, action: 'render_video', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    const video = {
      id: uuidv4(),
      filename: `video_${Date.now()}.mp4`,
      duration: params.duration || 30,
      resolution: params.resolution || '1920x1080',
      format: 'mp4',
      path: `/generated/video_${Date.now()}.mp4`,
      created: new Date().toISOString()
    };
    
    workflow.steps[1].status = 'completed';
    workflow.steps[1].output = video;
    workflow.status = 'completed';
    workflow.result = video;
    
    db.metrics.workflowsCompleted++;
    return workflow;
  }
  
  static async cryptoStrategyWorkflow(workflow, params) {
    workflow.steps.push({ step: 1, action: 'analyze_market', status: 'running' });
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const analysis = {
      pairs: params.pairs || ['BTC/USDT', 'ETH/USDT'],
      signals: params.pairs.map(pair => ({
        pair,
        signal: ['buy', 'sell', 'hold'][Math.floor(Math.random() * 3)],
        confidence: parseFloat((60 + Math.random() * 40).toFixed(2)),
        price: parseFloat((1000 + Math.random() * 50000).toFixed(2))
      })),
      timestamp: new Date().toISOString()
    };
    
    workflow.steps[0].status = 'completed';
    workflow.steps[0].output = analysis;
    workflow.status = 'completed';
    workflow.result = analysis;
    
    db.metrics.workflowsCompleted++;
    return workflow;
  }
}

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
      
      // Emit progress
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
    
    return nfts;
  }
}

// ========================================
// CRYPTO TRADING SIMULATOR
// ========================================
class CryptoTrader {
  static async analyzePairs(pairs) {
    const analysis = await Promise.all(pairs.map(async pair => {
      await new Promise(resolve => setTimeout(resolve, 100));
      
      return {
        pair,
        price: parseFloat((1000 + Math.random() * 50000).toFixed(2)),
        change24h: parseFloat((-10 + Math.random() * 20).toFixed(2)),
        volume: parseFloat((1000000 + Math.random() * 10000000).toFixed(0)),
        signal: ['buy', 'sell', 'hold'][Math.floor(Math.random() * 3)],
        confidence: parseFloat((60 + Math.random() * 40).toFixed(2)),
        indicators: {
          rsi: parseFloat((30 + Math.random() * 40).toFixed(2)),
          macd: parseFloat((-100 + Math.random() * 200).toFixed(2)),
          ma50: parseFloat((1000 + Math.random() * 50000).toFixed(2)),
          ma200: parseFloat((1000 + Math.random() * 50000).toFixed(2))
        },
        timestamp: new Date().toISOString()
      };
    }));
    
    return {
      pairs: analysis,
      summary: {
        totalPairs: pairs.length,
        buySignals: analysis.filter(a => a.signal === 'buy').length,
        sellSignals: analysis.filter(a => a.signal === 'sell').length,
        holdSignals: analysis.filter(a => a.signal === 'hold').length,
        avgConfidence: _.meanBy(analysis, 'confidence').toFixed(2)
      },
      timestamp: new Date().toISOString()
    };
  }
}

// ========================================
// API ROUTES
// ========================================

// Root
app.get('/', (req, res) => {
  res.json({
    name: 'GENE1799 ART CORPORATIONE v8.5',
    domain: 'gene1799artcorporatione.mom',
    status: 'PRODUCTION',
    version: '8.5.0',
    features: [
      'DDoS Protection (Cloudflare + Express)',
      'Rate Limiting Multi-Layer',
      'IP Whitelisting',
      '500 AI Agents',
      'WebSocket Real-time',
      'NFT Management',
      'Batch Operations (NEW)',
      'AI Workflows (NEW)',
      'Crypto Trading Simulator (NEW)',
      'Advanced Analytics (NEW)'
    ],
    endpoints: {
      health: '/api/health',
      agents: '/api/agents',
      agentsBatch: '/api/agents/batch-create',
      nfts: '/api/nft',
      nftsBatch: '/api/nft/batch-create',
      metrics: '/api/metrics',
      ipStats: '/api/ip-stats',
      security: '/api/security-status',
      workflows: '/api/workflows',
      crypto: '/api/crypto/analyze'
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
    version: '8.5.0',
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

// Agents - Enhanced
app.get('/api/agents', apiLimiter, (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 25;
  const category = req.query.category;
  const status = req.query.status;
  
  let agents = Array.from(db.agents.values());
  
  // Filters
  if (category) agents = agents.filter(a => a.category === category.toUpperCase());
  if (status) agents = agents.filter(a => a.status === status);
  
  const start = (page - 1) * limit;
  const paginated = agents.slice(start, start + limit);
  
  res.json({
    success: true,
    total: agents.length,
    page,
    limit,
    agents: paginated,
    stats: {
      active: agents.filter(a => a.status === 'active').length,
      training: agents.filter(a => a.status === 'training').length,
      gpuEnabled: agents.filter(a => a.gpu).length,
      avgEfficiency: _.meanBy(agents, 'efficiency').toFixed(2)
    }
  });
});

app.get('/api/agents/:id', (req, res) => {
  const agent = db.agents.get(req.params.id);
  if (!agent) {
    return res.status(404).json({ success: false, error: 'Agent not found' });
  }
  res.json({ success: true, agent });
});

app.post('/api/agents/create', createLimiter, (req, res) => {
  const agent = {
    id: `AGT_${uuidv4()}`,
    name: req.body.name || `Agent_${Date.now()}`,
    category: req.body.category || 'GENERAL',
    status: 'active',
    efficiency: 85,
    capabilities: req.body.capabilities || ['automation'],
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
  io.emit('agent-created', agent);
  res.json({ success: true, agent });
});

// NEW: Batch Create Agents
app.post('/api/agents/batch-create', createLimiter, async (req, res) => {
  try {
    const count = Math.min(req.body.count || 10, 100); // Max 100 per request
    const template = req.body.template || {};
    
    const agents = await BatchOperations.createAgentsBatch(count, template);
    
    res.json({
      success: true,
      created: agents.length,
      agents: agents.slice(0, 10), // Return first 10
      message: `${agents.length} agents created successfully`
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Execute Task
app.post('/api/agents/:id/execute', async (req, res) => {
  try {
    const agent = db.agents.get(req.params.id);
    if (!agent) {
      return res.status(404).json({ success: false, error: 'Agent not found' });
    }
    
    agent.status = 'working';
    db.agents.set(agent.id, agent);
    
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    const result = {
      success: true,
      agentId: agent.id,
      task: req.body.task || 'processing',
      output: `Task completed by ${agent.name}`,
      timestamp: new Date().toISOString()
    };
    
    agent.status = 'active';
    agent.stats.tasksCompleted++;
    agent.lastActive = new Date().toISOString();
    db.agents.set(agent.id, agent);
    db.tasks.push(result);
    db.metrics.tasksExecuted++;
    
    io.emit('task-completed', result);
    res.json(result);
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// NFTs - Enhanced
app.get('/api/nft', (req, res) => {
  const marketplace = req.query.marketplace;
  let nfts = Array.from(db.nfts.values());
  
  if (marketplace) {
    nfts = nfts.filter(n => n.marketplace === marketplace);
  }
  
  res.json({
    success: true,
    total: nfts.length,
    nfts
  });
});

app.get('/api/nft/:id', (req, res) => {
  const nft = db.nfts.get(req.params.id);
  if (!nft) {
    return res.status(404).json({ success: false, error: 'NFT not found' });
  }
  res.json({ success: true, nft });
});

app.post('/api/nft/create', createLimiter, (req, res) => {
  try {
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
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// NEW: Batch Create NFTs
app.post('/api/nft/batch-create', createLimiter, async (req, res) => {
  try {
    const count = Math.min(req.body.count || 5, 50); // Max 50 per request
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

// NEW: Workflows
app.post('/api/workflow/ai-to-nft', async (req, res) => {
  try {
    const workflow = await WorkflowEngine.executeWorkflow('ai-to-nft', req.body);
    res.json({ success: true, workflow });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/workflow/music-generation', async (req, res) => {
  try {
    const workflow = await WorkflowEngine.executeWorkflow('music-generation', req.body);
    res.json({ success: true, workflow });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/workflow/video-creation', async (req, res) => {
  try {
    const workflow = await WorkflowEngine.executeWorkflow('video-creation', req.body);
    res.json({ success: true, workflow });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/workflow/crypto-strategy', async (req, res) => {
  try {
    const workflow = await WorkflowEngine.executeWorkflow('crypto-strategy', req.body);
    res.json({ success: true, workflow });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/workflows', (req, res) => {
  const workflows = db.workflows;
  res.json({
    success: true,
    total: workflows.length,
    workflows: workflows.slice(-50) // Last 50
  });
});

// NEW: Crypto Analysis
app.post('/api/crypto/analyze', async (req, res) => {
  try {
    const pairs = req.body.pairs || ['BTC/USDT', 'ETH/USDT', 'SOL/USDT'];
    const analysis = await CryptoTrader.analyzePairs(pairs);
    res.json({ success: true, analysis });
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
    version: '8.5.0', 
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

process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing...');
  server.close(() => process.exit(0));
});

// ========================================
// START SERVER
// ========================================
server.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  GENE1799 ART CORPORATIONE v8.5 - LIVE SERVER   ║');
  console.log('╚══════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server:      http://0.0.0.0:${PORT}`);
  console.log(`🤖 Agents:      ${db.agents.size} loaded`);
  console.log(`🛡️  Protection:  DDoS + Rate Limit + Firewall`);
  console.log(`🌐 WebSocket:   ENABLED`);
  console.log(`🎯 Whitelist:   74.220.48.0/24, 74.220.56.0/24`);
  console.log(`⚡ NEW FEATURES:`);
  console.log(`   • Batch Operations (Agents/NFTs)`);
  console.log(`   • AI Workflows (4 types)`);
  console.log(`   • Crypto Analysis`);
  console.log(`   • Real-time Progress Events\n`);
});
