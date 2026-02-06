/**
 * ████████████████████████████████████████████████████████
 * █ GENE1799 ART CORPORATIONE - TELEGRAM BOT             █
 * █ Features:                                              █
 * █  1. NFT Sale Notifications (Zora/Base events)          █
 * █  2. $GENE1799 Token Info Commands                      █
 * █  3. Community Auto-Management                          █
 * █  4. Automated Content Promotion                        █
 * ████████████████████████████████████████████████████████
 * 
 * Deploy on Render.com as a Background Worker
 * 
 * ENV VARIABLES REQUIRED:
 *   BOT_TOKEN          - Telegram Bot Token (from @BotFather)
 *   CHANNEL_ID         - Your Telegram channel/group ID
 *   ADMIN_IDS          - Comma-separated admin Telegram user IDs
 *   BASE_RPC_URL       - Base network RPC (default: https://mainnet.base.org)
 *   TOKEN_CONTRACT     - $GENE1799 contract address
 *   ZORA_CREATOR       - Your Zora creator address
 */

const { Telegraf, Markup } = require('telegraf');
const { ethers } = require('ethers');
const cron = require('node-cron');
const fetch = require('node-fetch');

// ═══════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════

const CONFIG = {
  botToken: process.env.BOT_TOKEN,
  channelId: process.env.CHANNEL_ID || '',
  adminIds: (process.env.ADMIN_IDS || '').split(',').map(id => parseInt(id.trim())).filter(Boolean),
  baseRpc: process.env.BASE_RPC_URL || 'https://mainnet.base.org',
  tokenContract: process.env.TOKEN_CONTRACT || '0x63800f370b04ce132333c05d811663b80cec788e',
  zoraCreator: process.env.ZORA_CREATOR || 'gene1799',
  
  // Content for auto-promotion
  websiteUrl: 'https://gene1799artcorporatione.mom',
  zoraUrl: 'https://zora.co/@gene1799',
  superrareUrl: 'https://superrare.com/gen_e1799',
  discordUrl: 'https://discord.gg/n8wd7bW7',
  instagramUrl: 'https://www.instagram.com/gen.e1799',
  twitterUrl: 'https://x.com/@marco441441',
  
  // Anti-spam
  maxWarnings: 3,
  muteMinutes: 30,
  
  // Token ABI
  tokenAbi: [
    'function balanceOf(address) view returns (uint256)',
    'function decimals() view returns (uint8)',
    'function symbol() view returns (string)',
    'function name() view returns (string)',
    'function totalSupply() view returns (uint256)',
    'event Transfer(address indexed from, address indexed to, uint256 value)'
  ]
};

// Validate required config
if (!CONFIG.botToken) {
  console.error('❌ BOT_TOKEN environment variable is required!');
  console.log('Get your token from @BotFather on Telegram');
  process.exit(1);
}

// ═══════════════════════════════════════════
// INITIALIZE
// ═══════════════════════════════════════════

const bot = new Telegraf(CONFIG.botToken);
const provider = new ethers.providers.JsonRpcProvider(CONFIG.baseRpc);
const tokenContract = new ethers.Contract(CONFIG.tokenContract, CONFIG.tokenAbi, provider);

// State
const userWarnings = new Map(); // userId -> warning count
const lastSaleBlock = { value: 0 };

// ═══════════════════════════════════════════
// 1. COMMANDS - Token Info & General
// ═══════════════════════════════════════════

bot.command('start', (ctx) => {
  const welcomeMsg = `
🎨 *GENE1799 ART CORPORATIONE*
━━━━━━━━━━━━━━━━━━━━━━━━━
Benvenuto nel bot ufficiale!

*Comandi disponibili:*

💰 /token — Info $GENE1799
📊 /price — Prezzo e market cap
👛 /balance \\<address\\> — Check balance
🎨 /nft — Ultime collezioni NFT
🏛️ /gallery — Link gallerie
📢 /social — Tutti i social
ℹ️ /about — Chi siamo
🆘 /help — Lista comandi

*Fondatori:*
Marco Antonio Saverio Mazzitelli
Fabio Amedeo Lo Presti
_16/A409879L — Arthemis Ludovici Productions_
━━━━━━━━━━━━━━━━━━━━━━━━━
  `;

  ctx.replyWithMarkdownV2(escapeMarkdown(welcomeMsg), Markup.inlineKeyboard([
    [Markup.button.url('🌐 Website', CONFIG.websiteUrl)],
    [Markup.button.url('🎨 Zora', CONFIG.zoraUrl), Markup.button.url('💎 SuperRare', CONFIG.superrareUrl)],
    [Markup.button.url('💬 Discord', CONFIG.discordUrl)]
  ]));
});

