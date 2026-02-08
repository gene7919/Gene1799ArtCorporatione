/**
 * GENE1799 NFT Loader Module
 * Dynamically loads NFT collections from multiple platforms
 * Supports: Zora, SuperRare, Crypto.com, Foundation, OpenSea, Rarible
 */

class Gene1799NFTLoader {
  constructor(config = {}) {
    this.config = {
      artistAddress: config.artistAddress || 'gene1799',
      zoraUsername: config.zoraUsername || 'gene1799',
      baseUrl: config.baseUrl || 'https://zora.co',
      ...config
    };

    this.nftCache = new Map();
    this.platformAPIs = {
      zora: 'https://api.zora.co/graphql',
      superrare: 'https://api.superrare.com/v2',
      openSea: 'https://api.opensea.io/v2',
      rarible: 'https://api.rarible.com/v2',
      foundation: 'https://api.foundation.app/graphql'
    };
  }

  /**
   * Load all NFTs from all platforms
   */
  async loadAllNFTs() {
    try {
      const results = {
        zora: await this.loadZoraNFTs(),
        superrare: await this.loadSuperRareNFTs(),
        openSea: await this.loadOpenSeaNFTs(),
        rarible: await this.loadRaribleNFTs()
      };

      // Cache results
      this.nftCache.set('all_nfts', results);
      console.log('✓ All NFTs loaded successfully');

      return results;
    } catch (error) {
      console.error('Error loading NFTs:', error);
      return { error: error.message };
    }
  }

