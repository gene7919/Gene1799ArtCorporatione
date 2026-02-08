# 🌐 Web3 Integration with Azure Configuration

## Complete Setup for GENE1799 Web3 Services on Azure

**Date**: February 8, 2026
**Status**: ✅ Ready for Production

---

## 🏗️ Azure Configuration for Web3 Applications

### Environment Variables in App Service

Set these in Azure App Service Configuration:

```
# Web3 RPC Endpoints
ETH_RPC_URL=https://eth.llamarpc.com
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC_URL=https://mainnet.optimism.io
BASE_RPC_URL=https://mainnet.base.org

# Wallet Configuration (encrypted in Key Vault)
WALLET_ADDRESS=0x...
PRIVATE_KEY=<stored in Key Vault>

# API Keys (encrypted in Key Vault)
OPENSEA_API_KEY=<your_key>
COINGECKO_API_KEY=<your_key>

# Database
DATABASE_HOST=gene1799-db.postgres.database.azure.com
DATABASE_NAME=gene1799db
DATABASE_USER=gene1799admin
DATABASE_PASSWORD=<from Key Vault>

# Cache
REDIS_HOST=gene1799-cache.redis.cache.windows.net
REDIS_PASSWORD=<from Key Vault>

# Application
NODE_ENV=production
LOG_LEVEL=info
SECURE_COOKIES=true
```

---

## 🔐 Azure Key Vault Setup

Store sensitive credentials securely:

```bash
# Create Key Vault
az keyvault create \
  --resource-group gene1799-rg \
  --name gene1799-vault \
  --location westeurope

# Store secrets
az keyvault secret set \
  --vault-name gene1799-vault \
  --name PrivateKey \
  --value "0x..."

az keyvault secret set \
  --vault-name gene1799-vault \
  --name OpenSeaApiKey \
  --value "your-key"

az keyvault secret set \
  --vault-name gene1799-vault \
  --name DatabasePassword \
  --value "your-password"

# Grant App Service access to Key Vault
az keyvault set-policy \
  --name gene1799-vault \
  --object-id <app-service-principal-id> \
  --secret-permissions get list
```

---

## 🚀 Deployment Steps

### 1. Create App Service
```bash
# Create App Service Plan
az appservice plan create \
  --name gene1799-plan \
  --resource-group gene1799-rg \
  --sku B2 \
  --is-linux

# Create App Service
az webapp create \
  --resource-group gene1799-rg \
  --plan gene1799-plan \
  --name gene1799-web3-app \
  --runtime "node|18-lts"
```

### 2. Configure Web3 Database

Create PostgreSQL schema for tracking transactions:

```sql
-- Create transactions table
CREATE TABLE web3_transactions (
  id SERIAL PRIMARY KEY,
  tx_hash VARCHAR(255) UNIQUE NOT NULL,
  from_address VARCHAR(255) NOT NULL,
  to_address VARCHAR(255),
  amount DECIMAL(20, 8),
  token_symbol VARCHAR(20),
  transaction_type VARCHAR(50),
  chain VARCHAR(50),
  status VARCHAR(20),
  gas_used BIGINT,
  block_number BIGINT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create wallet table
CREATE TABLE web3_wallets (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(255) UNIQUE NOT NULL,
  balance_eth DECIMAL(20, 18),
  total_usd_value DECIMAL(20, 2),
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create dApp interactions table
CREATE TABLE dapp_interactions (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(255) NOT NULL,
  dapp_name VARCHAR(50),
  action VARCHAR(50),
  amount DECIMAL(20, 8),
  token VARCHAR(255),
  chain VARCHAR(50),
  tx_hash VARCHAR(255),
  success BOOLEAN,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_transactions_chain ON web3_transactions(chain);
CREATE INDEX idx_transactions_status ON web3_transactions(status);
CREATE INDEX idx_dapp_wallet ON dapp_interactions(wallet_address);
```

### 3. Deploy Code

```bash
# Push code to Git
git push origin main

# Azure App Service will auto-deploy
# OR manually deploy with:
az webapp up \
  --resource-group gene1799-rg \
  --name gene1799-web3-app
```

### 4. Configure Custom Domain

```bash
# Add custom domain
az webapp config hostname add \
  --resource-group gene1799-rg \
  --webapp-name gene1799-web3-app \
  --hostname your-domain.com

# Configure SSL certificate
az webapp config ssl bind \
  --resource-group gene1799-rg \
  --name gene1799-web3-app \
  --certificate-thumbprint <thumbprint>
```

---

## 📊 Monitoring Web3 Operations

### Application Insights Queries

Monitor Web3 dApp interactions:

