# 🚀 Gene1799 Art Corporatione Backend v9.1

## Overview
Multi-agent AI system backend with IP whitelisting, rate limiting, and DDoS protection.

## Features
- 🤖 **500 AI Agents** (VIDEO, ART, TRADING, MUSIC, LEARNING)
- 🎯 **IP Whitelisting**: 74.220.48.0/24, 74.220.56.0/24
- 🛡️ **Rate Limiting**: 100 req/15min (bypassed for target IPs)
- 🔒 **Security**: Helmet.js, CORS, Compression
- 📡 **WebSocket**: Real-time metrics updates
- 📊 **Monitoring**: Built-in metrics and stats

## Endpoints

### Health Check
\\\
GET /api/health
\\\

### IP Verification
\\\
GET /api/ip-check
\\\

### Agents
\\\
GET /api/agents?page=1&limit=25
\\\

### Metrics
\\\
GET /api/metrics
\\\

### IP Statistics
\\\
GET /api/ip-stats
\\\

## Local Development

\\\ash
# Install dependencies
npm install

# Start server
node server.js
# or
npm start
\\\

Server runs on: http://localhost:10000

## Production Deployment

### Render.com
- Branch: \master\
- Root Directory: \ackend\
- Build Command: \
pm install\
- Start Command: \
ode server.js\

## Environment Variables
- \PORT\: Server port (default: 10000)
- \NODE_ENV\: Environment (production/development)

## Tech Stack
- **Runtime**: Node.js >= 18.0.0
- **Framework**: Express.js
- **WebSocket**: Socket.io
- **Security**: Helmet, express-rate-limit
- **Utilities**: Lodash, Moment.js

## Version
v9.1.0 - Production Ready

## License
MIT

## Author
Gene1799 Art Corporatione
