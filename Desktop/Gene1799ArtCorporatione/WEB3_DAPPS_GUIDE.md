# 🌐 Web3 dApps Integration Guide

## Complete DeFi & NFT Integration for GENE1799

**Version**: 2.0.0
**Date**: February 8, 2026
**Status**: ✅ Production Ready

---

## 📋 Overview

GENE1799 now integrates with major Web3 applications and DeFi protocols:

### Supported Platforms
- **Uniswap** - Token swaps with optimal routing
- **Aave** - Lending, borrowing, and flash loans
- **OpenSea** - NFT trading and listing
- **Zora** - NFT minting and galleries
- **Lido** - Ethereum staking (ETH → stETH)
- **Curve** - Stablecoin swaps with minimal slippage

### Supported Chains
- Ethereum (mainnet)
- Polygon (L2 scaling)
- Arbitrum (L2 rollup)
- Optimism (L2 rollup)
- Base (Coinbase L2)

---

## 🚀 Installation

### 1. Install Dependencies
```bash
npm install ethers axios
```

### 2. Environment Configuration
Create or update `.env` file:
```bash
# Network RPC URLs
ETH_RPC_URL=https://eth.llamarpc.com
POLYGON_RPC_URL=https://polygon-rpc.com
ARBITRUM_RPC_URL=https://arb1.arbitrum.io/rpc
OPTIMISM_RPC_URL=https://mainnet.optimism.io
BASE_RPC_URL=https://mainnet.base.org

# Wallet Configuration
WALLET_ADDRESS=0x...your_wallet_address...
PRIVATE_KEY=0x...your_private_key...

# API Keys
OPENSEA_API_KEY=your_opensea_api_key
COINGECKO_API_KEY=optional_coingecko_key
```

### 3. Import Module
```javascript
const Web3DAppsIntegration = require('./backend/src/web3-dapps-integration');

const web3dApps = new Web3DAppsIntegration({
  rpcUrls: {
    ethereum: process.env.ETH_RPC_URL,
    polygon: process.env.POLYGON_RPC_URL,
    // ... other chains
  },
  walletAddress: process.env.WALLET_ADDRESS,
  privateKey: process.env.PRIVATE_KEY
});
```

---

## 💡 Usage Examples

### Get Wallet Balances
```javascript
// Get ETH and token balances
const balances = await web3dApps.getWalletBalances('ethereum', [
  '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
  '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
]);

console.log(balances);
// Output:
// {
//   ETH: "1.5",
//   tokens: {
//     USDC: { address: "0x...", balance: "5000", decimals: 6 },
//     USDT: { address: "0x...", balance: "3000", decimals: 6 }
//   }
// }
```

### Uniswap Token Swap
```javascript
// Swap tokens with slippage protection
const swap = await web3dApps.uniswapSwap(
  'ethereum',
  '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
  '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
  '1000', // amount
  0.5 // slippage 0.5%
);

console.log(swap);
// Output: { success: true, txHash: "0x...", gasUsed: "123456" }
```

### Aave Deposit (Lending)
```javascript
// Deposit token to Aave for lending
const deposit = await web3dApps.aaveDeposit(
  'polygon',
  '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', // USDC on Polygon
  '1000'
);

console.log(deposit);
// Output: { success: true, txHash: "0x...", aToken: "aUSDC address" }
```

### Aave Borrow
```javascript
// Borrow tokens from Aave
const borrow = await web3dApps.aaveBorrow(
  'polygon',
  '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', // USDC
  '500', // amount
  2 // 2 = variable interest rate
);

console.log(borrow);
// Output: { success: true, txHash: "0x...", borrowed: true }
```

### Lido Staking
```javascript
// Stake ETH on Lido to get stETH
const stake = await web3dApps.lidoStakeETH('ethereum', '1.5');

console.log(stake);
// Output: {
//   success: true,
//   ethStaked: "1.5",
//   stETHReceived: "1.495",
//   txHash: "0x..."
// }
```

### OpenSea NFT Listing
```javascript
// List NFT on OpenSea
const listing = await web3dApps.openSeaListNFT(
  'ethereum',
  '0x...' // NFT contract address
  '123', // token ID
  '2.5' // price in ETH
);

console.log(listing);
// Output: { success: true, orderId: "0x...", price: "2.5" }
```