```kusto
// Get all transactions
customEvents
| where name == "web3_transaction"
| summarize count() by tostring(customDimensions.transaction_type)

// Track Uniswap swaps
customEvents
| where name == "uniswap_swap_completed"
| extend amountIn = toreal(customDimensions.amountIn)
| summarize total_volume = sum(amountIn) by bin(timestamp, 1h)

// Aave deposits and borrows
customEvents
| where name in ("aave_deposit_completed", "aave_borrow_completed")
| extend amount = toreal(customDimensions.amount)
| summarize deposits = sum(iff(name == "aave_deposit_completed", amount, 0)),
            borrows = sum(iff(name == "aave_borrow_completed", amount, 0))

// Error tracking
customEvents
| where name == "error" and customDimensions.type contains "web3"
| summarize error_count = count() by customDimensions.type
```

### Alert Rules

Set up alerts for important events:

```bash
# Alert on high transaction failures
az monitor metrics alert create \
  --name HighWeb3Errors \
  --resource-group gene1799-rg \
  --scopes /subscriptions/{subscription}/resourceGroups/gene1799-rg/providers/microsoft.insights/components/gene1799-insights \
  --condition "avg (requests/duration) > 5000" \
  --window-size 5m

# Alert on gas price spikes
az monitor metrics alert create \
  --name HighGasPrice \
  --resource-group gene1799-rg \
  --condition "avg custom:gas_price > 100"
```

---

## 💾 Backup and disaster recovery

### Database Backups

```bash
# Enable automatic backups (7 days retention)
az postgres server update \
  --resource-group gene1799-rg \
  --name gene1799-db \
  --backup-retention 7 \
  --geo-redundant-backup Enabled

# Create manual backup
az postgres server backup create \
  --resource-group gene1799-rg \
  --server-name gene1799-db \
  --backup-name manual-backup-$(date +%s)
```

### Disaster Recovery Plan

```
1. Database failover (geo-redundancy enabled)
2. App Service regional failover (Traffic Manager)
3. Redis Cache replication
4. Storage Account replication
5. Key Vault replication
```

---

## 🔧 Monitoring Checklist

- [ ] Application Insights connected
- [ ] Logs streaming to Log Analytics
- [ ] Alerts configured for errors
- [ ] Database backups scheduled
- [ ] Redis caching operational
- [ ] Key Vault access verified
- [ ] SSL certificate valid
- [ ] Custom domain configured
- [ ] Auto-scaling rules active
- [ ] Performance baseline established

---

## 📈 Performance Optimization

### Cache Strategy

```javascript
// Cache token prices (1 hour)
const CACHE_DURATION = 3600000;
const priceCache = new Map();

async function getCachedTokenPrice(symbol) {
  const cached = priceCache.get(symbol);
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.price;
  }

  const price = await fetchTokenPrice(symbol);
  priceCache.set(symbol, { price, timestamp: Date.now() });
  return price;
}
```

### Database Connection Pooling

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Use pool for queries
pool.query('SELECT * FROM web3_wallets WHERE wallet_address = $1', [address]);
```

### API Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const web3Limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many Web3 requests',
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/api/dapps/swap', web3Limiter, (req, res) => {
  // Handle request
});
```

---

## 🧪 Testing Web3 Integration

### Unit Tests

```javascript
const { expect } = require('chai');
const Web3DAppsIntegration = require('./web3-dapps-integration');

describe('Web3 dApps Integration', () => {
  let web3;

  before(() => {
    web3 = new Web3DAppsIntegration({
      rpcUrls: { ethereum: process.env.ETH_RPC_URL }
    });
  });

  it('should get wallet balances', async () => {
    const balances = await web3.getWalletBalances('ethereum', []);
    expect(balances).to.have.property('ETH');
    expect(balances.ETH).to.be.a('string');
  });

  it('should get token prices', async () => {
    const prices = await web3.getTokenPrices(['ethereum', 'USDC']);
    expect(prices).to.have.property('ethereum');
    expect(prices.ethereum).to.be.a('number');
  });

  it('should estimate gas', async () => {
    const transaction = { to: '0x...', value: '1000000000000000000' };
    const estimate = await web3.estimateGas('ethereum', transaction);
    expect(estimate).to.have.property('estimatedCostInEth');
  });
});
```

### Integration Tests

```javascript
describe('Web3 Operations', () => {
  it('should execute Uniswap swap', async function() {
    this.timeout(30000);
    const result = await web3.uniswapSwap(
      'ethereum',
      USDC_ADDRESS,
      USDT_ADDRESS,
      '10',
      0.5
    );
    expect(result.success).to.be.true;
  });

  it('should deposit to Aave', async function() {
    this.timeout(30000);
    const result = await web3.aaveDeposit('ethereum', USDC_ADDRESS, '100');
    expect(result.success).to.be.true;
  });
});
```

---

## 📞 Support & Resources

### Documentation
- [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure PostgreSQL](https://docs.microsoft.com/en-us/azure/postgresql/)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Web3 dApps Guide](./WEB3_DAPPS_GUIDE.md)

### Monitoring
- Azure Portal: https://portal.azure.com
- Application Insights: Resource → Logs
- Key Vault: Settings → Secrets

---

**Version**: 2.0.0 | **Date**: February 8, 2026 | **Status**: ✅ Production Ready