bot.command('token', async (ctx) => {
  try {
    const [name, symbol, decimals, totalSupply] = await Promise.all([
      tokenContract.name(),
      tokenContract.symbol(),
      tokenContract.decimals(),
      tokenContract.totalSupply()
    ]);

    const supply = ethers.utils.formatUnits(totalSupply, decimals);

    const msg = `
💰 *$${symbol} TOKEN INFO*
━━━━━━━━━━━━━━━━━━━━━━━━━
📛 Nome: ${name}
🏷️ Simbolo: $${symbol}
⛓️ Network: Base (Chain ID: 8453)
📊 Total Supply: ${parseFloat(supply).toLocaleString()}
📝 Contratto: \`${CONFIG.tokenContract}\`
━━━━━━━━━━━━━━━━━━━━━━━━━
    `;

    ctx.replyWithMarkdownV2(escapeMarkdown(msg), Markup.inlineKeyboard([
      [Markup.button.url('📊 BaseScan', `https://basescan.org/address/${CONFIG.tokenContract}`)],
      [Markup.button.url('💱 DEX', `https://app.uniswap.org/#/swap?outputCurrency=${CONFIG.tokenContract}&chain=base`)]
    ]));
  } catch (error) {
    ctx.reply('❌ Errore nel recupero dati token. Riprova più tardi.');
    console.error('Token info error:', error);
  }
});

bot.command('balance', async (ctx) => {
  const args = ctx.message.text.split(' ');
  const address = args[1];

  if (!address || !ethers.utils.isAddress(address)) {
    return ctx.reply('⚠️ Usa: /balance <indirizzo_wallet>\nEsempio: /balance 0x1234...abcd');
  }

  try {
    const balance = await tokenContract.balanceOf(address);
    const decimals = await tokenContract.decimals();
    const formatted = ethers.utils.formatUnits(balance, decimals);

    ctx.replyWithMarkdownV2(escapeMarkdown(`
👛 *BALANCE CHECK*
━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Address: \`${address.slice(0, 8)}...${address.slice(-6)}\`
💰 Balance: ${parseFloat(formatted).toLocaleString()} $GENE1799
━━━━━━━━━━━━━━━━━━━━━━━━━
    `));
  } catch (error) {
    ctx.reply('❌ Errore nel check del balance. Verifica l\'indirizzo.');
  }
});

bot.command('price', async (ctx) => {
  try {
    // Try to get price from DEX (DexScreener API)
    const response = await fetch(
      `https://api.dexscreener.com/latest/dex/tokens/${CONFIG.tokenContract}`
    );
    const data = await response.json();
    const pair = data.pairs?.[0];

    if (pair) {
      ctx.replyWithMarkdownV2(escapeMarkdown(`
📊 *$GENE1799 PRICE*
━━━━━━━━━━━━━━━━━━━━━━━━━
💲 Prezzo: $${parseFloat(pair.priceUsd).toFixed(6)}
📈 24h: ${pair.priceChange?.h24 || 'N/A'}%
💧 Liquidità: $${parseFloat(pair.liquidity?.usd || 0).toLocaleString()}
📊 Volume 24h: $${parseFloat(pair.volume?.h24 || 0).toLocaleString()}
🏦 Market Cap: $${parseFloat(pair.fdv || 0).toLocaleString()}
━━━━━━━━━━━━━━━━━━━━━━━━━
      `));
    } else {
      ctx.reply('📊 Dati di prezzo non ancora disponibili su DEX. Il token potrebbe non essere ancora listato.');
    }
  } catch (error) {
    ctx.reply('❌ Errore nel recupero del prezzo. Riprova più tardi.');
  }
});

