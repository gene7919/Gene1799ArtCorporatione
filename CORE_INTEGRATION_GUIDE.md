# 🔗 GENE1799 Core System Integration Guide

## Overview

This document describes the complete integration between the Node.js backend API and the Python AI system. The integration provides seamless communication between both systems with automatic fallback capabilities.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Client Applications                          │
│  (Web UI, Mobile Apps, Third-party Services)                    │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTP/WebSocket
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Node.js Express Backend (Port 3000)                 │
│  • REST API Endpoints                                           │
│  • WebSocket Server                                             │
│  • Rate Limiting & Security                                     │
│  • Request Logging                                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              Integration Service Layer                           │
│  • Python Bridge (pythonBridge.js)                              │
│  • Integration Service (integrationService.js)                  │
│  • Automatic Fallback Logic                                     │
│  • Process Management                                           │
└────────┬────────────────────────────────────┬───────────────────┘
         │                                    │
         ▼ (Primary)                          ▼ (Fallback)
┌─────────────────────┐              ┌─────────────────────┐
│  Python AI System   │              │  Node.js Simulation │
│                     │              │                     │
│ • enhanced_system   │              │ • Basic responses   │
│ • content_creation  │              │ • Status tracking   │
│ • ai_learning       │              │ • Mock execution    │
│ • self_healing      │              │                     │
└─────────────────────┘              └─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│              External AI Services                                │
│  • OpenAI (GPT-4, DALL-E)                                       │
│  • Anthropic (Claude)                                           │
│  • Stability AI                                                 │
│  • RunwayML                                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Node.js Backend (server.js)

**Location**: `/server.js`

**Responsibilities**:
- HTTP server on port 3000
- REST API endpoints
- WebSocket server
- Security middleware
- Request handling and routing

**Key Features**:
- Express.js framework
- Helmet security headers
- CORS support
- Rate limiting (100 req/min)
- Winston logging
- Socket.io for real-time communication

### 2. Python Bridge (pythonBridge.js)

**Location**: `/backend/services/pythonBridge.js`

**Purpose**: Provides communication channel between Node.js and Python processes.

**Key Functions**:

```javascript
// Execute one-time Python script
await pythonBridge.execute('script.py', { args });

// Start long-running Python service
const serviceId = pythonBridge.startService('service.py', config);

// Stop running service
pythonBridge.stopService(serviceId);

// Run orchestrator
await pythonBridge.runOrchestrator(config);

// Create content via Python
await pythonBridge.createContent(spec);

// Run self-healing diagnostics
await pythonBridge.runSelfHealing();

// Update learning engine
await pythonBridge.updateLearning(data);
```

**Process Management**:
- Tracks all active Python processes
- Automatic cleanup on shutdown
- Process isolation
- Error handling and logging

### 3. Integration Service (integrationService.js)

**Location**: `/backend/services/integrationService.js`

**Purpose**: Coordinates between Node.js and Python systems with automatic fallback.

**Operating Modes**:
1. **Hybrid Mode**: Python system available, uses Python agents
2. **Node-only Mode**: Python unavailable, uses Node.js fallbacks

**Key Functions**:

```javascript
// Initialize integration
await integrationService.initialize();

// Get system health
const health = await integrationService.getSystemHealth();

// Execute agent with fallback
const result = await integrationService.executeAgent(
  agentId, 
  task, 
  parameters
);

// Create content with fallback
const content = await integrationService.createContent(
  type, 
  prompt, 
  parameters
);

// Update learning
await integrationService.updateLearning(agentId, data);

// Get status
const status = integrationService.getStatus();

// Shutdown
await integrationService.shutdown();
```

### 4. API Routes

**Location**: `/backend/routes/`

**Routes**:

#### Agents API (`/api/agents`)
```javascript
GET    /api/agents              // List all agents
GET    /api/agents/:id          // Get agent details
POST   /api/agents/:id/execute  // Execute agent task
GET    /api/agents/:id/status   // Get agent status
```

