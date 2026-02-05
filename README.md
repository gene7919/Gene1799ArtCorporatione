# GENE1799 ART CORPORATIONE v9.0

## Quick Start

1. **Start Server**:
   - Run \LAUNCHER.bat\ and select [1]
   - Or: \cd backend && npm start\

2. **Test API**:
   \\\
   curl http://localhost:3000/api/health
   \\\

3. **Create Agents**:
   \\\
   curl -X POST http://localhost:3000/api/agents/batch-create -H "Content-Type: application/json" -d "{\"count\":10}"
   \\\

## Endpoints

- **Health**: \GET /api/health\
- **Agents**: \GET /api/agents\
- **Batch Create**: \POST /api/agents/batch-create\
- **NFTs**: \GET /api/nft\
- **Metrics**: \GET /api/metrics\

## Features

✅ 500 AI Agents preloaded
✅ DDoS Protection + Rate Limiting
✅ IP Whitelisting (74.220.48/56.0/24)
✅ Batch Operations
✅ WebSocket Real-time
✅ NFT Marketplace
✅ Crypto Trading

## Security

- Helmet Security Headers
- Express Rate Limiting
- IP Whitelist
- CORS Protection
- Cloudflare Ready

## Authors

- Marco Antonio Saverio Mazzitelli
- Fabio Amedeo Lo Presti (Arthemis Ludovici)

---

**Version**: 9.0.0
**Port**: 3000
**Installation**: 2026-02-05 02:38:54