bot.command('nft', (ctx) => {
  ctx.replyWithMarkdownV2(escapeMarkdown(`
🎨 *NFT COLLECTIONS*
━━━━━━━━━━━━━━━━━━━━━━━━━
Scopri le opere di Gene1799 sui migliori marketplace:
  `), Markup.inlineKeyboard([
    [Markup.button.url('🟣 Zora', CONFIG.zoraUrl)],
    [Markup.button.url('💎 SuperRare', CONFIG.superrareUrl)],
    [Markup.button.url('🔶 Crypto.com', 'https://crypto.com/nft/profile/gen_e1799?tab=created')],
    [Markup.button.url('🟤 Foundation', 'https://foundation.app/@gen_e1799')],
    [Markup.button.url('🔵 OpenSea', 'https://opensea.io/gen_e1799')],
    [Markup.button.url('🟡 Rarible', 'https://og.rarible.com/gen_e1799/owned')]
  ]));
});

bot.command('gallery', (ctx) => {
  ctx.replyWithMarkdownV2(escapeMarkdown(`
🏛️ *GALLERY & EXHIBITIONS*
━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Miami Basel 2023 — "Attacchi di Panico"
📍 NFT.NYC 2024 — "Avana Syndrome"  
📍 Oculus NYC Dicembre 2024
📍 Pechino 2025
📍 Parigi 2025
📕 Annuario Mondadori 2025
━━━━━━━━━━━━━━━━━━━━━━━━━
Art Innovation Gallery • The Hug • ArtBoxy • Effetto Arte
  `));
});

bot.command('social', (ctx) => {
  ctx.replyWithMarkdownV2(escapeMarkdown(`
📢 *SOCIAL & COMMUNITY*
━━━━━━━━━━━━━━━━━━━━━━━━━
Seguici ovunque!
  `), Markup.inlineKeyboard([
    [Markup.button.url('📸 Instagram', CONFIG.instagramUrl)],
    [Markup.button.url('🐦 Twitter/X', CONFIG.twitterUrl)],
    [Markup.button.url('💬 Discord', CONFIG.discordUrl)],
    [Markup.button.url('🎬 YouTube', 'https://www.youtube.com/@gene1799artcorporatione')],
    [Markup.button.url('🎵 TikTok', 'https://www.tiktok.com/@gen_e1799')],
    [Markup.button.url('💼 LinkedIn', 'https://www.linkedin.com/in/marco-mazzitelli-704a54130/')],
    [Markup.button.url('📘 Facebook', 'https://www.facebook.com/Gen.e1799')]
  ]));
});

bot.command('about', (ctx) => {
  ctx.replyWithMarkdownV2(escapeMarkdown(`
ℹ️ *ABOUT GENE1799 ART CORPORATIONE*
━━━━━━━━━━━━━━━━━━━━━━━━━
Marco Mazzitelli (Gen_e1799) — artista digitale italiano, fondatore di Gene1799ArtCorporatione.

Dal 2007 crea opere ibride: tecnica manuale + digitale + AI.

🎨 Tecnologie: Smartphone Art, rendering 3D, Meta AI, blockchain NFT

🏛️ Esposizioni: Art Innovation Gallery (Miami Basel, NFT.NYC), Oculus NYC, Pechino, Parigi

📕 Annuario Artisti Contemporanei Mondadori 2025

⛓️ $GENE1799 Token su Base Network

Fondato da:
• Marco Antonio Saverio Mazzitelli
• Fabio Amedeo Lo Presti
Reg: 16/A409879L
Arthemis Ludovici Productions
━━━━━━━━━━━━━━━━━━━━━━━━━
  `));
});

bot.command('help', (ctx) => {
  ctx.reply(`
🆘 COMANDI DISPONIBILI:

💰 /token — Info token $GENE1799
📊 /price — Prezzo e market cap  
👛 /balance <address> — Check balance
🎨 /nft — Link collezioni NFT
🏛️ /gallery — Mostre ed esposizioni
📢 /social — Tutti i link social
ℹ️ /about — Chi siamo
🆘 /help — Questa lista

ADMIN:
🔧 /stats — Statistiche gruppo (admin)
📣 /promote — Post promozionale (admin)
  `);
});

