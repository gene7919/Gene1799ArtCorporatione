const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const http = require('http');
const socketIo = require('socket.io');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const _ = require('lodash');
const moment = require('moment');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: '*' } });
const PORT = process.env.PORT || 10000;

const TARGET_RANGES = ['74.220.48.0/24', '74.220.56.0/24'];

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

function checkTargetIP(ip) {
  return TARGET_RANGES.some(range => isIPInRange(ip, range));
}

app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  skip: (req) => {
    const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0].trim();
    return checkTargetIP(ip);
  }
});

app.use(globalLimiter);

app.use((req, res, next) => {
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0].trim();
  const inTarget = checkTargetIP(ip);
  const icon = inTarget ? '🎯' : '📍';
  console.log(`${icon} ${req.method} ${req.path} | IP: ${ip}`);
  req.isTargetIP = inTarget;
  next();
});

class Database {
  constructor() {
    this.agents = new Map();
    this.metrics = { requests: 0, targetIPHits: 0, startTime: Date.now() };
    this.initAgents();
  }
  
  initAgents() {
    const categories = ['VIDEO', 'ART', 'TRADING', 'MUSIC', 'LEARNING'];
    for (let i = 0; i < 500; i++) {
      this.agents.set(`GAC_${i.toString().padStart(4, '0')}`, {
        id: `GAC_${i.toString().padStart(4, '0')}`,
        name: `${categories[i % 5]}_AGENT_${i}`,
        category: categories[i % 5],
        status: 'active',
        efficiency: parseFloat((85 + Math.random() * 15).toFixed(1))
      });
    }
    console.log(`✅ Initialized ${this.agents.size} agents`);
  }
  
  getMetrics() {
    return {
      ...this.metrics,
      agents: this.agents.size,
      uptime: Math.floor((Date.now() - this.metrics.startTime) / 1000)
    };
  }
}

const db = new Database();

app.use((req, res, next) => {
  db.metrics.requests++;
  if (req.isTargetIP) db.metrics.targetIPHits++;
  next();
});

app.get('/', (req, res) => {
  res.json({
    name: 'GENE1799 ART CORPORATIONE v9.1',
    status: 'PRODUCTION',
    features: ['IP Whitelisting (74.220.48.0/24, 74.220.56.0/24)', '500 AI Agents', 'DDoS Protection'],
    targetRanges: TARGET_RANGES
  });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'online', 
    version: '9.1.0',
    environment: 'production',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    metrics: db.getMetrics(),
    isTargetIP: req.isTargetIP || false
  });
});

app.get('/api/ip-check', (req, res) => {
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress).split(',')[0].trim();
  res.json({
    success: true,
    ip,
    isTargetIP: checkTargetIP(ip),
    targetRanges: TARGET_RANGES,
    rateLimitBypassed: checkTargetIP(ip)
  });
});

app.get('/api/agents', (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 25;
  const agents = Array.from(db.agents.values()).slice((page - 1) * limit, page * limit);
  res.json({ 
    success: true, 
    total: db.agents.size, 
    page,
    limit,
    agents,
    isTargetIP: req.isTargetIP || false
  });
});

app.get('/api/metrics', (req, res) => {
  res.json({ success: true, metrics: db.getMetrics() });
});

app.get('/api/ip-stats', (req, res) => {
  const percentage = db.metrics.requests > 0 
    ? ((db.metrics.targetIPHits / db.metrics.requests) * 100).toFixed(2)
    : '0.00';
  
  res.json({
    success: true,
    targetIPHits: db.metrics.targetIPHits,
    totalRequests: db.metrics.requests,
    targetRanges: TARGET_RANGES,
    percentage
  });
});

io.on('connection', (socket) => {
  console.log(`✅ WebSocket connected: ${socket.id}`);
  socket.emit('welcome', { version: '9.1.0', agents: db.agents.size, targetRanges: TARGET_RANGES });
  const interval = setInterval(() => socket.emit('metrics-update', db.getMetrics()), 5000);
  socket.on('disconnect', () => clearInterval(interval));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  GENE1799 ART CORPORATIONE v9.1 - PRODUCTION    ║');
  console.log('╚══════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server:      http://0.0.0.0:${PORT}`);
  console.log(`🤖 Agents:      ${db.agents.size} loaded`);
  console.log(`🎯 Whitelist:   ${TARGET_RANGES.join(', ')}\n`);
});
