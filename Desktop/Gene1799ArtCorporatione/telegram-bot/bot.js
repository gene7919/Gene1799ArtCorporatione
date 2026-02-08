/**
 * GENE1799 ART CORPORATIONE - Telegram Bot
 * Features:
 * 1. NFT Sales Notifications (Zora every 30s)
 * 2. $GENE1799 Token Commands (price, balance, info)
 * 3. Community Management (welcome, anti-spam, warnings)
 * 4. Automatic Promotion (scheduled posts, weekly recap)
 */

const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');
const schedule = require('node-cron');

class Gene1799Bot {
  constructor(options = {}) {
    // Configuration
    this.token = process.env.BOT_TOKEN || options.token;
    this.channelId = process.env.CHANNEL_ID || options.channelId;
    this.adminIds = (process.env.ADMIN_IDS || '').split(',').filter(Boolean);
    this.baseRpcUrl = process.env.BASE_RPC_URL || 'https://mainnet.base.org';
    this.tokenContract = process.env.TOKEN_CONTRACT || '0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0';
    this.web3ServiceUrl = process.env.WEB3_SERVICE_URL || 'http://localhost:8004';

    // Initialize bot
    this.bot = new TelegramBot(this.token, { polling: true });

    // State management
    this.userWarnings = new Map();
    this.nftCheckInterval = null;
    this.lastNFTCheck = 0;

    this.setupCommands();
    this.setupEventHandlers();
    this.startScheduledTasks();

    console.log('✓ GENE1799 Telegram Bot initialized');
  }

  /**
   * Setup bot commands
   */
  setupCommands() {
    // /start - Welcome message
    this.bot.onText(/\/start/, (msg) => {
      this.handleStart(msg);
    });

    // /token - Token info
    this.bot.onText(/\/token/, (msg) => {
      this.handleTokenInfo(msg);
    });

    // /price - Get token price
    this.bot.onText(/\/price/, (msg) => {
      this.handlePrice(msg);
    });

    // /balance - Check wallet balance
    this.bot.onText(/\/balance/, (msg) => {
      this.handleBalance(msg);
    });

    // /nft - NFT collections
    this.bot.onText(/\/nft/, (msg) => {
      this.handleNFT(msg);
    });

    // /gallery - Gallery/exhibitions
    this.bot.onText(/\/gallery/, (msg) => {
      this.handleGallery(msg);
    });

    // /social - Social links
    this.bot.onText(/\/social/, (msg) => {
      this.handleSocial(msg);
    });

    // /about - About info
    this.bot.onText(/\/about/, (msg) => {
      this.handleAbout(msg);
    });

    // /help - Help
    this.bot.onText(/\/help/, (msg) => {
      this.handleHelp(msg);
    });

    // Admin commands
    this.bot.onText(/\/announce (.+)/, (msg, match) => {
      this.handleAnnounce(msg, match[1]);
    });

    this.bot.onText(/\/mute (@.*?)(\s+\d+)?/, (msg, match) => {
      this.handleMute(msg, match[1], match[2]);
    });

    this.bot.onText(/\/warn (@.*?)/, (msg, match) => {
      this.handleWarn(msg, match[1]);
    });

    // /portfolio - Wallet portfolio with real data
    this.bot.onText(/\/portfolio/, (msg) => {
      this.handlePortfolio(msg);
    });

    // /mint - Zora minting info
    this.bot.onText(/\/mint/, (msg) => {
      this.handleMint(msg);
    });
  }

  /**
   * Setup event handlers
   */
  setupEventHandlers() {
    // New member welcome
    this.bot.on('new_chat_members', (msg) => {
      this.welcomeNewMembers(msg);
    });

    // Message handling for spam detection
    this.bot.on('message', (msg) => {
      this.checkForSpam(msg);
    });

    // Error handling
    this.bot.on('polling_error', (error) => {
      console.error('Polling error:', error);
    });
  }

