/**
 * GENE1799 Web3 Integration Module
 * Handles MetaMask wallet connection, token interactions, and NFT integration
 * Integrates with Base network and $GENE1799 token contract
 */

class Gene1799Web3Integration {
  constructor(config = {}) {
    this.provider = null;
    this.signer = null;
    this.userAddress = null;
    this.tokenDecimals = 18;
    this.chainId = 8453; // Base mainnet

    this.config = {
      rpcUrl: config.rpcUrl || 'https://mainnet.base.org',
      tokenContract: config.tokenContract || '0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0',
      chainName: 'Base',
      ...config
    };

    this.ethers = window.ethers;
    if (!this.ethers) {
      console.error('ethers.js not loaded. Include: <script src="https://cdn.ethers.io/lib/ethers-5.7.umd.min.js"></script>');
    }
  }

  /**
   * Connect to MetaMask wallet
   */
  async connectWallet() {
    try {
      if (!window.ethereum) {
        throw new Error('MetaMask not detected. Install MetaMask extension.');
      }

      // Request account access
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      this.userAddress = accounts[0];

      // Setup provider and signer
      const provider = new this.ethers.providers.Web3Provider(window.ethereum);
      this.provider = provider;
      this.signer = provider.getSigner();

      // Verify network
      const network = await provider.getNetwork();
      if (network.chainId !== this.chainId) {
        await this.switchToBaseNetwork();
      }

      console.log('✓ Connected to MetaMask:', this.userAddress);
      return { success: true, address: this.userAddress };
    } catch (error) {
      console.error('MetaMask connection failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Request network switch to Base
   */
  async switchToBaseNetwork() {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x2105' }] // Base chainId in hex
      });
    } catch (switchError) {
      if (switchError.code === 4902) {
        // Network not added, add it
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: '0x2105',
            chainName: 'Base',
            rpcUrls: ['https://mainnet.base.org'],
            blockExplorerUrls: ['https://basescan.org'],
            nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 }
          }]
        });
      } else throw switchError;
    }
  }

  /**
   * Get token balance
   */
  async getTokenBalance(address = null) {
    try {
      const checkAddress = address || this.userAddress;
      if (!checkAddress) throw new Error('No wallet connected');

      const provider = new this.ethers.providers.JsonRpcProvider(this.config.rpcUrl);
      const contract = new this.ethers.Contract(
        this.config.tokenContract,
        ['function balanceOf(address) view returns (uint256)'],
        provider
      );

      const balance = await contract.balanceOf(checkAddress);
      const formattedBalance = this.ethers.utils.formatUnits(balance, this.tokenDecimals);

      return { success: true, balance: formattedBalance, raw: balance.toString() };
    } catch (error) {
      console.error('Error getting token balance:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get ETH balance (native token)
   */
  async getETHBalance(address = null) {
    try {
      const checkAddress = address || this.userAddress;
      if (!checkAddress) throw new Error('No wallet connected');

      const balance = await this.provider.getBalance(checkAddress);
      const ethBalance = this.ethers.utils.formatEther(balance);

      return { success: true, balance: ethBalance, raw: balance.toString() };
    } catch (error) {
      console.error('Error getting ETH balance:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Transfer tokens
   */
  async transferToken(toAddress, amount) {
    try {
      if (!this.signer) throw new Error('Not connected to wallet');

      const contract = new this.ethers.Contract(
        this.config.tokenContract,
        ['function transfer(address to, uint256 amount) returns (bool)'],
        this.signer
      );

      const amountWei = this.ethers.utils.parseUnits(amount, this.tokenDecimals);
      const tx = await contract.transfer(toAddress, amountWei);
      const receipt = await tx.wait();

      console.log('✓ Transfer successful:', receipt.transactionHash);
      return {
        success: true,
        txHash: receipt.transactionHash,
        blockNumber: receipt.blockNumber
      };
    } catch (error) {
      console.error('Transfer failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Claim airdrop (admin-controlled)
   */
  async claimAirdrop(airdropData) {
    try {
      if (!this.signer) throw new Error('Not connected to wallet');

      const contract = new this.ethers.Contract(
        this.config.tokenContract,
        ['function claim(bytes32[] proof, uint256 amount) returns (bool)'],
        this.signer
      );

      const tx = await contract.claim(airdropData.proof, airdropData.amount);
      const receipt = await tx.wait();

      return {
        success: true,
        txHash: receipt.transactionHash,
        amount: airdropData.amount
      };
    } catch (error) {
      console.error('Airdrop claim failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get ENS name for address
   */
  async getENSName(address = null) {
    try {
      const checkAddress = address || this.userAddress;
      const ensName = await this.provider.lookupAddress(checkAddress);
      return { success: true, ensName: ensName || 'Not available' };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Sign message (for verification)
   */
  async signMessage(message) {
    try {
      if (!this.signer) throw new Error('Not connected to wallet');

      const signature = await this.signer.signMessage(message);
      return { success: true, signature, message };
    } catch (error) {
      console.error('Signature failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get current user info
   */
  async getUserInfo() {
    try {
      if (!this.userAddress) {
        return { connected: false };
      }

      const [balance, ethBalance, ensName] = await Promise.all([
        this.getTokenBalance(),
        this.getETHBalance(),
        this.getENSName()
      ]);

      return {
        connected: true,
        address: this.userAddress,
        tokenBalance: balance.balance,
        ethBalance: ethBalance.balance,
        ensName: ensName.ensName,
        network: this.config.chainName
      };
    } catch (error) {
      console.error('Error getting user info:', error);
      return { connected: false, error: error.message };
    }
  }

  /**
   * Disconnect wallet
   */
  disconnect() {
    this.userAddress = null;
    this.provider = null;
    this.signer = null;
    console.log('✓ Wallet disconnected');
    return { success: true };
  }
}

// Export for use in WordPress
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Gene1799Web3Integration;
}
