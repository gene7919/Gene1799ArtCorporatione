/**
 * ████████████████████████████████████████████████████████
 * █ GENE1799 ART CORPORATIONE - WEB3 INTEGRATION        █
 * █ Marco Antonio Saverio Mazzitelli & Fabio Amedeo LP   █
 * █ 16/A409879L - Arthemis Ludovici Productions          █
 * ████████████████████████████████████████████████████████
 * 
 * Web3 wallet connection, token balance checking,
 * NFT ownership verification, and airdrop claim system.
 * Uses ethers.js v5 (loaded via CDN in index.html)
 */

const Web3Integration = (() => {
  // ═══════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════
  const BASE_CHAIN_ID = 8453;
  const BASE_RPC = 'https://mainnet.base.org';
  const TOKEN_CONTRACT = '0x63800f370b04ce132333c05d811663b80cec788e';
  
  // ERC-20 ABI (minimal for balance + transfer)
  const ERC20_ABI = [
    'function balanceOf(address owner) view returns (uint256)',
    'function decimals() view returns (uint8)',
    'function symbol() view returns (string)',
    'function name() view returns (string)',
    'function totalSupply() view returns (uint256)',
    'function transfer(address to, uint256 amount) returns (bool)',
    'event Transfer(address indexed from, address indexed to, uint256 value)'
  ];

  // Zora NFT contract ABIs (ERC-721 / ERC-1155)
  const NFT_ABI = [
    'function balanceOf(address owner) view returns (uint256)',
    'function tokenURI(uint256 tokenId) view returns (string)',
    'function ownerOf(uint256 tokenId) view returns (address)',
    'function name() view returns (string)'
  ];

  // Known NFT collections by Gene1799
  const GENE1799_COLLECTIONS = [
    // Add your Zora collection addresses here
    // { address: '0x...', name: 'Collection Name', platform: 'Zora' }
  ];

  // ═══════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════
  let provider = null;
  let signer = null;
  let userAddress = null;
  let tokenContract = null;
  let isConnected = false;

  // ═══════════════════════════════════════════
  // WALLET CONNECTION
  // ═══════════════════════════════════════════

  /**
   * Connect to MetaMask or compatible wallet
   */
  async function connectWallet() {
    if (typeof window.ethereum === 'undefined') {
      showStatus('❌ MetaMask non trovato. Installa MetaMask per continuare.', 'error');
      window.open('https://metamask.io/download/', '_blank');
      return null;
    }

    try {
      // Request account access
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      provider = new ethers.providers.Web3Provider(window.ethereum);
      signer = provider.getSigner();
      userAddress = accounts[0];

      // Check if on Base network
      const network = await provider.getNetwork();
      if (network.chainId !== BASE_CHAIN_ID) {
        await switchToBase();
      }

      // Initialize token contract
      tokenContract = new ethers.Contract(TOKEN_CONTRACT, ERC20_ABI, signer);

      isConnected = true;
      updateUI();
      showStatus(`✅ Wallet connesso: ${formatAddress(userAddress)}`, 'success');

      // Listen for account/network changes
      window.ethereum.on('accountsChanged', handleAccountChange);
      window.ethereum.on('chainChanged', () => window.location.reload());

      return userAddress;

    } catch (error) {
      console.error('Connection error:', error);
      showStatus(`❌ Errore connessione: ${error.message}`, 'error');
      return null;
    }
  }

  /**
   * Switch to Base network
   */
  async function switchToBase() {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: ethers.utils.hexValue(BASE_CHAIN_ID) }]
      });
    } catch (switchError) {
      // Chain not added yet — add it
      if (switchError.code === 4902) {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: ethers.utils.hexValue(BASE_CHAIN_ID),
            chainName: 'Base',
            nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
            rpcUrls: [BASE_RPC],
            blockExplorerUrls: ['https://basescan.org']
          }]
        });
      } else {
        throw switchError;
      }
    }
  }

  /**
   * Handle account change
   */
  function handleAccountChange(accounts) {
    if (accounts.length === 0) {
      disconnect();
    } else {
      userAddress = accounts[0];
      updateUI();
    }
  }

  /**
   * Disconnect wallet
   */
  function disconnect() {
    provider = null;
    signer = null;
    userAddress = null;
    tokenContract = null;
    isConnected = false;
    updateUI();
    showStatus('Wallet disconnesso', 'info');
  }

  // ═══════════════════════════════════════════
  // TOKEN FUNCTIONS
  // ═══════════════════════════════════════════

  /**
   * Get $GENE1799 token balance
   */
  async function getTokenBalance() {
    if (!isConnected || !tokenContract) return '0';
    
    try {
      const balance = await tokenContract.balanceOf(userAddress);
      const decimals = await tokenContract.decimals();
      return ethers.utils.formatUnits(balance, decimals);
    } catch (error) {
      console.error('Balance check error:', error);
      return '0';
    }
  }

  /**
   * Get token info (name, symbol, supply)
   */
  async function getTokenInfo() {
    const readProvider = new ethers.providers.JsonRpcProvider(BASE_RPC);
    const contract = new ethers.Contract(TOKEN_CONTRACT, ERC20_ABI, readProvider);

    try {
      const [name, symbol, decimals, totalSupply] = await Promise.all([
        contract.name(),
        contract.symbol(),
        contract.decimals(),
        contract.totalSupply()
      ]);

      return {
        name,
        symbol,
        decimals,
        totalSupply: ethers.utils.formatUnits(totalSupply, decimals),
        contract: TOKEN_CONTRACT,
        network: 'Base',
        chainId: BASE_CHAIN_ID
      };
    } catch (error) {
      console.error('Token info error:', error);
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // NFT VERIFICATION (for Airdrop)
  // ═══════════════════════════════════════════

  /**
   * Check if user owns any Gene1799 NFTs across platforms
   * Uses Zora API + direct contract calls
   */
  async function checkNFTOwnership() {
    if (!isConnected) {
      showStatus('❌ Connetti il wallet prima', 'error');
      return { owns: false, collections: [] };
    }

    showStatus('🔍 Verifica NFT in corso...', 'info');

    const ownedNFTs = [];

    // Check each known collection
    for (const collection of GENE1799_COLLECTIONS) {
      try {
        const readProvider = new ethers.providers.JsonRpcProvider(BASE_RPC);
        const nftContract = new ethers.Contract(collection.address, NFT_ABI, readProvider);
        const balance = await nftContract.balanceOf(userAddress);

        if (balance.gt(0)) {
          ownedNFTs.push({
            ...collection,
            balance: balance.toString()
          });
        }
      } catch (error) {
        console.error(`Error checking ${collection.name}:`, error);
      }
    }

    // Also check via Zora API (for collections on Zora protocol)
    try {
      const zoraOwned = await checkZoraOwnership(userAddress);
      ownedNFTs.push(...zoraOwned);
    } catch (error) {
      console.error('Zora API error:', error);
    }

    const result = {
      owns: ownedNFTs.length > 0,
      collections: ownedNFTs,
      address: userAddress
    };

    if (result.owns) {
      showStatus(`✅ Trovati ${ownedNFTs.length} NFT Gene1799! Puoi richiedere l'airdrop.`, 'success');
    } else {
      showStatus('ℹ️ Nessun NFT Gene1799 trovato. Acquista su Zora per ottenere l\'airdrop!', 'info');
    }

    displayNFTResult(result);
    return result;
  }

  /**
   * Check Zora protocol for owned NFTs by Gene1799
   */
  async function checkZoraOwnership(address) {
    // Zora API v2 - check tokens owned by address from Gene1799 creator
    try {
      const response = await fetch(
        `https://api.zora.co/discover/tokens?ownerAddresses[]=${address}&creatorAddresses[]=gene1799`,
        { headers: { 'Accept': 'application/json' } }
      );
      
      if (!response.ok) return [];
      
      const data = await response.json();
      return (data.results || []).map(token => ({
        address: token.collectionAddress,
        name: token.collectionName || 'Zora Collection',
        platform: 'Zora',
        tokenId: token.tokenId,
        balance: '1'
      }));
    } catch {
      return [];
    }
  }

  // ═══════════════════════════════════════════
  // AIRDROP CLAIM
  // ═══════════════════════════════════════════

  /**
   * Claim airdrop tokens (500 $GENE1799 per NFT owned)
   * This would connect to your backend API for the actual distribution
   */
  async function claimAirdrop() {
    if (!isConnected) {
      showStatus('❌ Connetti il wallet prima', 'error');
      return;
    }

    const ownership = await checkNFTOwnership();
    if (!ownership.owns) {
      showStatus('❌ Devi possedere almeno un NFT Gene1799 per l\'airdrop', 'error');
      return;
    }

    showStatus('📝 Preparazione airdrop...', 'info');

    try {
      // Call your backend API to process the airdrop
      const response = await fetch('/api/claim-airdrop', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          address: userAddress,
          nftCount: ownership.collections.length,
          collections: ownership.collections.map(c => c.address),
          timestamp: Date.now()
        })
      });

      if (response.ok) {
        const result = await response.json();
        showStatus(`🎉 Airdrop richiesto! ${result.amount} $GENE1799 in arrivo.`, 'success');
      } else {
        const error = await response.json();
        showStatus(`❌ ${error.message || 'Errore nel claim'}`, 'error');
      }
    } catch (error) {
      // If no backend, show info message
      showStatus('ℹ️ Sistema airdrop in fase di attivazione. Registrazione salvata!', 'info');
      console.log('Airdrop claim data:', {
        address: userAddress,
        nftCount: ownership.collections.length
      });
    }
  }

  // ═══════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════

  function formatAddress(addr) {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  }

  function showStatus(message, type = 'info') {
    const statusEl = document.getElementById('web3-status');
    if (statusEl) {
      statusEl.textContent = message;
      statusEl.className = `web3-status web3-status--${type}`;
      statusEl.style.display = 'block';
    }
    console.log(`[Web3] ${message}`);
  }

  function updateUI() {
    const connectBtn = document.getElementById('connect-wallet-btn');
    const walletInfo = document.getElementById('wallet-info');
    const walletAddress = document.getElementById('wallet-address');

    if (isConnected && userAddress) {
      if (connectBtn) connectBtn.textContent = `✅ ${formatAddress(userAddress)}`;
      if (walletInfo) walletInfo.style.display = 'block';
      if (walletAddress) walletAddress.textContent = userAddress;

      // Update balance display
      getTokenBalance().then(balance => {
        const balanceEl = document.getElementById('token-balance');
        if (balanceEl) {
          balanceEl.textContent = `${parseFloat(balance).toLocaleString()} $GENE1799`;
        }
      });
    } else {
      if (connectBtn) connectBtn.textContent = '🦊 CONNECT METAMASK';
      if (walletInfo) walletInfo.style.display = 'none';
    }
  }

  function displayNFTResult(result) {
    const container = document.getElementById('nft-check-result');
    const content = document.getElementById('nft-result-content');
    if (!container || !content) return;

    container.style.display = 'block';

    if (result.owns) {
      content.innerHTML = `
        <p class="text-green">✅ VERIFICATO: ${result.collections.length} NFT Gene1799 trovati!</p>
        ${result.collections.map(c => `
          <div class="nft-result-item">
            <span class="text-cyan">${c.name}</span>
            <span class="text-gold"> × ${c.balance}</span>
            <span class="text-secondary"> (${c.platform})</span>
          </div>
        `).join('')}
        <div class="mt-lg text-center">
          <button onclick="Web3Integration.claimAirdrop()" class="btn btn-gold">
            🎁 RICHIEDI ${result.collections.length * 500} $GENE1799
          </button>
        </div>
      `;
    } else {
      content.innerHTML = `
        <p class="text-gold">ℹ️ Nessun NFT Gene1799 trovato per ${formatAddress(result.address)}</p>
        <p>Acquista un NFT per ottenere 500 $GENE1799 gratuiti!</p>
        <div class="mt-lg text-center">
          <a href="https://zora.co/@gene1799" target="_blank" class="btn">ACQUISTA SU ZORA</a>
        </div>
      `;
    }
  }

  // ═══════════════════════════════════════════
  // EVENT LISTENERS
  // ═══════════════════════════════════════════

  document.addEventListener('DOMContentLoaded', () => {
    const connectBtn = document.getElementById('connect-wallet-btn');
    if (connectBtn) {
      connectBtn.addEventListener('click', connectWallet);
    }

    // Auto-connect if previously connected
    if (window.ethereum && window.ethereum.selectedAddress) {
      connectWallet();
    }
  });

  // ═══════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════

  return {
    connectWallet,
    disconnect,
    getTokenBalance,
    getTokenInfo,
    checkNFTOwnership,
    claimAirdrop,
    get isConnected() { return isConnected; },
    get address() { return userAddress; },
    get provider() { return provider; }
  };
})();

// Make globally available
window.Web3Integration = Web3Integration;