// ═══════════════════════════════════════════
// 2. NFT SALE NOTIFICATIONS
// ═══════════════════════════════════════════

/**
 * Monitor Transfer events on known NFT contracts
 * and notify the channel when a sale occurs
 */
async function startNFTMonitor() {
  console.log('🔍 Starting NFT sale monitor...');

  // Monitor ERC-721 Transfer events on Base
  const transferTopic = ethers.utils.id('Transfer(address,address,uint256)');
  
  // Poll every 30 seconds for new events
  setInterval(async () => {
    try {
      const currentBlock = await provider.getBlockNumber();
      const fromBlock = lastSaleBlock.value || currentBlock - 100;
      
      if (fromBlock >= currentBlock) return;

      // Check for Zora mint/sale events via API
      const sales = await checkZoraSales();
      
      for (const sale of sales) {
        await notifySale(sale);
      }

      lastSaleBlock.value = currentBlock;
    } catch (error) {
      console.error('NFT monitor error:', error);
    }
  }, 30000);
}

async function checkZoraSales() {
  try {
    const response = await fetch(
      `https://api.zora.co/discover/tokens?creatorAddresses[]=${CONFIG.zoraCreator}&sortKey=CREATED&sortDirection=DESC&limit=5`,
      { headers: { 'Accept': 'application/json' } }
    );
    
    if (!response.ok) return [];
    
    const data = await response.json();
    const recentSales = [];
    
    for (const token of (data.results || [])) {
      const mintedAt = new Date(token.mintedAt || 0);
      const fiveMinAgo = new Date(Date.now() - 5 * 60000);
      
      if (mintedAt > fiveMinAgo) {
        recentSales.push({
          title: token.name || 'New NFT',
          collection: token.collectionName || '',
          buyer: token.owner || 'Unknown',
          price: token.mintPrice || '0',
          platform: 'Zora',
          url: `https://zora.co/collect/${token.collectionAddress}/${token.tokenId}`,
          image: token.image?.url || ''
        });
      }
    }
    
    return recentSales;
  } catch {
    return [];
  }
}

async function notifySale(sale) {
  if (!CONFIG.channelId) return;

  const msg = `
🎉 *NUOVA VENDITA NFT!*
━━━━━━━━━━━━━━━━━━━━━━━━━
🖼️ ${sale.title}
📦 ${sale.collection}
💰 ${sale.price} ETH
👤 Acquirente: ${sale.buyer.slice(0, 8)}...
🏪 ${sale.platform}
━━━━━━━━━━━━━━━━━━━━━━━━━
  `;

  try {
    await bot.telegram.sendMessage(CONFIG.channelId, escapeMarkdown(msg), {
      parse_mode: 'MarkdownV2',
      reply_markup: {
        inline_keyboard: [[
          { text: '🔗 Vedi NFT', url: sale.url }
        ]]
      }
    });
  } catch (error) {
    console.error('Notification send error:', error);
  }
}

// ═══════════════════════════════════════════
// 3. COMMUNITY MANAGEMENT
// ═══════════════════════════════════════════

// Welcome new members
bot.on('new_chat_members', (ctx) => {
  const newMembers = ctx.message.new_chat_members;
  for (const member of newMembers) {
    if (member.is_bot) continue;
    
    const name = member.first_name || 'Nuovo membro';
    ctx.replyWithMarkdownV2(escapeMarkdown(`
🎨 *Benvenuto/a ${name}!*

Entra nella community Gene1799 Art Corporatione!

Usa /start per scoprire tutti i comandi.
Usa /nft per esplorare le collezioni.
Usa /token per info su $GENE1799.

Regole: rispetto, no spam, no scam ✨
    `));
  }
});