#### Content API (`/api/content`)
```javascript
POST   /api/content/create      // Create new content
GET    /api/content/:id         // Get content status
GET    /api/content             // List content
DELETE /api/content/:id         // Delete content
```

#### Social Media API (`/api/social`)
```javascript
POST   /api/social/post         // Create social post
GET    /api/social/posts        // List posts
GET    /api/social/analytics    // Get analytics
GET    /api/social/platforms    // List platforms
```

## Integration Flow

### Agent Execution Flow

```
1. Client Request
   ↓
2. Express Route (/api/agents/:id/execute)
   ↓
3. Integration Service
   ↓
4. Python Bridge (if available)
   ↓
5. Python AI System
   • enhanced_system.py
   • Executes agent logic
   • Returns result
   ↓
6. Response to Client
```

### Fallback Flow

```
1. Client Request
   ↓
2. Integration Service attempts Python execution
   ↓
3. Python execution fails
   ↓
4. Automatic fallback to Node.js simulation
   ↓
5. Returns simulated response with note
   ↓
6. Client receives response
```

## Configuration

### Environment Variables

```bash
# Python System
PYTHON_PATH=python3                    # Python interpreter path

# Feature Flags
ENABLE_AI_AGENTS=true                  # Enable AI agents
ENABLE_CONTENT_CREATION=true           # Enable content creation
ENABLE_SOCIAL_AUTOMATION=true          # Enable social media
ENABLE_WEB3=true                       # Enable Web3 features
ENABLE_TELEGRAM_BOT=true               # Enable Telegram
ENABLE_AUTO_HEALING=true               # Enable self-healing
ENABLE_LEARNING_ENGINE=true            # Enable learning

# AI Services (for Python system)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
STABILITY_API_KEY=...
RUNWAYML_API_KEY=...
```

## Python System Setup

### Requirements

The Python AI system requires the following dependencies:

```bash
# Core
python >= 3.8
numpy
pandas
scikit-learn

# AI/ML
openai
anthropic
torch
transformers

# Content Creation
Pillow
opencv-python
moviepy

# Other
aiohttp
asyncio
```

### Installation

```bash
# Navigate to Python system directory
cd Desktop/Gene1799ArtCorporatione

# Install dependencies
pip install -r requirements.txt

# Or manually
pip install numpy pandas scikit-learn openai anthropic torch transformers Pillow opencv-python moviepy aiohttp
```

## Usage Examples

### Execute AI Agent

```javascript
// POST /api/agents/anti-cancer/execute
{
  "task": "analyze_compound",
  "parameters": {
    "compound": "C20H25N3O",
    "properties": ["toxicity", "efficacy", "interactions"]
  }
}

// Response
{
  "success": true,
  "source": "python",  // or "node" for fallback
  "agentId": "anti-cancer",
  "agentName": "Anti-Cancer AI Engine",
  "task": "analyze_compound",
  "result": {
    "analysis": { /* results */ },
    "recommendations": [ /* list */ ]
  },
  "executionTime": 1234,
  "timestamp": "2026-02-08T20:52:16.410Z"
}
```

### Create Content

```javascript
// POST /api/content/create
{
  "type": "text",
  "prompt": "Write a blog post about AI in healthcare",
  "parameters": {
    "length": 500,
    "tone": "professional",
    "keywords": ["AI", "healthcare", "innovation"]
  }
}

// Response
{
  "success": true,
  "contentId": "content_1707422336410_abc123",
  "type": "text",
  "status": "processing",
  "estimatedTime": "5-10 seconds"
}
```

### Check System Health

```javascript
// GET /api/health

// Response
{
  "status": "healthy",
  "uptime": 12345,
  "version": "9.0.0",
  "systems": {
    "node": {
      "status": "healthy",
      "uptime": 12345,
      "memory": { /* usage */ }
    },
    "python": {
      "status": "running",  // or "unavailable"
      "services": [ /* active services */ ]
    }
  }
}
```