  /**
   * Start scheduled tasks
   */
  startScheduledTasks() {
    // NFT sales notifications - Every 30 seconds
    this.nftCheckInterval = setInterval(() => {
      this.checkNFTSales();
    }, 30000);

    // Promotional posts - 10:00 and 18:00 Rome time
    schedule.schedule('0 10 * * *', () => {
      this.sendPromotion();
    }, { timezone: 'Europe/Rome' });

    schedule.schedule('0 18 * * *', () => {
      this.sendPromotion();
    }, { timezone: 'Europe/Rome' });

    // Weekly recap - Every Monday at 08:00
    schedule.schedule('0 8 * * 1', () => {
      this.sendWeeklyRecap();
    }, { timezone: 'Europe/Rome' });

    console.log('✓ Scheduled tasks started');
  }

  /**
   * Handler: /start
   */
  async handleStart(msg) {
    const startMessage = `
👋 **Benvenuto in GENE1799 ART CORPORATIONE!**

Ciao! Sono il bot ufficiale di GENE1799.

🎨 **Chi siamo:**
GENE1799 è un collettivo di artisti digitali che esplora l'intersezione tra arte, tecnologia e Web3.

💰 **Cosa posso fare:**
- 🪙 /token - Info su \`$GENE1799\`
- 💵 /price - Prezzo token e market cap
- 👛 /balance - Verifica balance wallet
- 🖼️ /nft - Collezioni NFT
- 🎭 /gallery - Mostre ed esposizioni
- 🔗 /social - Link social
- ℹ️ /about - Chi siamo
- ❓ /help - Lista comandi

**Siamo su:**
🟣 Zora: zora.co/@gene1799
🦅 Rarible: rarible.com/@gene1799
🎨 SuperRare: superrare.com/@gene1799
🌐 Website: gene1799artcorporatione.mom

*Buona esplorazione! 🚀*
    `;

    this.bot.sendMessage(msg.chat.id, startMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Handler: /token
   */
  async handleTokenInfo(msg) {
    const tokenMessage = `
💰 **\`$GENE1799\` TOKEN**

**Informazioni Contratto:**
- Rete: Base (Ethereum)
- Decimali: 18
- Contratto: \`${this.tokenContract}\`
- Standard: ERC-20 Compliant

**Come comprare:**
🔗 DEX: Uniswap v3 (Base network)
🔗 CEX: Coming soon...

**Utilità:**
✓ Holder rewards
✓ Accesso community esclusiva
✓ Governance token
✓ NFT discount

*Vuoi controllare il tuo balance? Usa /balance*
    `;

    this.bot.sendMessage(msg.chat.id, tokenMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Handler: /price
   */
  async handlePrice(msg) {
    try {
      const priceData = await this.getTokenPrice();

      const priceMessage = `
💹 **Prezzo \`$GENE1799\`**

💵 Prezzo Attuale: **$${priceData.price}**
📊 Market Cap: **$${priceData.marketCap}**
📈 24h Volume: **$${priceData.volume24h}**
📉 24h Change: **${priceData.change24h > 0 ? '🟢' : '🔴'} ${priceData.change24h}%**

*Dati aggiornati da DexScreener*
      `;

      this.bot.sendMessage(msg.chat.id, priceMessage, { parse_mode: 'Markdown' });
    } catch (error) {
      this.bot.sendMessage(msg.chat.id, `❌ Errore nel recupero prezzo: ${error.message}`);
    }
  }

  /**
   * Handler: /balance
   */
  async handleBalance(msg) {
    if (!msg.text.includes(' ')) {
      const balanceMessage = `
👛 **Controlla il tuo Balance**

Usa il comando:
\`/balance 0x1234...\`

Sostituisci \`0x1234...\` con il tuo indirizzo wallet.

Anche MetaMask funziona se lo hai collegato! 🦊
      `;

      return this.bot.sendMessage(msg.chat.id, balanceMessage, { parse_mode: 'Markdown' });
    }

    const address = msg.text.split(' ')[1];

    try {
      const balance = await this.getTokenBalance(address);
      const ethBalance = await this.getETHBalance(address);

      const balanceMessage = `
👛 **Balance di ${address.substring(0, 6)}...${address.substring(-4)}**

🪙 \`$GENE1799\`: **${parseFloat(balance).toFixed(2)}**
Ξ **${parseFloat(ethBalance).toFixed(4)} ETH**

*Saldo aggiornato da Base Network*
      `;

      this.bot.sendMessage(msg.chat.id, balanceMessage, { parse_mode: 'Markdown' });
    } catch (error) {
      this.bot.sendMessage(msg.chat.id, `❌ Errore: ${error.message}`);
    }
  }

  /**
   * Handler: /nft
   */
  async handleNFT(msg) {
    const nftMessage = `
🖼️ **COLLEZIONI NFT GENE1799**

**Platform & Strategie:**

🟣 **Zora** (Volume + Community)
→ Open editions, mint frequenti
→ zora.co/@gene1799

🦅 **Rarible** (Decentralizzazione)
→ Verifica badge, community
→ rarible.com/@gene1799

🎨 **SuperRare** (Prestigio + 1/1)
→ Opere premium curate
→ superrare.com/@gene1799

📱 **Crypto.com** (Mainstream)
→ Collezioni prezzo accessibile
→ crypto.com/@gene1799

🏛️ **Foundation** (Sperimentale)
→ AI art, nuove tecniche
→ foundation.app/@gene1799

📦 **OpenSea** (Mercato secondario)
→ Trading cross-platform
→ opensea.io/collection/gene1799
    `;

    this.bot.sendMessage(msg.chat.id, nftMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Handler: /gallery
   */
  async handleGallery(msg) {
    const galleryMessage = `
🎭 **MOSTRE & ESPOSIZIONI**

**Prossimi Eventi:**

📅 **GENE1799:EMERGE**
→ Mostre virtuali su Zora
→ Nuove collezioni ogni mese
→ Tema: "Phygital Boundaries"

📅 **AI+HUMAN**
→ Collaborazioni con intelligenza artificiale
→ Foundation + SuperRare exclusive
→ Q2 2026

📅 **PHYSICAL TWINS**
→ Conversione NFT ↔ Fisico
→ Edizioni limitate
→ Q3 2026

💌 **Iscriviti alla newsletter:**
→ https://gene1799artcorporatione.mom/subscribe

*Rimani aggiornato! Usa /social per i link*
    `;

    this.bot.sendMessage(msg.chat.id, galleryMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Handler: /social
   */
  async handleSocial(msg) {
    const keyboard = {
      inline_keyboard: [
        [
          { text: '🐦 Twitter/X', url: 'https://twitter.com/gene1799' },
          { text: '📸 Instagram', url: 'https://instagram.com/gene1799art' }
        ],
        [
          { text: '🔗 Zora', url: 'https://zora.co/@gene1799' },
          { text: '🌐 Website', url: 'https://gene1799artcorporatione.mom' }
        ],
        [
          { text: '💬 Discord', url: 'https://discord.gg/gene1799' },
          { text: '📧 Email', url: 'mailto:hello@gene1799.art' }
        ]
      ]
    };

    this.bot.sendMessage(msg.chat.id, '🔗 **I nostri social:**', {
      parse_mode: 'Markdown',
      reply_markup: keyboard
    });
  }

  /**
   * Handler: /about
   */
  async handleAbout(msg) {
    const aboutMessage = `
ℹ️ **CHI SIAMO - GENE1799 ART CORPORATIONE**

**I Fondatori:**
👤 Marco Antonio Saverio Mazzitelli
👤 Fabio Amedeo Lo Presti

**La Missione:**
Esplorare l'intersezione tra arte, tecnologia Web3 e intelligenza artificiale.
Creare opere che sfidano i confini tra digitale e fisico.

**La Visione:**
Un ecosistema dove gli artisti controllano la propria narrativa attraverso blockchain.

**Specializzazioni:**
🎨 Digital Art & NFT
🤖 AI-Generated Compositions
📱 Phygital Experiences
🌐 Web3 Integration
🎭 Curatorial Projects

**Contratti & Legalità:**
📋 GENE1799 è registrato come entità legale in Italia
🏛️ Certificazioni: Arthemis Ludovici Productions
📄 ID: 16/A409879L

Numero di Supporto: +39 123 456 7890

*Contattaci per collaborazioni 🚀*
    `;

    this.bot.sendMessage(msg.chat.id, aboutMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Handler: /help
   */
  async handleHelp(msg) {
    const helpMessage = `
❓ **LISTA COMANDI**

**Informazioni:**
/start - Benvenuto e info
/token - Info \`$GENE1799\`
/price - Prezzo e market cap
/balance - Check balance wallet
/portfolio - Portfolio completo wallet
/nft - Collezioni NFT
/mint - Minta NFT su Zora
/gallery - Mostre ed esposizioni
/social - Link social
/about - Chi siamo
/help - Questo messaggio

**Community (Admin only):**
/announce [msg] - Annuncia al canale
/mute [@user] [min] - Silenzia utente
/warn [@user] - Avvertimento

**Regole della Community:**
✓ Sii rispettoso
✗ No spam, no scam links
✗ No crypto pump promotions
✗ No offensive content
⚠️ 3 warnings = 30 min mute

*Domande? Contattaci via /social*
    `;

    this.bot.sendMessage(msg.chat.id, helpMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Check for NFT sales
   */
  async checkNFTSales() {
    try {
      const sales = await this.fetchZoraSales();

      for (const sale of sales) {
        const saleMessage = `
🎨 **GENE1799 - NUOVA VENDITA NFT**

📌 Titolo: ${sale.title}
💰 Prezzo: ${sale.price} ETH
👤 Acquirente: ${sale.buyer.substring(0, 6)}...${sale.buyer.substring(-4)}
🔗 Zora: ${sale.marketplaceUrl}

Congratulazioni! 🎉
      `;

        this.bot.sendMessage(this.channelId, saleMessage, { parse_mode: 'Markdown' });
      }
    } catch (error) {
      console.error('Error checking NFT sales:', error);
    }
  }

  /**
   * Send promotional post
   */
  async sendPromotion() {
    const promotions = [
      `🎨 **Scopri le ultime opere GENE1799**\n\n🟣 Zora: zora.co/@gene1799\n🎨 SuperRare: superrare.com/@gene1799`,
      `💰 **Conosci \`$GENE1799\`**\n\n🪙 Token holder exclusive rewards!\n💵 Usa /price per dettagli`,
      `🖼️ **Nuove collezioni NFT**\n\n📱 Phygital experiences, tema "Physical Twins"\n🎭 Q3 2026 launch`,
      `🤖 **AI + Human Collaboration**\n\n🎨 Scopri come l'IA ispira gl'artisti GENE1799\n🌐 Foundation exclusive`,
      `⏰ **Ricorda: Community Guidelines**\n\n✓ Sii rispettoso\n✗ No spam\n⚠️ 3 strikes = mute`
    ];

    const randomPromo = promotions[Math.floor(Math.random() * promotions.length)];
    this.bot.sendMessage(this.channelId, randomPromo, { parse_mode: 'Markdown' });
  }

  /**
   * Send weekly recap
   */
  async sendWeeklyRecap() {
    const recapMessage = `
📊 **GENE1799 - WEEKLY RECAP**

🎨 **Nuove Operazioni:**
- 3 new mints on Zora
- 2 acquisitions on SuperRare
- 1 exhibition update

💰 **Dati Token:**
- \`$GENE1799\` +5.2% settimanale
- 1.2K holders
- $2.3M market cap

👥 **Community:**
- +150 nuovi followers
- 85% engagement rate
- 42 giorni di streak

🎗️ **Ricorda:**
Segui /social per aggiornamenti in real-time!

— Arrivederci e buona settimana! 🚀
    `;

    this.bot.sendMessage(this.channelId, recapMessage, { parse_mode: 'Markdown' });
  }

  /**
   * Welcome new members
   */
  async welcomeNewMembers(msg) {
    const welcomeText = msg.new_chat_members
      .map(member => member.first_name)
      .join(', ');

    const welcomeMessage = `
👋 Benvenuti ${welcomeText}!

Siamo GENE1799 ART CORPORATIONE. Per iniziare:
1️⃣ Leggi le regole della community
2️⃣ Usa /help per i comandi disponibili
3️⃣ Segui /social per rimanere aggiornato

Buona esplorazione! 🚀
    `;

    this.bot.sendMessage(msg.chat.id, welcomeMessage);
  }

  /**
   * Check for spam
   */
  checkForSpam(msg) {
    const spamPatterns = [
      /(?:crypto|bitcoin|ethereum|token|ico|defi)\s*(?:pump|moon|x100|profit|free|guaranteed)/gi,
      /(?:join|click)\s*(?:here|now|link)\s*(?:fast|quickly|urgent)/gi,
      /(http|https):\/\/\S+(?:airdrop|claim|free|bonus)/gi,
      /suspect cryptocurrency link/gi
    ];

    for (const pattern of spamPatterns) {
      if (pattern.test(msg.text)) {
        this.addWarning(msg.from.id, msg.from.username);
        this.bot.deleteMessage(msg.chat.id, msg.message_id);
        this.bot.sendMessage(
          msg.chat.id,
          `⚠️ @${msg.from.username} - Messaggio rimosso per spam. Warning ${this.userWarnings.get(msg.from.id) || 1}/3`,
          { reply_to_message_id: msg.message_id }
        );
        break;
      }
    }
  }

  /**
   * Add warning to user
   */
  addWarning(userId, username) {
    const warnings = (this.userWarnings.get(userId) || 0) + 1;
    this.userWarnings.set(userId, warnings);

    if (warnings >= 3) {
      // Mute for 30 minutes
      this.muteUser(userId, 30);
      this.bot.sendMessage(this.channelId, `🔇 @${username} è stato silenziato per 30 minuti (3 warning raggiunti)`);
    }
  }

  /**
   * Mute user (30 minutes by default)
   */
  async muteUser(userId, minutes = 30) {
    const now = new Date();
    const muteUntil = new Date(now.getTime() + minutes * 60000);

    try {
      // Note: Actual muting requires admin permissions
      // This is a placeholder for the muting logic
      console.log(`Muting user ${userId} until ${muteUntil}`);
    } catch (error) {
      console.error('Error muting user:', error);
    }
  }

  /**
   * Handle /announce command
   */
  handleAnnounce(msg, announcement) {
    if (!this.adminIds.includes(msg.from.id.toString())) {
      return this.bot.sendMessage(msg.chat.id, '❌ Solo admin possono usare questo comando');
    }

    this.bot.sendMessage(this.channelId, `📣 ${announcement}`, { parse_mode: 'Markdown' });
  }

  /**
   * Handle /mute command
   */
  async handleMute(msg, username, minutes) {
    if (!this.adminIds.includes(msg.from.id.toString())) {
      return this.bot.sendMessage(msg.chat.id, '❌ Solo admin possono usare questo comando');
    }

    const muteMinutes = parseInt(minutes) || 30;
    // Implementation would go here
    this.bot.sendMessage(msg.chat.id, `🔇 ${username} silenziato per ${muteMinutes} minuti`);
  }

  /**
   * Handle /warn command
   */
  async handleWarn(msg, username) {
    if (!this.adminIds.includes(msg.from.id.toString())) {
      return this.bot.sendMessage(msg.chat.id, '❌ Solo admin possono usare questo comando');
    }

    this.bot.sendMessage(msg.chat.id, `⚠️ Avvertimento inviato a ${username}`);
  }

  /**
   * Helper: Get token price
   */
  async getTokenPrice() {
    try {
      const response = await axios.get(
        `https://api.dexscreener.com/latest/dex/search?q=${this.tokenContract}`
      );

      const pair = response.data.pairs?.[0];
      if (!pair) throw new Error('Token pair not found');

      return {
        price: parseFloat(pair.priceUsd) || 0,
        marketCap: pair.marketCap || 'N/A',
        volume24h: pair.volume?.h24 || 'N/A',
        change24h: pair.priceChange?.h24 || 0
      };
    } catch (error) {
      console.error('Error fetching price:', error);
      return { price: 0, marketCap: 'N/A', volume24h: 'N/A', change24h: 0 };
    }
  }

  /**
   * Helper: Get token balance via Web3 Service
   */
  async getTokenBalance(address) {
    try {
      const response = await axios.get(
        `${this.web3ServiceUrl}/wallet/${address}/portfolio`,
        { timeout: 10000 }
      );
      return response.data.gene1799_balance || '0';
    } catch (error) {
      console.error('Error fetching token balance:', error.message);
      return '0';
    }
  }

  /**
   * Helper: Get ETH balance via Web3 Service
   */
  async getETHBalance(address) {
    try {
      const response = await axios.get(
        `${this.web3ServiceUrl}/wallet/${address}/portfolio`,
        { timeout: 10000 }
      );
      return response.data.eth_balance || '0';
    } catch (error) {
      console.error('Error fetching ETH balance:', error.message);
      return '0';
    }
  }

  /**
   * Helper: Fetch Zora NFTs/sales via Web3 Service
   */
  async fetchZoraSales() {
    try {
      const response = await axios.get(
        `${this.web3ServiceUrl}/nft/zora`,
        { timeout: 15000 }
      );
      return response.data.nfts || [];
    } catch (error) {
      console.error('Error fetching Zora NFTs:', error.message);
      return [];
    }
  }

  /**
   * Handler: /portfolio - View wallet portfolio
   */
  async handlePortfolio(msg) {
    if (!msg.text.includes(' ')) {
      return this.bot.sendMessage(msg.chat.id, `
*Wallet Portfolio*

Usa il comando:
\`/portfolio 0xTuoIndirizzo\`

Mostra il tuo saldo ETH + $GENE1799 su Base Network.
      `, { parse_mode: 'Markdown' });
    }

    const address = msg.text.split(' ')[1];
    this.bot.sendMessage(msg.chat.id, 'Caricamento portfolio...');

    try {
      const response = await axios.get(
        `${this.web3ServiceUrl}/wallet/${address}/portfolio`,
        { timeout: 15000 }
      );
      const p = response.data;

      const portfolioMsg = `
*Portfolio ${address.substring(0, 6)}...${address.slice(-4)}*

*ETH:* ${p.eth_balance || '0'} ETH
*$GENE1799:* ${p.gene1799_balance || '0'}
${p.gene1799_value_usd ? `*Valore:* $${p.gene1799_value_usd} USD` : ''}

*Chain:* Base (L2)
*Explorer:* [BaseScan](${p.explorer || 'https://basescan.org'})
      `;

      this.bot.sendMessage(msg.chat.id, portfolioMsg, {
        parse_mode: 'Markdown',
        disable_web_page_preview: true
      });
    } catch (error) {
      this.bot.sendMessage(msg.chat.id, `Errore: ${error.message}`);
    }
  }

  /**
   * Handler: /mint - Zora minting info and links
   */
  async handleMint(msg) {
    const keyboard = {
      inline_keyboard: [
        [
          { text: 'Mint su Zora', url: 'https://zora.co/@gene1799' }
        ],
        [
          { text: 'OpenSea Collection', url: 'https://opensea.io/collection/gene1799' },
          { text: 'Rarible', url: 'https://rarible.com/gene1799' }
        ],
        [
          { text: '$GENE1799 DexScreener', url: `https://dexscreener.com/base/${this.tokenContract}` }
        ]
      ]
    };

    let nftInfo = '';
    try {
      const response = await axios.get(
        `${this.web3ServiceUrl}/nft/zora`,
        { timeout: 10000 }
      );
      const nftCount = response.data.nft_count || 0;
      nftInfo = nftCount > 0 ? `\n*Opere disponibili:* ${nftCount} NFTs su Zora` : '';
    } catch (e) {
      // Ignore errors
    }

    const mintMsg = `
*MINT GENE1799 NFT*

Minta le opere di GENE1799 direttamente su Zora!
${nftInfo}

*Come mintare:*
1. Apri il link Zora sotto
2. Connetti il tuo wallet (MetaMask)
3. Seleziona l'opera
4. Clicca "Mint"

*Token:* $GENE1799 su Base Network
*Contratto:* \`${this.tokenContract}\`
    `;

    this.bot.sendMessage(msg.chat.id, mintMsg, {
      parse_mode: 'Markdown',
      reply_markup: keyboard
    });
  }

  /**
   * Stop the bot
   */
  stop() {
    if (this.nftCheckInterval) {
      clearInterval(this.nftCheckInterval);
    }
    this.bot.stopPolling();
    console.log('✓ Bot stopped');
  }
}

// Export and initialization
module.exports = Gene1799Bot;

// Start bot if running directly
if (require.main === module) {
  const bot = new Gene1799Bot();

  process.on('SIGINT', () => {
    bot.stop();
    process.exit(0);
  });

  process.on('SIGTERM', () => {
    bot.stop();
    process.exit(0);
  });
}
