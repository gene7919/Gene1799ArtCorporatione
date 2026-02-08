/**
 * GENE1799 Web3 dApps Integration
 * Multi-chain, multi-dApp support for NFTs, trading, and DeFi
 *
 * Supported:
 * - Uniswap (Token Swap, Liquidity Pools)
 * - Aave (Lending, Borrowing, Flash Loans)
 * - OpenSea (NFT Trading)
 * - Zora (NFT Minting & Trading)
 * - Lido (Staking)
 * - Curve (Stablecoin Swaps)
 *
 * Chains: Ethereum, Polygon, Arbitrum, Optimism, Base
 */

const { ethers } = require('ethers');
const EventEmitter = require('events');
const axios = require('axios');

class Web3DAppsIntegration extends EventEmitter {
  constructor(config = {}) {
    super();

    this.config = {
      rpcUrls: {
        ethereum: process.env.ETH_RPC_URL || 'https://eth.llamarpc.com',
        polygon: process.env.POLYGON_RPC_URL || 'https://polygon-rpc.com',
        arbitrum: process.env.ARBITRUM_RPC_URL || 'https://arb1.arbitrum.io/rpc',
        optimism: process.env.OPTIMISM_RPC_URL || 'https://mainnet.optimism.io',
        base: process.env.BASE_RPC_URL || 'https://mainnet.base.org'
      },
      walletAddress: process.env.WALLET_ADDRESS,
      privateKey: process.env.PRIVATE_KEY,
      ...config
    };

    // Initialize providers for each chain
    this.providers = {
      ethereum: new ethers.JsonRpcProvider(this.config.rpcUrls.ethereum),
      polygon: new ethers.JsonRpcProvider(this.config.rpcUrls.polygon),
      arbitrum: new ethers.JsonRpcProvider(this.config.rpcUrls.arbitrum),
      optimism: new ethers.JsonRpcProvider(this.config.rpcUrls.optimism),
      base: new ethers.JsonRpcProvider(this.config.rpcUrls.base)
    };

    // Initialize signers for each chain
    this.signers = {};
    if (this.config.privateKey) {
      Object.keys(this.providers).forEach(chain => {
        this.signers[chain] = new ethers.Wallet(this.config.privateKey, this.providers[chain]);
      });
    }

    // Cache for contract ABIs
    this.abiCache = {};

    // Tracking gas prices
    this.gasPrices = {};
  }

  /**
   * Get wallet balance across multiple tokens
   */
  async getWalletBalances(chain = 'ethereum', tokenAddresses = []) {
    try {
      const provider = this.providers[chain];
      const wallet = this.config.walletAddress;

      // ETH balance
      const ethBalance = await provider.getBalance(wallet);

      const balances = {
        ETH: ethers.formatEther(ethBalance),
        tokens: {}
      };

      // Token balances
      if (tokenAddresses.length > 0) {
        const erc20ABI = [
          'function balanceOf(address owner) public view returns (uint256)',
          'function decimals() public view returns (uint8)',
          'function symbol() public view returns (string)'
        ];

        for (const tokenAddress of tokenAddresses) {
          try {
            const contract = new ethers.Contract(tokenAddress, erc20ABI, provider);
            const balance = await contract.balanceOf(wallet);
            const decimals = await contract.decimals();
            const symbol = await contract.symbol();

            balances.tokens[symbol] = {
              address: tokenAddress,
              balance: ethers.formatUnits(balance, decimals),
              decimals
            };
          } catch (error) {
            console.error(`Error fetching balance for ${tokenAddress}:`, error.message);
          }
        }
      }

      return balances;
    } catch (error) {
      this.emit('error', { type: 'balance_fetch_error', error: error.message });
      throw error;
    }
  }