// Anti-spam: detect and warn/mute spammers
bot.on('message', async (ctx, next) => {
  const msg = ctx.message;
  if (!msg || !msg.from) return next();
  
  const userId = msg.from.id;
  
  // Skip admins
  if (CONFIG.adminIds.includes(userId)) return next();
  
  // Check for spam patterns
  const text = (msg.text || '').toLowerCase();
  const isSpam = detectSpam(text, msg);
  
  if (isSpam) {
    const warnings = (userWarnings.get(userId) || 0) + 1;
    userWarnings.set(userId, warnings);
    
    if (warnings >= CONFIG.maxWarnings) {
      // Mute user
      try {
        await ctx.restrictChatMember(userId, {
          until_date: Math.floor(Date.now() / 1000) + CONFIG.muteMinutes * 60,
          permissions: { can_send_messages: false }
        });
        ctx.reply(`🔇 ${msg.from.first_name} mutato per ${CONFIG.muteMinutes} minuti (spam).`);
        userWarnings.delete(userId);
      } catch (e) {
        console.error('Mute error:', e);
      }
    } else {
      ctx.reply(`⚠️ ${msg.from.first_name}, avviso ${warnings}/${CONFIG.maxWarnings}. No spam!`);
    }
    
    // Try to delete spam message
    try { await ctx.deleteMessage(); } catch (e) { /* may lack permissions */ }
    return;
  }
  
  return next();
});

