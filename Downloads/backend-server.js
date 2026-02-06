/**
 * Gene1799 Art Corporatione - Backend API
 * Handles: airdrop claims, token info, NFT verification
 * Deploy on Render.com as Web Service
 */

const http = require('http');
const { ethers } = require('ethers');

const PORT = process.env.PORT || 3000;
const CORS_ORIGIN = process.env.CORS_ORIGIN || 'https://gene1799artcorporatione.mom';
const BASE_RPC = process.env.BASE_RPC_URL || 'https://mainnet.base.org';
const TOKEN_CONTRACT = process.env.TOKEN_CONTRACT || '0x63800f370b04ce132333c05d811663b80cec788e';

const provider = new ethers.providers.JsonRpcProvider(BASE_RPC);
const tokenAbi = [
  'function balanceOf(address) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)',
  'function name() view returns (string)',
  'function totalSupply() view returns (uint256)'
];
const tokenContract = new ethers.Contract(TOKEN_CONTRACT, tokenAbi, provider);

// In-memory claim tracking (use a database in production)
const claims = new Map();

// Rate limiting
const rateLimits = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const RATE_LIMIT_MAX = 30; // requests per window

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = rateLimits.get(ip) || { count: 0, resetAt: now + RATE_LIMIT_WINDOW };
  
  if (now > entry.resetAt) {
    entry.count = 0;
    entry.resetAt = now + RATE_LIMIT_WINDOW;
  }
  
  entry.count++;
  rateLimits.set(ip, entry);
  
  return entry.count <= RATE_LIMIT_MAX;
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
}

function sendJson(res, statusCode, data) {
  setCorsHeaders(res);
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function getBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
      if (body.length > 1e6) { req.destroy(); reject(new Error('Too large')); }
    });
    req.on('end', () => {
      try { resolve(JSON.parse(body)); } catch { reject(new Error('Invalid JSON')); }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  
  // Rate limiting
  if (!checkRateLimit(ip)) {
    return sendJson(res, 429, { error: 'Too many requests' });
  }

  // CORS preflight
  if (req.method === 'OPTIONS') {
    setCorsHeaders(res);
    res.writeHead(204);
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;

  try {
    // Health check
    if (path === '/api/health') {
      return sendJson(res, 200, { status: 'ok', service: 'gene1799-api', timestamp: new Date().toISOString() });
    }

    // Token info
    if (path === '/api/token' && req.method === 'GET') {
      const [name, symbol, decimals, totalSupply] = await Promise.all([
        tokenContract.name(), tokenContract.symbol(),
        tokenContract.decimals(), tokenContract.totalSupply()
      ]);
      return sendJson(res, 200, {
        name, symbol, decimals,
        totalSupply: ethers.utils.formatUnits(totalSupply, decimals),
        contract: TOKEN_CONTRACT,
        network: 'Base', chainId: 8453
      });
    }

    // Balance check
    if (path === '/api/balance' && req.method === 'GET') {
      const address = url.searchParams.get('address');
      if (!address || !ethers.utils.isAddress(address)) {
        return sendJson(res, 400, { error: 'Invalid address' });
      }
      const balance = await tokenContract.balanceOf(address);
      const decimals = await tokenContract.decimals();
      return sendJson(res, 200, {
        address, balance: ethers.utils.formatUnits(balance, decimals), symbol: '$GENE1799'
      });
    }

    // Claim airdrop
    if (path === '/api/claim-airdrop' && req.method === 'POST') {
      const body = await getBody(req);
      const { address, nftCount, collections } = body;

      if (!address || !ethers.utils.isAddress(address)) {
        return sendJson(res, 400, { error: 'Invalid wallet address' });
      }
      if (!nftCount || nftCount < 1) {
        return sendJson(res, 400, { error: 'Must own at least 1 Gene1799 NFT' });
      }
      if (claims.has(address.toLowerCase())) {
        return sendJson(res, 409, { error: 'Airdrop already claimed for this address' });
      }

      const amount = nftCount * 500;
      claims.set(address.toLowerCase(), {
        address, nftCount, collections, amount,
        claimedAt: new Date().toISOString(), status: 'pending'
      });

      return sendJson(res, 200, {
        success: true, amount,
        message: `${amount} $GENE1799 in coda per distribuzione!`
      });
    }

    // 404
    sendJson(res, 404, { error: 'Not found' });
  } catch (error) {
    console.error('API error:', error);
    sendJson(res, 500, { error: 'Internal server error' });
  }
});

server.listen(PORT, () => {
  console.log(`
████████████████████████████████████████████████████████
█ GENE1799 API SERVER                                  █
█ Running on port ${PORT}                                  █
████████████████████████████████████████████████████████
  `);
});
