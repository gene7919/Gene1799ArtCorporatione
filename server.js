const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const winston = require('winston');
const { createServer } = require('http');
const { Server } = require('socket.io');
const { getOrchestratorService } = require('./backend/services/orchestratorService');
require('dotenv').config();

// Initialize Express app
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;

// Get orchestrator service
const orchestratorService = getOrchestratorService();

// Configure Winston Logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});

// Security Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX || '100'),
  message: 'Too many requests, please try again later'
});
app.use('/api/', limiter);

// Speed Limiting
const speedLimiter = slowDown({
  windowMs: 60 * 1000,
  delayAfter: 50,
  delayMs: () => 500
});
app.use('/api/', speedLimiter);

// Request Logging Middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Health Check Endpoint
app.get('/api/health', async (req, res) => {
  try {
    const orchestratorHealth = orchestratorService.getHealth();
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: require('./package.json').version,
      environment: process.env.NODE_ENV || 'development',
      orchestrator: orchestratorHealth
    });
  } catch (error) {
    logger.error('Health check error:', error);
    res.status(503).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Root Endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'GENE1799 ART CORPORATIONE Backend API',
    version: require('./package.json').version,
    status: 'running',
    endpoints: {
      health: '/api/health',
      orchestrator: '/api/orchestrator',
      websocket: 'ws://localhost:' + PORT
    }
  });
});

// Import route modules
const orchestratorRoutes = require('./backend/routes/orchestrator');

// Register API routes
app.use('/api/orchestrator', orchestratorRoutes);

// WebSocket Connection Handler
io.on('connection', (socket) => {
  logger.info(`WebSocket client connected: ${socket.id}`);
  
  socket.emit('welcome', {
    message: 'Connected to GENE1799 Real-time System',
    socketId: socket.id,
    timestamp: new Date().toISOString()
  });
  
  socket.on('agent:status', () => {
    socket.emit('agent:status:response', {
      agents: ['anti-cancer', 'drug-discovery', 'ml-orchestrator'],
      allActive: true
    });
  });
  
  socket.on('disconnect', () => {
    logger.info(`WebSocket client disconnected: ${socket.id}`);
  });
});

// Error Handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found'
  });
});

// Start Server
httpServer.listen(PORT, async () => {
  logger.info(`GENE1799 Backend Server running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`Health check: http://localhost:${PORT}/api/health`);
  
  // Ensure log directory exists
  const fs = require('fs');
  if (!fs.existsSync('logs')) {
    fs.mkdirSync('logs', { recursive: true });
  }
  
  if (!fs.existsSync('data')) {
    fs.mkdirSync('data', { recursive: true });
  }
  
  // Initialize orchestrator service
  try {
    await orchestratorService.initialize();
    logger.info('Orchestrator service initialized successfully');
  } catch (error) {
    logger.error('Orchestrator service initialization failed:', error);
    logger.warn('Running in limited mode');
  }
});

// Graceful Shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  
  // Shutdown orchestrator service
  try {
    await orchestratorService.shutdown();
    logger.info('Orchestrator service shutdown complete');
  } catch (error) {
    logger.error('Orchestrator service shutdown error:', error);
  }
  
  httpServer.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

module.exports = { app, httpServer, io };