  /**
   * Load NFTs from Zora
   */
  async loadZoraNFTs() {
    try {
      const query = `
        query GetNFTsByArtist($artist: String!) {
          nfts(where: {creator: $artist}) {
            id
            title
            description
            image
            contentURI
            price
            edition
            createdAt
            contractAddress
            tokenId
            metadata {
              attributes
              tags
            }
          }
        }
      `;

      const response = await fetch(this.platformAPIs.zora, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query,
          variables: { artist: this.config.artistAddress }
        })
      });

      const data = await response.json();

      if (!data.data || !data.data.nfts) {
        throw new Error('Zora API error: No NFTs found');
      }

      const nfts = data.data.nfts.map(nft => ({
        ...nft,
        platform: 'Zora',
        marketplaceURL: `https://zora.co/@${this.config.zoraUsername}/${nft.id}`
      }));

      this.nftCache.set('zora_nfts', nfts);
      return { success: true, nfts, count: nfts.length };
    } catch (error) {
      console.error('Error loading Zora NFTs:', error);
      return { success: false, error: error.message, nfts: [] };
    }
  }

  /**
   * Load NFTs from SuperRare
   */
  async loadSuperRareNFTs() {
    try {
      const response = await fetch(
        `${this.platformAPIs.superrare}/artworks?creator=${this.config.artistAddress}`,
        {
          headers: {
            'Authorization': `Bearer ${this.config.superrareToken || ''}`
          }
        }
      );

      const data = await response.json();

      if (!data.artworks) {
        return { success: false, error: 'No SuperRare NFTs found', nfts: [] };
      }

      const nfts = data.artworks.map(artwork => ({
        id: artwork.id,
        title: artwork.name,
        description: artwork.description,
        image: artwork.image,
        price: artwork.price,
        contractAddress: artwork.contractAddress,
        tokenId: artwork.tokenId,
        platform: 'SuperRare',
        marketplaceURL: `https://superrare.com/artwork/${artwork.id}`,
        metadata: {
          attributes: artwork.attributes || []
        }
      }));

      this.nftCache.set('superrare_nfts', nfts);
      return { success: true, nfts, count: nfts.length };
    } catch (error) {
      console.error('Error loading SuperRare NFTs:', error);
      return { success: false, error: error.message, nfts: [] };
    }
  }

  /**
   * Load NFTs from OpenSea
   */
  async loadOpenSeaNFTs() {
    try {
      const response = await fetch(
        `${this.platformAPIs.openSea}/collections/${this.config.artistAddress}`,
        {
          headers: {
            'X-API-KEY': this.config.openSeaKey || ''
          }
        }
      );

      const data = await response.json();

      if (!data.nfts) {
        return { success: false, error: 'No OpenSea NFTs found', nfts: [] };
      }

      const nfts = data.nfts.map(nft => ({
        id: nft.identifier,
        title: nft.name,
        description: nft.description,
        image: nft.image_url,
        price: nft.current_price,
        contractAddress: nft.contract,
        tokenId: nft.identifier,
        platform: 'OpenSea',
        marketplaceURL: `https://opensea.io/assets/${nft.contract}/${nft.identifier}`,
        metadata: {
          attributes: nft.traits || []
        }
      }));

      this.nftCache.set('opensea_nfts', nfts);
      return { success: true, nfts, count: nfts.length };
    } catch (error) {
      console.error('Error loading OpenSea NFTs:', error);
      return { success: false, error: error.message, nfts: [] };
    }
  }

  /**
   * Load NFTs from Rarible
   */
  async loadRaribleNFTs() {
    try {
      const response = await fetch(
        `${this.platformAPIs.rarible}/items/byCreator?creator=${this.config.artistAddress}&size=100`
      );

      const data = await response.json();

      if (!data.items) {
        return { success: false, error: 'No Rarible NFTs found', nfts: [] };
      }

      const nfts = data.items.map(item => ({
        id: item.id,
        title: item.name,
        description: item.description,
        image: item.image,
        price: item.price,
        contractAddress: item.contract,
        tokenId: item.token_id,
        platform: 'Rarible',
        marketplaceURL: `https://rarible.com/token/${item.contract}:${item.token_id}`,
        metadata: {
          attributes: item.attributes || []
        }
      }));

      this.nftCache.set('rarible_nfts', nfts);
      return { success: true, nfts, count: nfts.length };
    } catch (error) {
      console.error('Error loading Rarible NFTs:', error);
      return { success: false, error: error.message, nfts: [] };
    }
  }

  /**
   * Get NFTs by collection/platform
   */
  getNFTsByPlatform(platform) {
    const key = `${platform.toLowerCase()}_nfts`;
    return this.nftCache.get(key) || [];
  }

  /**
   * Search NFTs
   */
  searchNFTs(query, platform = null) {
    const allNFTs = platform
      ? this.getNFTsByPlatform(platform)
      : (this.nftCache.get('all_nfts') || {});

    const searchTerm = query.toLowerCase();
    const results = [];

    const searchInArray = (arr) => {
      return arr.filter(nft =>
        nft.title?.toLowerCase().includes(searchTerm) ||
        nft.description?.toLowerCase().includes(searchTerm) ||
        nft.id?.toLowerCase().includes(searchTerm)
      );
    };

    if (Array.isArray(allNFTs)) {
      return searchInArray(allNFTs);
    } else {
      Object.values(allNFTs).forEach(nftArray => {
        if (Array.isArray(nftArray)) {
          results.push(...searchInArray(nftArray));
        }
      });
    }

    return results;
  }

  /**
   * Render NFT gallery HTML
   */
  renderGallery(nfts, containerId = 'nft-gallery', options = {}) {
    const container = document.getElementById(containerId);
    if (!container) {
      console.error(`Container #${containerId} not found`);
      return;
    }

    const columns = options.columns || 3;
    const containerHTML = document.createElement('div');
    containerHTML.className = 'nft-gallery';
    containerHTML.style.cssText = `
      display: grid;
      grid-template-columns: repeat(${columns}, 1fr);
      gap: 20px;
      padding: 20px;
    `;

    nfts.forEach(nft => {
      const card = document.createElement('div');
      card.className = 'nft-card';
      card.style.cssText = `
        border: 1px solid #ccc;
        border-radius: 8px;
        overflow: hidden;
        background: white;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      `;

      card.innerHTML = `
        <img src="${nft.image}" alt="${nft.title}" style="width: 100%; height: 300px; object-fit: cover;">
        <div style="padding: 15px;">
          <h3 style="margin: 0 0 8px 0; font-size: 16px;">${nft.title}</h3>
          <p style="margin: 0 0 10px 0; color: #666; font-size: 12px;">${nft.platform}</p>
          <p style="margin: 0 0 15px 0; color: #999; font-size: 13px;">${nft.description?.substring(0, 100) || 'No description'}...</p>
          <div style="display: flex; justify-content: space-between; align-items: center;">
            ${nft.price ? `<strong>${nft.price} ETH</strong>` : '<strong>Not for sale</strong>'}
            <a href="${nft.marketplaceURL}" target="_blank" style="padding: 8px 12px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; font-size: 12px;">
              View
            </a>
          </div>
        </div>
      `;

      containerHTML.appendChild(card);
    });

    container.innerHTML = '';
    container.appendChild(containerHTML);
  }

  /**
   * Get cache statistics
   */
  getCacheStats() {
    return {
      totalNFTs: Array.from(this.nftCache.values()).reduce((sum, val) => {
        if (Array.isArray(val)) return sum + val.length;
        if (typeof val === 'object' && val !== null) {
          return sum + Object.values(val).reduce((s, v) => s + (Array.isArray(v) ? v.length : 0), 0);
        }
        return sum;
      }, 0),
      cachedPlatforms: Array.from(this.nftCache.keys()),
      cacheSize: this.nftCache.size
    };
  }
}

// Export
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Gene1799NFTLoader;
}