### Zora NFT Minting
```javascript
// Mint NFT on Zora
const mint = await web3dApps.zoraMintNFT(
  'ethereum',
  '0x...', // contract address
  '0x...', // recipient address
  {
    name: 'My NFT',
    description: 'Limited edition NFT',
    image: 'ipfs://...',
    attributes: []
  }
);

console.log(mint);
// Output: { success: true, txHash: "0x..." }
```

### Get Portfolio Value
```javascript
// Calculate total portfolio value in USD
const portfolio = await web3dApps.getPortfolioValue('ethereum', [
  '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
  '0xdAC17F958D2ee523a2206206994597C13D831ec7'  // USDT
]);

console.log(portfolio);
// Output: {
//   totalValue: "15234.56",
//   ethValue: "8500.00",
//   tokenValue: "6734.56",
//   balances: { ETH: "1.5", tokens: {...} }
// }
```

### Get Token Prices
```javascript
// Fetch current token prices from CoinGecko
const prices = await web3dApps.getTokenPrices([
  'ethereum',
  'USDC',
  'AAVE',
  'UNISWAP'
]);

console.log(prices);
// Output: { ethereum: 2450.50, USDC: 1.00, AAVE: 150.25, UNISWAP: 8.75 }
```

### Get Gas Prices
```javascript
// Get current gas prices for transaction
const gas = await web3dApps.getGasPrices('ethereum');

console.log(gas);
// Output: {
//   gasPrice: "45.2",
//   maxFeePerGas: "48.5",
//   maxPriorityFeePerGas: "3.2"
// }
```

### Estimate Gas Cost
```javascript
// Estimate transaction cost
const estimate = await web3dApps.estimateGas('ethereum', {
  to: '0x...',
  data: '0x...',
  value: ethers.parseEther('0.1')
});

console.log(estimate);
// Output: {
//   gasEstimate: "123456",
//   estimatedCostInEth: "0.0055",
//   estimatedCostInUsd: "13.48"
// }
```

---

## 🎨 Dashboard Features

Access the Web3 Dashboard at: `frontend/web3-dapps-dashboard.html`

### Features
- 💰 Real-time portfolio value
- 💳 Multi-token balance display
- 🔄 Uniswap token swaps
- 📈 Aave deposits and borrowing
- 🎯 Lido ETH staking
- 🎨 OpenSea NFT listing
- ⛓️ Multi-chain support
- ⚡ Gas price monitoring
- 📜 Transaction history

### Dashboard Sections
1. **Portfolio Overview** - Total value and asset breakdown
2. **Token Balances** - All holdings across chains
3. **Uniswap Swap** - Execute token swaps
4. **Aave Lending** - Deposit and borrow tokens
5. **Lido Staking** - Earn rewards on Ethereum
6. **OpenSea Listing** - List NFTs for sale
7. **Network Selection** - Switch between chains
8. **Gas Monitor** - Track transaction costs

---

## 🔐 Security Considerations

### Private Key Management
```javascript
// NEVER commit private keys!
// Use environment variables or secure key management

// Better: Use hardware wallet
const wallet = new ethers.HDNodeWallet(...);

// Even Better: Use Web3 provider (MetaMask, WalletConnect)
const signer = provider.getSigner();
```

### Transaction Validation
```javascript
// Always estimate gas before sending
const estimate = await web3dApps.estimateGas(chain, transaction);
console.log(`Estimated cost: ${estimate.estimatedCostInUsd}`);

// Use slippage protection
const slippage = 0.5; // max 0.5%
```

### Approval Limits
```javascript
// Set reasonable approval limits
const maxApproval = ethers.parseEther('100'); // Not MaxUint256
const tx = await token.approve(spender, maxApproval);
```

---

## 📊 Event Monitoring

Monitor dApp interactions with event listeners:

```javascript
// Listen for swaps
web3dApps.on('swap_completed', (data) => {
  console.log('Swap completed:', data);
  // data: { chain, tokenIn, tokenOut, amountIn, txHash, gasUsed }
});

// Listen for deposits
web3dApps.on('aave_deposit_completed', (data) => {
  console.log('Deposit completed:', data);
});

// Listen for staking
web3dApps.on('lido_stake_completed', (data) => {
  console.log('Staking completed:', data);
});

// Listen for errors
web3dApps.on('error', (error) => {
  console.error('Error:', error);
});
```

