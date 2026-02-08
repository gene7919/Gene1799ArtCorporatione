# 🚀 Complete Deployment Guide - GENE1799 ART CORPORATIONE

## Table of Contents

1. [Quick Start](#quick-start)
2. [Local Development](#local-development)
3. [Docker Deployment](#docker-deployment)
4. [Render.com Deployment](#rendercom-deployment)
5. [Azure Deployment](#azure-deployment)
6. [Production Configuration](#production-configuration)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

Get the system running in 5 minutes:

```bash
# Clone repository
git clone https://github.com/gene7919/Gene1799ArtCorporatione.git
cd Gene1799ArtCorporatione

# Install dependencies
npm install

# Configure environment
cp .env.example .env
nano .env  # Add your API keys

# Start server
npm start
```

Server will be available at `http://localhost:3000`

---

## Local Development

### Prerequisites

- Node.js >= 18.0.0
- npm or yarn
- Git
- Python 3.8+ (optional, for full AI features)

### Setup Steps

1. **Clone and Install**
   ```bash
   git clone https://github.com/gene7919/Gene1799ArtCorporatione.git
   cd Gene1799ArtCorporatione
   npm install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```bash
   # Required
   NODE_ENV=development
   PORT=3000
   JWT_SECRET=your_secret_here
   SESSION_SECRET=your_session_secret
   
   # Optional AI Services
   OPENAI_API_KEY=sk-...
   ANTHROPIC_API_KEY=...
   ```

3. **Install Python Dependencies (Optional)**
   ```bash
   cd Desktop/Gene1799ArtCorporatione
   pip install -r requirements.txt
   # or
   pip install numpy pandas scikit-learn openai anthropic
   ```

4. **Start Development Server**
   ```bash
   npm run dev
   ```
   
   Server starts with auto-reload on `http://localhost:3000`

5. **Verify Installation**
   ```bash
   curl http://localhost:3000/api/health
   ```

### Available Scripts

```bash
npm start       # Production mode
npm run dev     # Development mode with nodemon
npm test        # Run tests
npm run lint    # Lint code
```

---

## Docker Deployment

### Build and Run

**Option 1: Docker**
```bash
# Build image
docker build -t gene1799-backend .

# Run container
docker run -d \
  --name gene1799 \
  -p 3000:3000 \
  --env-file .env \
  gene1799-backend

# View logs
docker logs -f gene1799

# Stop container
docker stop gene1799
```

**Option 2: Docker Compose** (Recommended)
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after changes
docker-compose up -d --build
```

### Docker Configuration

The Dockerfile includes:
- Node.js 20 Alpine base
- Python 3 support
- All necessary dependencies
- Health checks
- Automatic restarts

### Docker Environment Variables

Create a `.env` file or use docker-compose environment variables:

```bash
# .env file
NODE_ENV=production
PORT=3000
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
# ... other variables
```

---

## Render.com Deployment

### One-Click Deployment

1. **Connect GitHub**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New +" → "Web Service"
   - Connect your GitHub account
   - Select `Gene1799ArtCorporatione` repository

2. **Configure Service**
   - Name: `gene1799-backend`
   - Region: `Frankfurt` (or closest to your users)
   - Branch: `main`
   - Build Command: `npm install --production`
   - Start Command: `npm start`

3. **Environment Variables**
   
   Add these in Render dashboard under "Environment":
   ```
   NODE_ENV=production
   PORT=10000
   JWT_SECRET=<generate-random>
   SESSION_SECRET=<generate-random>
   OPENAI_API_KEY=<your-key>
   ANTHROPIC_API_KEY=<your-key>
   TELEGRAM_BOT_TOKEN=<your-token>
   # ... add others as needed
   ```

4. **Deploy**
   - Click "Create Web Service"
   - Wait for build and deployment (5-10 minutes)
   - Access your service at the provided URL

### Using render.yaml

The repository includes `render.yaml` for automatic configuration:

```bash
# render.yaml is automatically detected by Render
# Just connect your repository and it will configure everything
```

### Auto-Deploy

Enable auto-deploy to automatically deploy on git push:
- Settings → Build & Deploy
- Enable "Auto-Deploy"
- Push to main branch triggers deployment

---

## Azure Deployment

### Prerequisites

- Azure account
- Azure CLI installed
- Resource group created

### Quick Deploy with ARM Template

**One-Click Button**:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template)

**Manual Deployment**:

1. **Login to Azure**
   ```bash
   az login
   ```

2. **Create Resource Group**
   ```bash
   az group create \
     --name gene1799-rg \
     --location westeurope
   ```

3. **Deploy Template**
   ```bash
   az deployment group create \
     --resource-group gene1799-rg \
     --template-file azure-infrastructure-template.json \
     --parameters azure-parameters.json
   ```

4. **Configure App Service**
   ```bash
   # Set environment variables
   az webapp config appsettings set \
     --name gene1799-app \
     --resource-group gene1799-rg \
     --settings \
       NODE_ENV=production \
       OPENAI_API_KEY=<your-key>
   ```

### Azure Services Created

- App Service Plan
- Web App
- PostgreSQL Database (optional)
- Redis Cache (optional)
- Application Insights
- Storage Account

### Cost Estimation

- **Free Tier**: $0/month (limited resources)
- **Basic Tier**: ~$13/month
- **Standard Tier**: ~$50/month
- **Premium Tier**: ~$150/month

---

## Production Configuration

### Essential Environment Variables

```bash
# Server
NODE_ENV=production
PORT=3000

# Security
JWT_SECRET=<strong-random-secret>
SESSION_SECRET=<strong-random-secret>
CORS_ORIGIN=https://yourdomain.com

# Rate Limiting
RATE_LIMIT_MAX=100

# AI Services
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
STABILITY_API_KEY=sk-...
RUNWAYML_API_KEY=...

# Blockchain
ETHEREUM_RPC_URL=https://mainnet.base.org
TOKEN_CONTRACT_ADDRESS=0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0
CHAIN_ID=8453

# Social Media
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHANNEL_ID=...
TWITTER_API_KEY=...
LINKEDIN_CLIENT_ID=...

# Database (if using)
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Monitoring
SENTRY_DSN=...
AZURE_INSIGHTS_KEY=...

# Feature Flags
ENABLE_AI_AGENTS=true
ENABLE_CONTENT_CREATION=true
ENABLE_SOCIAL_AUTOMATION=true
ENABLE_WEB3=true
```

### Security Best Practices

1. **Use Strong Secrets**
   ```bash
   # Generate random secrets
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

2. **Enable HTTPS**
   - Use Let's Encrypt for free SSL
   - Configure in reverse proxy (nginx, Apache)
   - Or use cloud provider's SSL

3. **Configure CORS**
   ```bash
   CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com
   ```

4. **Rate Limiting**
   ```bash
   RATE_LIMIT_MAX=100  # Adjust based on needs
   ```

5. **Monitoring**
   - Enable Application Insights
   - Configure Sentry for error tracking
   - Set up log aggregation

### Performance Tuning

1. **Node.js Options**
   ```bash
   NODE_OPTIONS=--max-old-space-size=4096
   ```

2. **Process Manager**
   ```bash
   # Install PM2
   npm install -g pm2
   
   # Start with PM2
   pm2 start server.js --name gene1799 -i max
   
   # Auto-restart on system boot
   pm2 startup
   pm2 save
   ```

3. **Caching**
   - Add Redis for caching
   - Cache frequently accessed data
   - Use CDN for static assets

---

## Post-Deployment

### Verification Checklist

After deployment, verify:

```bash
# 1. Health check
curl https://yourdomain.com/api/health

# 2. API endpoints
curl https://yourdomain.com/api/agents

# 3. Agent execution
curl -X POST https://yourdomain.com/api/agents/anti-cancer/execute \
  -H "Content-Type: application/json" \
  -d '{"task":"test","parameters":{}}'

# 4. Content creation
curl -X POST https://yourdomain.com/api/content/create \
  -H "Content-Type: application/json" \
  -d '{"type":"text","prompt":"test"}'
```

### Monitoring Setup

1. **Set up monitoring**
   - Application Insights (Azure)
   - Sentry (Error tracking)
   - Custom dashboards

2. **Configure alerts**
   - Server down
   - High error rate
   - High latency
   - Resource usage

3. **Log management**
   - Centralized logging
   - Log rotation
   - Log analysis

### Backup Strategy

1. **Database backups**
   ```bash
   # Automated daily backups
   # Configure in cloud provider
   ```

2. **Code backups**
   - Git repository (already backed up)
   - Multiple remotes recommended

3. **Configuration backups**
   - Store `.env` securely (not in git)
   - Use secret management services

---

## Troubleshooting

### Common Issues

#### 1. Server Won't Start

**Error**: `Error: listen EADDRINUSE: address already in use :::3000`

**Solution**:
```bash
# Find process using port
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
PORT=3001 npm start
```

#### 2. Python System Not Available

**Error**: `Python system not available, running in Node-only mode`

**Solution**:
```bash
# Install Python dependencies
cd Desktop/Gene1799ArtCorporatione
pip install -r requirements.txt

# Set Python path
export PYTHON_PATH=/usr/bin/python3
```

#### 3. API Keys Not Working

**Error**: `401 Unauthorized` from AI services

**Solution**:
- Verify API keys are correct
- Check key hasn't expired
- Ensure sufficient credits/quota
- Verify environment variables are loaded

#### 4. High Memory Usage

**Solution**:
```bash
# Increase Node.js memory
NODE_OPTIONS=--max-old-space-size=4096 npm start

# Monitor memory
curl http://localhost:3000/api/health
```

#### 5. Database Connection Failed

**Solution**:
- Verify DATABASE_URL is correct
- Check database is accessible
- Verify credentials
- Check firewall rules

### Debug Mode

Enable detailed logging:

```bash
# .env
NODE_ENV=development
LOG_LEVEL=debug
DEBUG=true
```

### Getting Help

- **Documentation**: See CORE_INTEGRATION_GUIDE.md
- **GitHub Issues**: https://github.com/gene7919/Gene1799ArtCorporatione/issues
- **Email**: gene1799artcorporatione@gmail.com
- **Telegram**: @gene1799_art_bot

---

## Deployment Comparison

| Feature | Local | Docker | Render | Azure |
|---------|-------|--------|--------|-------|
| Setup Time | 5 min | 10 min | 15 min | 30 min |
| Cost | Free | Free | $7-25/mo | $13-150/mo |
| Scalability | No | Limited | Good | Excellent |
| Python Support | Yes | Yes | Limited | Yes |
| Auto-Deploy | No | No | Yes | Yes |
| HTTPS | Manual | Manual | Automatic | Automatic |
| Custom Domain | Manual | Manual | Yes | Yes |
| Monitoring | Manual | Manual | Basic | Advanced |
| Best For | Development | Testing | Small Apps | Enterprise |

---

## Next Steps

After deployment:

1. **Configure Custom Domain**
   - Point DNS to your server
   - Configure SSL certificate
   - Update CORS settings

2. **Set Up Monitoring**
   - Configure alerts
   - Set up dashboards
   - Enable error tracking

3. **Optimize Performance**
   - Add caching layer
   - Enable CDN
   - Optimize database queries

4. **Security Hardening**
   - Regular security audits
   - Update dependencies
   - Monitor logs for suspicious activity

5. **Scale as Needed**
   - Add more instances
   - Configure load balancer
   - Optimize resource usage

---

**Last Updated**: February 8, 2026
**Version**: 9.0.0
**Status**: Production Ready

For detailed integration information, see [CORE_INTEGRATION_GUIDE.md](CORE_INTEGRATION_GUIDE.md)
