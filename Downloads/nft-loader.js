/**
 * ████████████████████████████████████████████████████████
 * █ GENE1799 ART CORPORATIONE - NFT LOADER               █
 * █ Loads and displays NFT collections from multiple       █
 * █ platforms: Zora, SuperRare, Crypto.com, Foundation     █
 * ████████████████████████████████████████████████████████
 */

const NFTLoader = (() => {
  // ═══════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════
  
  const CREATOR_ADDRESSES = {
    zora: 'gene1799',
    superrare: 'gen_e1799',
    cryptoCom: 'gen_e1799',
    foundation: 'gen_e1799'
  };

  const PLATFORM_URLS = {
    zora: 'https://zora.co/@gene1799',
    superrare: 'https://superrare.com/gen_e1799',
    cryptoCom: 'https://crypto.com/nft/profile/gen_e1799?tab=created',
    foundation: 'https://foundation.app/@gen_e1799',
    opensea: 'https://opensea.io/gen_e1799'
  };

  const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
  let nftCache = { data: null, timestamp: 0 };

  // ═══════════════════════════════════════════
  // NFT FETCHING
  // ═══════════════════════════════════════════

  /**
   * Fetch NFTs from Zora API
   */
  async function fetchZoraNFTs() {
    try {
      const response = await fetch(
        'https://api.zora.co/discover/tokens?creatorAddresses[]=gene1799&limit=20&sortDirection=DESC',
        { headers: { 'Accept': 'application/json' } }
      );

      if (!response.ok) throw new Error('Zora API error');

      const data = await response.json();
      return (data.results || []).map(token => ({
        id: token.tokenId || token.id,
        title: token.name || 'Untitled',
        image: token.image?.url || token.media?.image?.url || '',
        platform: 'Zora',
        platformUrl: `https://zora.co/collect/${token.collectionAddress}/${token.tokenId}`,
        price: token.mintPrice ? `${token.mintPrice} ETH` : 'View on Zora',
        collection: token.collectionName || '',
        minted: token.mintedAt || ''
      }));
    } catch (error) {
      console.warn('Zora fetch failed:', error);
      return [];
    }
  }

  /**
   * Fetch from SimpleHash API (aggregates multiple marketplaces)
   * Free tier: 100 requests/day
   */
  async function fetchSimpleHashNFTs(creatorAddress) {
    try {
      const response = await fetch(
        `https://api.simplehash.com/api/v0/nfts/creators?chains=ethereum,base&wallet_addresses=${creatorAddress}&limit=20`,
        {
          headers: {
            'Accept': 'application/json',
            // Add your SimpleHash API key for production
            // 'X-API-KEY': 'YOUR_KEY'
          }
        }
      );

      if (!response.ok) return [];

      const data = await response.json();
      return (data.nfts || []).map(nft => ({
        id: nft.token_id,
        title: nft.name || 'Untitled',
        image: nft.previews?.image_medium_url || nft.image_url || '',
        platform: detectPlatform(nft),
        platformUrl: nft.marketplace_pages?.[0]?.marketplace_collection_id || '',
        price: nft.last_sale?.unit_price ? `${nft.last_sale.unit_price} ETH` : '',
        collection: nft.collection?.name || '',
        minted: nft.created_date || ''
      }));
    } catch (error) {
      console.warn('SimpleHash fetch failed:', error);
      return [];
    }
  }

  /**
   * Detect which platform an NFT is primarily on
   */
  function detectPlatform(nft) {
    const marketplaces = nft.marketplace_pages || [];
    for (const mp of marketplaces) {
      const id = (mp.marketplace_id || '').toLowerCase();
      if (id.includes('zora')) return 'Zora';
      if (id.includes('superrare')) return 'SuperRare';
      if (id.includes('foundation')) return 'Foundation';
      if (id.includes('opensea')) return 'OpenSea';
    }
    return 'NFT';
  }

  // ═══════════════════════════════════════════
  // STATIC FALLBACK GALLERY
  // (when APIs are unavailable)
  // ═══════════════════════════════════════════

  function getStaticGallery() {
    return [
      {
        id: 1,
        title: 'Attacchi di Panico',
        image: 'assets/images/nft-attacchi-di-panico.jpg',
        platform: 'SuperRare',
        platformUrl: PLATFORM_URLS.superrare,
        price: 'View on SuperRare',
        collection: 'Miami Basel 2023',
        description: 'Exhibited at Art Innovation Gallery, Miami Basel 2023'
      },
      {
        id: 2,
        title: 'Avana Syndrome',
        image: 'assets/images/nft-avana-syndrome.jpg',
        platform: 'SuperRare',
        platformUrl: PLATFORM_URLS.superrare,
        price: 'View on SuperRare',
        collection: 'NFT.NYC 2024',
        description: 'Exhibited at NFT.NYC 2024'
      },
      {
        id: 3,
        title: 'Bipolar',
        image: 'assets/images/nft-bipolar.jpg',
        platform: 'Foundation',
        platformUrl: 'https://foundation.app/mint/eth/0x8f9f6BA197156F098b4149A85583281120F6E2f0/3',
        price: 'View on Foundation',
        collection: 'Digital Twin Collection',
        description: 'Acrylic on canvas with resin + NFT digital twin'
      },
      {
        id: 4,
        title: 'Pixels Show Times Square',
        image: 'assets/images/nft-pixels-show.jpg',
        platform: 'Crypto.com',
        platformUrl: PLATFORM_URLS.cryptoCom,
        price: 'View on Crypto.com',
        collection: 'Times Square Projection',
        description: 'Art Innovation Gallery collaboration with Crypto.com'
      },
      {
        id: 5,
        title: 'Gene1799 Collection',
        image: 'assets/images/nft-collection-zora.jpg',
        platform: 'Zora',
        platformUrl: PLATFORM_URLS.zora,
        price: 'Mint on Zora',
        collection: 'Zora Collection',
        description: 'Latest drops on Zora protocol'
      }
    ];
  }

  // ═══════════════════════════════════════════
  // LOADING & RENDERING
  // ═══════════════════════════════════════════

  /**
   * Load all NFTs from available sources
   */
  async function loadAllNFTs() {
    // Check cache
    if (nftCache.data && Date.now() - nftCache.timestamp < CACHE_DURATION) {
      return nftCache.data;
    }

    let allNFTs = [];

    try {
      // Try Zora API first
      const zoraNFTs = await fetchZoraNFTs();
      allNFTs = [...zoraNFTs];

      // If we got results, cache them
      if (allNFTs.length > 0) {
        nftCache = { data: allNFTs, timestamp: Date.now() };
        return allNFTs;
      }
    } catch (error) {
      console.warn('API fetch failed, using static gallery');
    }

    // Fallback to static gallery
    allNFTs = getStaticGallery();
    nftCache = { data: allNFTs, timestamp: Date.now() };
    return allNFTs;
  }

  /**
   * Render NFT cards into the grid
   */
  async function renderGallery(containerId = 'nft-grid') {
    const container = document.getElementById(containerId);
    if (!container) return;

    // Show loading state
    container.innerHTML = `
      <div class="nft-card loading">
        <div class="nft-image-placeholder"></div>
        <div class="nft-info">
          <div class="nft-title loading-text">LOADING NFTs...</div>
          <div class="nft-platform">Connecting to marketplaces</div>
        </div>
      </div>
    `;

    const nfts = await loadAllNFTs();

    if (nfts.length === 0) {
      container.innerHTML = `
        <div class="ascii-box text-center">
          <p class="text-gold">No NFTs loaded. Visit our marketplaces directly:</p>
          <div class="mt-lg">
            <a href="${PLATFORM_URLS.zora}" target="_blank" class="btn">ZORA</a>
            <a href="${PLATFORM_URLS.superrare}" target="_blank" class="btn btn-secondary">SUPERRARE</a>
          </div>
        </div>
      `;
      return;
    }

    // Render NFT cards with staggered animation
    container.innerHTML = nfts.map((nft, index) => `
      <a href="${escapeHtml(nft.platformUrl)}" target="_blank" rel="noopener noreferrer" 
         class="nft-card" style="animation-delay: ${index * 0.1}s">
        <div class="nft-image-wrapper">
          ${nft.image 
            ? `<img src="${escapeHtml(nft.image)}" alt="${escapeHtml(nft.title)}" 
                   class="nft-image" loading="lazy" 
                   onerror="this.parentElement.innerHTML='<div class=\\'nft-image-placeholder\\'>${escapeHtml(nft.title)}</div>'">`
            : `<div class="nft-image-placeholder">${escapeHtml(nft.title)}</div>`
          }
        </div>
        <div class="nft-info">
          <div class="nft-title">${escapeHtml(nft.title)}</div>
          <div class="nft-platform">${escapeHtml(nft.platform)}</div>
          ${nft.collection ? `<div class="nft-collection">${escapeHtml(nft.collection)}</div>` : ''}
          ${nft.price ? `<div class="nft-price">${escapeHtml(nft.price)}</div>` : ''}
        </div>
      </a>
    `).join('');
  }

  /**
   * Escape HTML to prevent XSS
   */
  function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // ═══════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════

  document.addEventListener('DOMContentLoaded', () => {
    renderGallery();
  });

  return {
    loadAllNFTs,
    renderGallery,
    getStaticGallery,
    PLATFORM_URLS
  };
})();

window.NFTLoader = NFTLoader;