function detectSpam(text, msg) {
  // Known spam patterns
  const spamPatterns = [
    /free\s*(airdrop|crypto|money|bitcoin|eth)/i,
    /click\s*here.*wallet/i,
    /connect.*wallet.*claim/i,
    /send.*eth.*receive.*back/i,
    /double.*your.*(money|crypto|eth)/i,
    /t\.me\/(?!gene1799)/i, // Telegram links to other groups
    /bit\.ly|tinyurl|shorturl/i, // Shortened URLs (suspicious)
    /whatsapp\.com\/channel/i,
  ];
  
  for (const pattern of spamPatterns) {
    if (pattern.test(text)) return true;
  }
  
  // Check for excessive links
  const linkCount = (text.match(/https?:\/\//g) || []).length;
  if (linkCount > 3) return true;
  
  // Check for forwarded messages from channels (common spam)
  if (msg.forward_from_chat && msg.forward_from_chat.type === 'channel') return true;
  
  return false;
}

// Admin: Stats command
bot.command('stats', async (ctx) => {
  if (!CONFIG.adminIds.includes(ctx.from.id)) {
    return ctx.reply('❌ Solo admin possono usare questo comando.');
  }
  
  try {
    const chatInfo = await ctx.getChat();
    const memberCount = await ctx.getChatMembersCount();
    
    ctx.reply(`
📊 STATISTICHE GRUPPO
━━━━━━━━━━━━━━━━━━━━
👥 Membri: ${memberCount}
📛 Nome: ${chatInfo.title || 'N/A'}
⚠️ Utenti avvisati: ${userWarnings.size}
🤖 Bot attivo da: ${new Date().toISOString().split('T')[0]}
━━━━━━━━━━━━━━━━━━━━
    `);
  } catch (error) {
    ctx.reply('❌ Errore nel recupero statistiche.');
  }
});

// ═══════════════════════════════════════════
// 4. AUTOMATED CONTENT PROMOTION
// ═══════════════════════════════════════════

const promotionalMessages = [
  {
    text: `🎨 *Scopri le opere di Gene1799!*\n\nArte digitale unica su Zora — mint, colleziona, investi.\n\n💎 Ogni NFT è un pezzo di storia dell'arte digitale italiana.`,
    buttons: [[{ text: '🎨 Esplora su Zora', url: CONFIG.zoraUrl }]]
  },
  {
    text: `💰 *$GENE1799 Token su Base*\n\nIl token ufficiale della community artistica.\n\n⛓️ Base Network | Commissioni basse | Community-driven`,
    buttons: [[{ text: '📊 Vedi su BaseScan', url: `https://basescan.org/address/${CONFIG.tokenContract}` }]]
  },
  {
    text: `🏛️ *Esposizioni Internazionali*\n\n📍 Miami Basel 2023\n📍 NFT.NYC 2024\n📍 Pechino 2025\n📍 Parigi 2025\n\nL'arte italiana nel mondo! 🇮🇹`,
    buttons: [[{ text: '🌐 Sito Web', url: CONFIG.websiteUrl }]]
  },
  {
    text: `🖼️ *SuperRare Collection*\n\nOpere curate, certificate, uniche.\nDai CryptoPunks a Beeple — Gene1799 tra i grandi.\n\nArt Innovation Gallery certified.`,
    buttons: [[{ text: '💎 Vedi su SuperRare', url: CONFIG.superrareUrl }]]
  },
  {
    text: `📢 *Unisciti alla Community!*\n\n🎨 Artisti digitali\n💻 Sviluppatori blockchain\n🔮 Visionari Web3\n💎 Collezionisti NFT\n\nIl futuro dell'arte si costruisce insieme.`,
    buttons: [
      [{ text: '💬 Discord', url: CONFIG.discordUrl }],
      [{ text: '📸 Instagram', url: CONFIG.instagramUrl }, { text: '🐦 Twitter', url: CONFIG.twitterUrl }]
    ]
  }
];

let promoIndex = 0;

async function sendScheduledPromo() {
  if (!CONFIG.channelId) {
    console.log('⚠️ CHANNEL_ID not set, skipping promo');
    return;
  }

  const promo = promotionalMessages[promoIndex % promotionalMessages.length];
  promoIndex++;

  try {
    await bot.telegram.sendMessage(CONFIG.channelId, escapeMarkdown(promo.text), {
      parse_mode: 'MarkdownV2',
      reply_markup: { inline_keyboard: promo.buttons }
    });
    console.log(`📢 Promo sent: #${promoIndex}`);
  } catch (error) {
    console.error('Promo send error:', error);
  }
}

// Admin: manual promote
bot.command('promote', async (ctx) => {
  if (!CONFIG.adminIds.includes(ctx.from.id)) {
    return ctx.reply('❌ Solo admin.');
  }
  await sendScheduledPromo();
  ctx.reply('✅ Post promozionale inviato!');
});

// ═══════════════════════════════════════════
// SCHEDULED TASKS (CRON)
// ═══════════════════════════════════════════

// Auto-promote every day at 10:00 and 18:00 (Rome time)
cron.schedule('0 10,18 * * *', () => {
  console.log('⏰ Scheduled promo trigger');
  sendScheduledPromo();
}, { timezone: 'Europe/Rome' });

// Weekly recap every Monday at 9:00
cron.schedule('0 9 * * 1', async () => {
  if (!CONFIG.channelId) return;
  
  try {
    const tokenInfo = await getTokenSummary();
    const msg = `
📅 *WEEKLY RECAP — Gene1799*
━━━━━━━━━━━━━━━━━━━━━━━━━
${tokenInfo}

🎨 Nuove opere ogni settimana su Zora!
💬 Unisciti alla community per non perdere nulla.
━━━━━━━━━━━━━━━━━━━━━━━━━
    `;
    
    await bot.telegram.sendMessage(CONFIG.channelId, escapeMarkdown(msg), {
      parse_mode: 'MarkdownV2'
    });
  } catch (error) {
    console.error('Weekly recap error:', error);
  }
}, { timezone: 'Europe/Rome' });

async function getTokenSummary() {
  try {
    const totalSupply = await tokenContract.totalSupply();
    const decimals = await tokenContract.decimals();
    return `💰 $GENE1799 Supply: ${parseFloat(ethers.utils.formatUnits(totalSupply, decimals)).toLocaleString()}`;
  } catch {
    return '💰 $GENE1799 — Controlla /token per i dettagli';
  }
}

// ═══════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════

function escapeMarkdown(text) {
  // Escape special characters for MarkdownV2
  // But preserve *bold* and `code` formatting
  return text
    .replace(/([_\[\]()~>#\+\-=|{}.!])/g, '\\$1');
}

// ═══════════════════════════════════════════
// LAUNCH
// ═══════════════════════════════════════════

async function main() {
  console.log(`
████████████████████████████████████████████████████████
█ GENE1799 ART CORPORATIONE - TELEGRAM BOT            █
█ Starting...                                          █
████████████████████████████████████████████████████████
  `);

  // Start NFT sale monitoring
  startNFTMonitor();

  // Start bot (polling mode for simplicity)
  bot.launch();
  console.log('✅ Bot is running!');

  // Graceful shutdown
  process.once('SIGINT', () => bot.stop('SIGINT'));
  process.once('SIGTERM', () => bot.stop('SIGTERM'));
}

main().catch(console.error);