## Monitoring & Debugging

### Logs

**Location**: `/logs/`

Files:
- `combined.log` - All logs
- `error.log` - Errors only

**Log Levels**: error, warn, info, http, verbose, debug, silly

### WebSocket Events

Connect to `ws://localhost:3000` for real-time updates:

```javascript
// Client-side
const socket = io('http://localhost:3000');

socket.on('welcome', (data) => {
  console.log('Connected:', data);
});

socket.emit('agent:status');

socket.on('agent:status:response', (data) => {
  console.log('Agent status:', data);
});
```

### Health Checks

```bash
# Simple health check
curl http://localhost:3000/api/health

# With formatting
curl -s http://localhost:3000/api/health | jq '.'
```

## Troubleshooting

### Python System Not Available

**Symptom**: Logs show "Python system not available, running in Node-only mode"

**Solutions**:
1. Install Python dependencies: `pip install -r requirements.txt`
2. Check Python path: `which python3`
3. Set PYTHON_PATH in .env: `PYTHON_PATH=/usr/bin/python3`
4. Verify Python scripts exist in `Desktop/Gene1799ArtCorporatione/`

### Module Import Errors

**Symptom**: "ModuleNotFoundError: No module named 'X'"

**Solution**: Install missing module
```bash
pip install <module-name>
```

### Port Already in Use

**Symptom**: "EADDRINUSE: address already in use :::3000"

**Solutions**:
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use different port
PORT=3001 npm start
```

### High Memory Usage

**Symptom**: Server becomes slow or crashes

**Solutions**:
1. Restart server regularly
2. Limit concurrent Python processes
3. Increase Node.js memory: `NODE_OPTIONS=--max-old-space-size=4096 npm start`
4. Monitor with `GET /api/health`

## Performance Optimization

### Node.js Optimizations

```bash
# Production mode
NODE_ENV=production npm start

# Increase memory
NODE_OPTIONS=--max-old-space-size=4096 npm start

# Cluster mode (use PM2)
pm2 start server.js -i max
```

### Python Optimizations

1. Use async operations where possible
2. Limit concurrent Python processes
3. Cache frequently used results
4. Use lightweight models for quick tasks

### Caching

Add Redis caching layer:
```bash
npm install redis
```

```javascript
const redis = require('redis');
const client = redis.createClient();
```

## Security Considerations

### Best Practices

1. **Never commit secrets**: Use .env files
2. **Validate all inputs**: Sanitize user data
3. **Rate limiting**: Already implemented
4. **HTTPS**: Use in production
5. **Process isolation**: Python processes are isolated
6. **Error handling**: Never expose internal errors to clients

### Security Checklist

- [ ] All API keys in .env (not committed)
- [ ] HTTPS enabled in production
- [ ] Rate limiting configured
- [ ] Input validation on all endpoints
- [ ] Error messages don't leak sensitive info
- [ ] Logs don't contain secrets
- [ ] Dependencies updated regularly
- [ ] Python processes run with limited permissions

## Deployment

### Docker Deployment

```bash
# Build
docker build -t gene1799-backend .

# Run
docker run -p 3000:3000 --env-file .env gene1799-backend

# With Python support
docker run -p 3000:3000 --env-file .env \
  -v $(pwd)/Desktop:/app/Desktop \
  gene1799-backend
```

### Production Checklist

- [ ] Environment variables configured
- [ ] Python dependencies installed
- [ ] Logs directory exists
- [ ] Health check endpoint accessible
- [ ] HTTPS configured
- [ ] Monitoring setup
- [ ] Backup strategy in place
- [ ] Auto-restart configured (PM2, systemd, etc.)

## Support

For issues or questions:
- GitHub Issues: https://github.com/gene7919/Gene1799ArtCorporatione/issues
- Email: gene1799artcorporatione@gmail.com
- Telegram: @gene1799_art_bot

---

**Last Updated**: February 8, 2026
**Version**: 9.0.0
**Status**: Production Ready