---

## ⛓️ Multi-Chain Configuration

### Supported RPC Endpoints

**Ethereum Mainnet**
```
https://eth.llamarpc.com
https://eth-mainnet.g.alchemy.com/v2/YOUR-KEY
https://mainnet.infura.io/v3/YOUR-KEY
```

**Polygon**
```
https://polygon-rpc.com
https://polygon-mainnet.g.alchemy.com/v2/YOUR-KEY
```

**Arbitrum**
```
https://arb1.arbitrum.io/rpc
https://arbitrum-mainnet.infura.io/v3/YOUR-KEY
```

**Optimism**
```
https://mainnet.optimism.io
https://opt-mainnet.g.alchemy.com/v2/YOUR-KEY
```

**Base**
```
https://mainnet.base.org
https://base-mainnet.g.alchemy.com/v2/YOUR-KEY
```

---

## 🔧 Advanced Configuration

### Custom Provider
```javascript
const customProvider = new ethers.JsonRpcProvider(
  'https://your-rpc-endpoint.com'
);

const web3dApps = new Web3DAppsIntegration({
  providers: {
    ethereum: customProvider
  }
});
```

### Batch Operations
```javascript
// Execute multiple operations
const operations = await Promise.all([
  web3dApps.getTokenPrices(['ethereum', 'USDC']),
  web3dApps.getGasPrices('ethereum'),
  web3dApps.getPortfolioValue('ethereum', [])
]);
```

### Gas Optimization
```javascript
// Check gas prices and wait for lower gas
async function executeWithOptimalGas() {
  let gasPrice = await web3dApps.getGasPrices('ethereum');

  while (parseFloat(gasPrice.gasPrice) > 50) {
    console.log('Gas too high, waiting...');
    await new Promise(r => setTimeout(r, 30000));
    gasPrice = await web3dApps.getGasPrices('ethereum');
  }

  // Execute transaction with good gas price
}
```

---

## 📚 Smart Contract Integration

### Token Interactions
```javascript
const ERC20_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'function approve(address spender, uint256 amount) returns (bool)',
  'function decimals() view returns (uint8)'
];

const token = new ethers.Contract(tokenAddress, ERC20_ABI, signer);
```

### DeFi Pool Interactions
```javascript
const POOL_ABI = [
  'function deposit(address asset, uint256 amount)',
  'function withdraw(address asset, uint256 amount)',
  'function borrow(address asset, uint256 amount)'
];

const pool = new ethers.Contract(poolAddress, POOL_ABI, signer);
```

---

## 🧪 Testing

### Test Uniswap Swap
```javascript
async function testUniswapSwap() {
  try {
    const result = await web3dApps.uniswapSwap(
      'ethereum',
      '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
      '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT
      '100',
      0.5
    );

    console.log('✓ Uniswap swap successful');
    return result;
  } catch (error) {
    console.error('✗ Uniswap swap failed:', error.message);
  }
}
```

### Test Portfolio Analysis
```javascript
async function testPortfolio() {
  try {
    const portfolio = await web3dApps.getPortfolioValue('ethereum', []);
    console.log('✓ Portfolio value:', portfolio.totalValue);
    return portfolio;
  } catch (error) {
    console.error('✗ Portfolio analysis failed:', error.message);
  }
}
```

---

## 📞 Support

### Documentation
- [Uniswap Docs](https://docs.uniswap.org)
- [Aave Docs](https://docs.aave.com)
- [Lido Docs](https://docs.lido.fi)
- [OpenSea Docs](https://docs.opensea.io)
- [ethers.js Docs](https://docs.ethers.org)

### Community
- Telegram: @gene1799_art_bot
- Email: gene1799artcorporatione@gmail.com
- GitHub: github.com/gene7919/Gene1799ArtCorporatione

---

## 🎉 Next Steps

1. **Configure Environment**: Set up RPC URLs and wallet
2. **Test Locally**: Run test functions to verify setup
3. **Deploy Dashboard**: Access Web3 dashboard interface
4. **Monitor Transactions**: Track operations in real-time
5. **Scale Up**: Add more tokens and DeFi protocols

---

**Version**: 2.0.0 | **Status**: ✅ Production Ready | **Date**: February 8, 2026
