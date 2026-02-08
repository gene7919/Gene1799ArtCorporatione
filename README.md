# 🎨 GENE1799 ART CORPORATIONE - Integrated AI Platform

<div align="center">

![Version](https://img.shields.io/badge/version-9.0.0-brightgreen)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/status-production%20ready-success)

**Advanced AI-Powered Art & Content Creation Platform**

[Features](#features) • [Quick Start](#quick-start) • [API Documentation](#api-documentation) • [Deployment](#deployment) • [Contributing](#contributing)

</div>

---

## 🚀 Overview

GENE1799 ART CORPORATIONE is an enterprise-grade, fully integrated AI platform that combines multiple AI agents, content creation systems, social media automation, and blockchain integration into a unified, production-ready backend service.

### 🌟 Key Features

- **🤖 AI Agent Orchestration** - 6 specialized AI agents for different tasks
- **🎨 Multi-Modal Content Creation** - Text, images, video, and music generation
- **📱 Social Media Automation** - Multi-platform posting and analytics
- **🔗 Web3 Integration** - NFT support and blockchain connectivity
- **🔒 Enterprise Security** - 5-layer security matrix with rate limiting
- **📊 Real-time Monitoring** - WebSocket support for live updates
- **🔧 Self-Healing System** - Automatic error detection and recovery
- **📈 Learning Engine** - Continuous improvement through ML

---

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [API Documentation](#api-documentation)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Development](#development)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

---

## ✨ Features

### AI Agents

The platform includes 6 specialized AI agents:

1. **Anti-Cancer AI Engine** - Medical research and drug discovery
2. **Drug Discovery Engine** - Pharmaceutical compound analysis
3. **ML Orchestrator** - Machine learning pipeline automation
4. **Content Creator** - Multi-modal content generation
5. **Social Media Manager** - Automated social engagement
6. **Self-Healing Agent** - System monitoring and auto-repair

### Content Creation

- **Text Generation**: GPT-4 powered writing with multiple styles
- **Image Creation**: DALL-E 3 and Stability AI integration
- **Video Synthesis**: RunwayML Gen-3 for video creation
- **Music Composition**: AI-powered music generation

### Social Media Platforms

Integrated support for:
- Twitter/X
- LinkedIn
- Instagram
- TikTok
- Telegram

### Web3 & NFT

- MetaMask integration
- Base Network (Chain ID: 8453)
- NFT marketplace integration (OpenSea, Zora, SuperRare)
- Token contract: `0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0`

---

## 🚀 Quick Start

### Prerequisites

- Node.js >= 18.0.0
- npm or yarn
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/gene7919/Gene1799ArtCorporatione.git
cd Gene1799ArtCorporatione

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your API keys and configuration
nano .env

# Start the server
npm start
```

### Development Mode

```bash
npm run dev
```

The server will start on `http://localhost:3000`

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client Layer                          │
│  (Web UI, Mobile Apps, External Services)               │
└────────────────────┬─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│               Express.js Backend API                      │
│  • Rate Limiting  • CORS  • Helmet Security              │
│  • JWT Auth       • Logging (Winston)                    │
└────┬─────────────┬─────────────┬────────────────────────┘
     │             │             │
┌────▼────┐  ┌────▼────┐  ┌────▼────┐
│ Agents  │  │Content  │  │ Social  │
│ Routes  │  │ Routes  │  │ Routes  │
└────┬────┘  └────┬────┘  └────┬────┘
     │             │             │
┌────▼─────────────▼─────────────▼────────────────────────┐
│              Service Layer                               │
│  • AI Agent Controllers                                  │
│  • Content Generation Services                           │
│  • Social Media Integrations                             │
│  • Web3 & Blockchain Services                            │
└────┬─────────────┬─────────────┬────────────────────────┘
     │             │             │
┌────▼────┐  ┌────▼────┐  ┌────▼────┐
│ OpenAI  │  │ DALL-E  │  │Twitter  │
│   API   │  │ Runway  │  │LinkedIn │
└─────────┘  └─────────┘  └─────────┘
```

---

## 📚 API Documentation

### Health Check

```http
GET /api/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-08T20:52:16.410Z",
  "uptime": 12345,
  "version": "9.0.0",
  "environment": "production"
}
```

### AI Agents

#### List All Agents

```http
GET /api/agents
```

#### Get Agent Details

```http
GET /api/agents/:id
```

#### Execute Agent Task

```http
POST /api/agents/:id/execute

{
  "task": "analyze compound",
  "parameters": {
    "compound": "C20H25N3O"
  }
}
```

### Content Creation

#### Create Content

```http
POST /api/content/create

{
  "type": "text|image|video|music",
  "prompt": "Your creative prompt",
  "parameters": {}
}
```

#### Get Content Status

```http
GET /api/content/:id
```

### Social Media

#### Post to Platform

```http
POST /api/social/post

{
  "platform": "twitter",
  "content": "Your post content",
  "media": [],
  "schedule": "2026-02-09T12:00:00Z" // optional
}
```

#### Get Analytics

```http
GET /api/social/analytics?platform=twitter&days=7
```

### WebSocket Events

Connect to `ws://localhost:3000`

**Events:**
- `welcome` - Connection established
- `agent:status` - Request agent status
- `agent:status:response` - Receive agent status
- `content:update` - Content generation updates
- `social:engagement` - Real-time engagement metrics

---

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Server
NODE_ENV=production
PORT=3000

# Security
JWT_SECRET=your_secret_here
SESSION_SECRET=your_session_secret

# AI Services
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
STABILITY_API_KEY=...
RUNWAYML_API_KEY=...

# Social Media
TELEGRAM_BOT_TOKEN=...
TWITTER_API_KEY=...
LINKEDIN_CLIENT_ID=...

# Web3
ETHEREUM_RPC_URL=https://mainnet.base.org
TOKEN_CONTRACT_ADDRESS=0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0
```

See `.env.example` for complete list of configuration options.

---

## 🚢 Deployment

### Docker Deployment

```bash
# Build image
docker build -t gene1799-backend .

# Run container
docker run -p 3000:3000 --env-file .env gene1799-backend
```

### Docker Compose

```bash
docker-compose up -d
```

### Render.com

The project includes a `render.yaml` configuration file for one-click deployment to Render.com.

1. Connect your GitHub repository to Render
2. Create a new Web Service
3. Render will automatically detect `render.yaml`
4. Add environment variables in Render dashboard
5. Deploy!

### Azure Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template)

See `AZURE_DEPLOYMENT_QUICK.md` for detailed Azure deployment instructions.

---

## 👨‍💻 Development

### Project Structure

```
Gene1799ArtCorporatione/
├── server.js                 # Main application entry
├── package.json             # Dependencies and scripts
├── .env.example            # Environment template
├── backend/
│   ├── routes/             # API route handlers
│   │   ├── agents.js       # AI agents routes
│   │   ├── content.js      # Content creation routes
│   │   └── social.js       # Social media routes
│   ├── controllers/        # Business logic
│   ├── services/           # External service integrations
│   ├── middleware/         # Custom middleware
│   └── utils/              # Utility functions
├── Desktop/                # Advanced Python AI system
│   └── Gene1799ArtCorporatione/
│       ├── enhanced_system.py
│       ├── orchestrator.py
│       └── ...
├── logs/                   # Application logs
└── docs/                   # Documentation

```

### Available Scripts

```bash
npm start              # Start production server
npm run dev            # Start development server with nodemon
npm test               # Run tests
npm run lint           # Run ESLint
```

### Adding New Features

1. Create route in `backend/routes/`
2. Implement controller logic
3. Add service integration if needed
4. Register route in `server.js`
5. Update API documentation
6. Write tests

---

## 🔒 Security

The platform implements enterprise-grade security:

- **Helmet.js** - HTTP security headers
- **CORS** - Cross-origin resource sharing
- **Rate Limiting** - 100 requests/minute per IP
- **Speed Limiting** - Progressive slowdown
- **JWT Authentication** - Secure token-based auth
- **Input Validation** - All inputs sanitized
- **Error Handling** - Secure error responses
- **Logging** - Comprehensive audit trail

### Security Best Practices

- Never commit `.env` files
- Rotate API keys regularly
- Use strong JWT secrets
- Enable HTTPS in production
- Monitor logs for suspicious activity
- Keep dependencies updated

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Use ES6+ syntax
- Follow Airbnb style guide
- Write meaningful commit messages
- Add comments for complex logic
- Write tests for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

**GENE1799 ART CORPORATIONE**
- Fabio Amedeo Lo Presti
- Marco Antonio Saverio Mazzitelli

---

## 📞 Support

- **Email**: gene1799artcorporatione@gmail.com
- **GitHub Issues**: [Create an issue](https://github.com/gene7919/Gene1799ArtCorporatione/issues)
- **Telegram**: [@gene1799_art_bot](https://t.me/gene1799_art_bot)

---

## 🙏 Acknowledgments

- OpenAI for GPT-4 and DALL-E 3
- Anthropic for Claude
- Stability AI for image generation
- RunwayML for video synthesis
- The open-source community

---

<div align="center">

**Made with ❤️ by GENE1799 ART CORPORATIONE**

[![GitHub](https://img.shields.io/github/stars/gene7919/Gene1799ArtCorporatione?style=social)](https://github.com/gene7919/Gene1799ArtCorporatione)

</div>