  /**
   * Uniswap Integration - Token Swap
   */
  async uniswapSwap(chain = 'ethereum', tokenIn, tokenOut, amountIn, slippage = 0.5) {
    try {
      const UNISWAP_ROUTER = {
        ethereum: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        polygon: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        arbitrum: '0xE592427A0AEce92De3Edee1F18E0157C05861564'
      }[chain];

      const UNISWAP_ABI = [
        'function exactInputSingle((bytes path, address recipient, uint256 deadline, uint256 amountIn, uint256 amountOutMinimum)) external payable returns (uint256 amountOut)',
        'function exactOutputSingle((bytes path, address recipient, uint256 deadline, uint256 amountOut, uint256 amountInMaximum)) external payable returns (uint256 amountIn)'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const router = new ethers.Contract(UNISWAP_ROUTER, UNISWAP_ABI, signer);

      // Encode path
      const path = ethers.solidityPacked(
        ['address', 'uint24', 'address'],
        [tokenIn, 3000, tokenOut] // 3000 = 0.3% fee tier
      );

      // Calculate minimum amount with slippage
      const minAmountOut = ethers.parseEther(amountIn) * (1 - slippage / 100);

      const params = {
        path: path,
        recipient: signer.address,
        deadline: Math.floor(Date.now() / 1000) + 60 * 20, // 20 minutes
        amountIn: ethers.parseEther(amountIn),
        amountOutMinimum: minAmountOut
      };

      const tx = await router.exactInputSingle(params);
      const receipt = await tx.wait();

      this.emit('swap_completed', {
        chain,
        tokenIn,
        tokenOut,
        amountIn,
        txHash: receipt.hash,
        gasUsed: receipt.gasUsed.toString()
      });

      return {
        success: true,
        txHash: receipt.hash,
        gasUsed: receipt.gasUsed.toString()
      };
    } catch (error) {
      this.emit('error', { type: 'uniswap_swap_error', error: error.message });
      throw error;
    }
  }

  /**
   * Aave Integration - Deposit assets
   */
  async aaveDeposit(chain = 'ethereum', tokenAddress, amount) {
    try {
      const AAVE_POOL = {
        ethereum: '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9',
        polygon: '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9',
        arbitrum: '0x794a61358D6845594F94dc1DB02A252b5b4814aD'
      }[chain];

      const AAVE_POOL_ABI = [
        'function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const pool = new ethers.Contract(AAVE_POOL, AAVE_POOL_ABI, signer);

      // Approve token first
      await this.approveToken(chain, tokenAddress, AAVE_POOL, amount);

      const tx = await pool.deposit(
        tokenAddress,
        ethers.parseEther(amount),
        signer.address,
        0 // referral code
      );

      const receipt = await tx.wait();

      this.emit('aave_deposit_completed', {
        chain,
        token: tokenAddress,
        amount,
        txHash: receipt.hash
      });

      return {
        success: true,
        txHash: receipt.hash,
        amount,
        aToken: `a${tokenAddress}` // aToken address (simplified)
      };
    } catch (error) {
      this.emit('error', { type: 'aave_deposit_error', error: error.message });
      throw error;
    }
  }

  /**
   * Aave Integration - Borrow assets
   */
  async aaveBorrow(chain = 'ethereum', tokenAddress, amount, interestRateMode = 2) {
    try {
      const AAVE_POOL = {
        ethereum: '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9',
        polygon: '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9',
        arbitrum: '0x794a61358D6845594F94dc1DB02A252b5b4814aD'
      }[chain];

      const AAVE_POOL_ABI = [
        'function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const pool = new ethers.Contract(AAVE_POOL, AAVE_POOL_ABI, signer);

      const tx = await pool.borrow(
        tokenAddress,
        ethers.parseEther(amount),
        interestRateMode, // 2 = variable rate
        0, // referral code
        signer.address
      );

      const receipt = await tx.wait();

      this.emit('aave_borrow_completed', {
        chain,
        token: tokenAddress,
        amount,
        txHash: receipt.hash,
        interestRateMode
      });

      return {
        success: true,
        txHash: receipt.hash,
        amount,
        borrowed: true
      };
    } catch (error) {
      this.emit('error', { type: 'aave_borrow_error', error: error.message });
      throw error;
    }
  }

  /**
   * OpenSea - List NFT for sale
   */
  async openSeaListNFT(chain = 'ethereum', contractAddress, tokenId, priceInEther) {
    try {
      const OPENSEA_API = 'https://api.opensea.io/v2';

      const listingPayload = {
        asset_contract_address: contractAddress,
        token_id: tokenId,
        price_per_item: priceInEther,
        duration: 604800, // 1 week
        listing_type: 'fixed'
      };

      const response = await axios.post(
        `${OPENSEA_API}/orders/ethereum/post/listings`,
        listingPayload,
        {
          headers: {
            'X-API-KEY': process.env.OPENSEA_API_KEY,
            'Content-Type': 'application/json'
          }
        }
      );

      this.emit('opensea_listing_created', {
        contractAddress,
        tokenId,
        price: priceInEther,
        orderId: response.data.order_hash
      });

      return {
        success: true,
        orderId: response.data.order_hash,
        price: priceInEther,
        expiresAt: new Date(Date.now() + 604800 * 1000)
      };
    } catch (error) {
      this.emit('error', { type: 'opensea_listing_error', error: error.message });
      throw error;
    }
  }

  /**
   * Zora - Mint NFT
   */
  async zoraMintNFT(chain = 'ethereum', contractAddress, recipientAddress, metadata) {
    try {
      const ZORA_MINTER_ABI = [
        'function mint(address to, string memory uri) external returns (uint256)',
        'function mintWithSignature((address from, address to, uint256 tokenId, string uri, bytes signature)) external'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const contract = new ethers.Contract(contractAddress, ZORA_MINTER_ABI, signer);

      const tx = await contract.mint(recipientAddress, JSON.stringify(metadata));
      const receipt = await tx.wait();

      this.emit('zora_mint_completed', {
        chain,
        contractAddress,
        tokenId: receipt.events?.[0]?.args?.tokenId,
        txHash: receipt.hash
      });

      return {
        success: true,
        txHash: receipt.hash,
        metadata
      };
    } catch (error) {
      this.emit('error', { type: 'zora_mint_error', error: error.message });
      throw error;
    }
  }

  /**
   * Lido - Stake ETH
   */
  async lidoStakeETH(chain = 'ethereum', amountInEther) {
    try {
      const LIDO_ADDRESS = '0xae7ab96520DE3A18E5e111B5eaAFc337671cBC4f';
      const LIDO_ABI = [
        'function submit(address referral) external payable returns (uint256)',
        'function balanceOf(address account) public view returns (uint256)'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const lido = new ethers.Contract(LIDO_ADDRESS, LIDO_ABI, signer);

      const tx = await lido.submit(ethers.ZeroAddress, {
        value: ethers.parseEther(amountInEther)
      });

      const receipt = await tx.wait();

      // Get stETH balance
      const stETHBalance = await lido.balanceOf(signer.address);

      this.emit('lido_stake_completed', {
        chain,
        ethStaked: amountInEther,
        stETHReceived: ethers.formatEther(stETHBalance),
        txHash: receipt.hash
      });

      return {
        success: true,
        ethStaked: amountInEther,
        stETHReceived: ethers.formatEther(stETHBalance),
        txHash: receipt.hash
      };
    } catch (error) {
      this.emit('error', { type: 'lido_stake_error', error: error.message });
      throw error;
    }
  }

  /**
   * Curve - Stablecoin swap
   */
  async curveSwapStablecoin(chain = 'ethereum', poolAddress, tokenInIndex, tokenOutIndex, amountIn, minAmountOut) {
    try {
      const CURVE_ABI = [
        'function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256)'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const pool = new ethers.Contract(poolAddress, CURVE_ABI, signer);

      const tx = await pool.exchange(
        tokenInIndex,
        tokenOutIndex,
        ethers.parseEther(amountIn),
        ethers.parseEther(minAmountOut)
      );

      const receipt = await tx.wait();

      this.emit('curve_swap_completed', {
        chain,
        tokenInIndex,
        tokenOutIndex,
        amountIn,
        txHash: receipt.hash
      });

      return {
        success: true,
        txHash: receipt.hash,
        amountIn,
        minAmountOut
      };
    } catch (error) {
      this.emit('error', { type: 'curve_swap_error', error: error.message });
      throw error;
    }
  }

  /**
   * Approve ERC20 token for spending
   */
  async approveToken(chain, tokenAddress, spenderAddress, amount) {
    try {
      const ERC20_ABI = [
        'function approve(address spender, uint256 amount) external returns (bool)'
      ];

      const signer = this.signers[chain];
      if (!signer) throw new Error(`No signer available for chain: ${chain}`);

      const token = new ethers.Contract(tokenAddress, ERC20_ABI, signer);
      const maxApproval = ethers.MaxUint256;

      const tx = await token.approve(spenderAddress, maxApproval);
      const receipt = await tx.wait();

      this.emit('token_approved', {
        chain,
        token: tokenAddress,
        spender: spenderAddress,
        txHash: receipt.hash
      });

      return {
        success: true,
        txHash: receipt.hash
      };
    } catch (error) {
      this.emit('error', { type: 'token_approval_error', error: error.message });
      throw error;
    }
  }

  /**
   * Get token prices from multiple sources
   */
  async getTokenPrices(tokens = []) {
    try {
      const prices = {};

      // CoinGecko API (free, no key required)
      const coingeckoIds = {
        'ethereum': 'ethereum',
        'usdc': 'usd-coin',
        'usdt': 'tether',
        'dai': 'dai',
        'aave': 'aave',
        'uniswap': 'uniswap'
      };

      for (const token of tokens) {
        const coingeckoId = coingeckoIds[token.toLowerCase()];
        if (!coingeckoId) continue;

        const response = await axios.get(
          `https://api.coingecko.com/api/v3/simple/price?ids=${coingeckoId}&vs_currencies=usd`
        );

        prices[token] = response.data[coingeckoId]?.usd || 0;
      }

      return prices;
    } catch (error) {
      this.emit('error', { type: 'price_fetch_error', error: error.message });
      return {};
    }
  }

  /**
   * Get current gas prices
   */
  async getGasPrices(chain = 'ethereum') {
    try {
      const provider = this.providers[chain];
      const feeData = await provider.getFeeData();

      const gasPrices = {
        gasPrice: ethers.formatUnits(feeData.gasPrice, 'gwei'),
        maxFeePerGas: ethers.formatUnits(feeData.maxFeePerGas, 'gwei'),
        maxPriorityFeePerGas: ethers.formatUnits(feeData.maxPriorityFeePerGas, 'gwei')
      };

      this.gasPrices[chain] = gasPrices;
      return gasPrices;
    } catch (error) {
      this.emit('error', { type: 'gas_price_error', error: error.message });
      throw error;
    }
  }

  /**
   * Get portfolio value across all assets
   */
  async getPortfolioValue(chain = 'ethereum', tokenAddresses = []) {
    try {
      const balances = await this.getWalletBalances(chain, tokenAddresses);
      const prices = await this.getTokenPrices(
        ['ethereum', ...tokenAddresses.map(a => a.toLowerCase())]
      );

      let totalValue = parseFloat(balances.ETH) * (prices['ethereum'] || 0);

      for (const [symbol, data] of Object.entries(balances.tokens)) {
        const price = prices[symbol.toLowerCase()] || 0;
        totalValue += parseFloat(data.balance) * price;
      }

      this.emit('portfolio_analyzed', {
        chain,
        totalValue: totalValue.toFixed(2),
        ethValue: (parseFloat(balances.ETH) * (prices['ethereum'] || 0)).toFixed(2),
        tokenCount: Object.keys(balances.tokens).length
      });

      return {
        totalValue: totalValue.toFixed(2),
        tokenValue: totalValue - (parseFloat(balances.ETH) * (prices['ethereum'] || 0)),
        ethValue: (parseFloat(balances.ETH) * (prices['ethereum'] || 0)).toFixed(2),
        balances
      };
    } catch (error) {
      this.emit('error', { type: 'portfolio_analysis_error', error: error.message });
      throw error;
    }
  }

  /**
   * Simulate transaction and estimate gas
   */
  async estimateGas(chain = 'ethereum', transaction) {
    try {
      const provider = this.providers[chain];
      const gasEstimate = await provider.estimateGas(transaction);
      const feeData = await provider.getFeeData();

      const estimatedCost = ethers.formatEther(
        gasEstimate * feeData.gasPrice
      );

      return {
        gasEstimate: gasEstimate.toString(),
        estimatedCostInEth: estimatedCost,
        estimatedCostInUsd: (parseFloat(estimatedCost) * (await this.getTokenPrices(['ethereum']))['ethereum']).toFixed(2)
      };
    } catch (error) {
      this.emit('error', { type: 'gas_estimation_error', error: error.message });
      throw error;
    }
  }
}

module.exports = Web3DAppsIntegration;
