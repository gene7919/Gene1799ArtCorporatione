# GENE1799 ART CORPORATIONE - Guida di Setup Completa

## 🎯 Indice
1. [Configurazione Telegram Bot](#telegram-bot)
2. [Deploy su Render.com](#render-deploy)
3. [Configurazione WordPress](#wordpress)
4. [Setup DNS Porkbun](#dns-porkbun)
5. [Integrazione Web3](#web3-integration)
6. [GitHub Security](#github-security)
7. [Checklist Finale](#checklist)

---

## 🤖 Telegram Bot <a name="telegram-bot"></a>

### Step 1: Creare il Bot con @BotFather

1. Apri Telegram e cerca **@BotFather**
2. Invia comando: `/newbot`
3. Scegli nome: `Gene1799 Art Bot`
4. Scegli username: `gene1799_art_bot` (deve terminare con `_bot`)
5. Riceverai il **TOKEN** (formato: `123456789:ABCdefGhIJKlmNoPQRsTUVwxyz`)

### Step 2: Configurare i Comandi del Bot

Sempre in conversazione con @BotFather:

```
/setcommands

Incolla il seguente testo:

start - Benvenuto e info
token - Info $GENE1799
price - Prezzo e market cap
balance - Check balance wallet
nft - Collezioni NFT
gallery - Mostre ed esposizioni
social - Link social
about - Chi siamo
help - Lista comandi
```

### Step 3: Ottenere IDs Necessari

**Per CHANNEL_ID:**
1. Tuo canale/gruppo Telegram privato: `@gene1799announcements`
2. Aggiungi il bot al canale
3. Usa **@getidsbot** per ottenere l'ID (formato: `-100xxxxxxxxx`)

**Per ADMIN_IDS:**
1. Apri una chat privata con il bot
2. Usa **@getidsbot** su te stesso
3. Annota il tuo USERID

### Step 4: Configurare le Variabili d'Ambiente

Crea file `.env` in cartella `telegram-bot/`:

```env
BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRsTUVwxyz
CHANNEL_ID=-100XXXXXXXXX
ADMIN_IDS=123456789,987654321
BASE_RPC_URL=https://mainnet.base.org
TOKEN_CONTRACT=0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0
NODE_ENV=production
BOT_TIMEZONE=Europe/Rome
```

### Step 5: Testare Localmente

```bash
cd telegram-bot
npm install
npm start
```

Dovresti vedere:
```
✓ GENE1799 Telegram Bot initialized
✓ Scheduled tasks started
```

---

## 🚀 Deploy su Render.com <a name="render-deploy"></a>

### Step 1: Push su GitHub

```bash
git add .
git commit -m "feat: Aggiungi Telegram Bot e Web3 integration"
git push origin main
```

### Step 2: Connettere Render.com

1. Visita https://dashboard.render.com
2. Clicca **New > Background Worker**
3. Connetti il repository GitHub: `gene1799/Gene1799ArtCorporatione`
4. Configura:
   - **Name**: `gene1799-telegram-bot`
   - **Root Directory**: `telegram-bot`
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

### Step 3: Aggiungere Secrets

1. Vai a **Environment** nel dashboard Render
2. Aggiungi le seguenti variabili:
   - `BOT_TOKEN` = (dal @BotFather)
   - `CHANNEL_ID` = (da @getidsbot)
   - `ADMIN_IDS` = (il tuo ID)
   - `BASE_RPC_URL` = `https://mainnet.base.org`
   - `TOKEN_CONTRACT` = `0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0`
   - `NODE_ENV` = `production`

### Step 4: Deploy

1. Clicca **Deploy**
2. Aspetta 3-5 minuti
3. Verifica che sia online (deve dire "✓ Live")

---

## 🌐 Configurazione WordPress <a name="wordpress"></a>

### Step 1: Setup Iniziale

1. Visita `gene1799artcorporatione.mom/wp-admin`
2. Completa installazione guidata
3. **NON usare username `admin`** - usa `gene1799_admin`
4. Password: minimo 20 caratteri (misto maiuscole/minuscole/numeri/simboli)

### Step 2: Configurare wp-config.php

Apri file `wp-config.php` dal tuo hosting:

```php
// Cambia prefisso tabelle PRIMA dell'installazione
$table_prefix = 'g1799_';

// Aggiungi dopo linea: define('DB_COLLATE', '');
define('DISALLOW_FILE_EDIT', true);
define('FORCE_SSL_ADMIN', true);
define('FORCE_SSL_LOGIN', true);
define('FORCE_SSL', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('COOKIEHTTPONLY', true);
define('COOKIESECURE', true);
```

### Step 3: Aggiungere .htaccess

Upload `wordpress-security.conf` contenuto nel file `.htaccess` nella root del WordPress:

```
/public_html/.htaccess  oppure  /var/www/gene1799/.htaccess
```

### Step 4: Installare Plugin Essenziali

1. **Wordfence Security**
   - Settings > Firewall > Enable
   - Enable 2FA
   - Setup malware scanning

2. **WP-Optimize**
   - Enable caching
   - Setup automatic cleanup

3. **Yoast SEO**
   - Configure per il tuo sito

4. **WPCode**
   - Per inserire script Web3/NFT

### Step 5: Integrare Web3

In WPCode:
1. Vai a **WPCode > Header & Footer**
2. Nel **Header**, aggiungi:

```html
<script src="https://cdn.ethers.io/lib/ethers-5.7.umd.min.js"></script>
<script src="/wp-content/uploads/web3-integration.js"></script>
<script src="/wp-content/uploads/nft-loader.js"></script>
```

3. Crea pagina WordPress con shortcode:
```html
[web3_connect_button]
[nft_gallery]
```

---

## 🔐 Setup DNS Porkbun <a name="dns-porkbun"></a>

1. Vai su https://porkbun.com (pannello domini)
2. Clicca su `gene1799artcorporatione.mom`
3. Sezione **DNS** > **Advanced DNS**

### Record A (Hosting)
- **Subdomain**: `@` (root)
- **Type**: `A`
- **IP Address**: [Indirizzo IP del tuo hosting]
- **TTL**: `600`

### Record TXT - SPF
- **Subdomain**: `@`
- **Type**: `TXT`
- **Value**: `v=spf1 -all`
- **TTL**: `600`

### Record TXT - DMARC
- **Subdomain**: `_dmarc`
- **Type**: `TXT`
- **Value**: `v=DMARC1; p=quarantine; rua=mailto:security@gene1799artcorporatione.mom`

### CAA Record - SSL
- **Subdomain**: `@`
- **Type**: `CAA`
- **Value**:
  - `0 issue "letsencrypt.org"`
  - `0 issuewild "letsencrypt.org"`

### Sicurezza Avanzata

1. **DNSSEC**: Settings > Enable DNSSEC ✓
2. **Domain Lock**: Settings > Domain Lock ✓
3. **Anti-Transfer Locked**: Settings > Registration Lock ✓

### SSL Certificate

1. Porkbun > SSL Certificate > **Get Free Certificate**
2. Scegli Let's Encrypt
3. Auto-renewal abilitato
4. Prout certificato in 15 minuti

---

## 🔗 Integrazione Web3 <a name="web3-integration"></a>

### Testare Web3 Integration

Crea file HTML di test in WordPress:

```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.ethers.io/lib/ethers-5.7.umd.min.js"></script>
    <script src="/web3-integration.js"></script>
</head>
<body>
    <button id="connectBtn">Connetti MetaMask</button>
    <div id="userInfo"></div>

    <script>
        const web3 = new Gene1799Web3Integration({
            tokenContract: '0x63800f788e788e0d3a9cc0ce92a8e6c866f0f0f0'
        });

        document.getElementById('connectBtn').addEventListener('click', async () => {
            const result = await web3.connectWallet();
            if (result.success) {
                const info = await web3.getUserInfo();
                document.getElementById('userInfo').innerHTML = `
                    <p>Indirizzo: ${info.address}</p>
                    <p>Balance: ${info.tokenBalance} tokens</p>
                    <p>ETH: ${info.ethBalance}</p>
                `;
            }
        });
    </script>
</body>
</html>
```

### Integrare NFT Gallery

Aggiungi a WordPress:

```html
<div id="nft-gallery"></div>
<script src="/nft-loader.js"></script>
<script>
    const nftLoader = new Gene1799NFTLoader({
        artistAddress: 'gene1799',
        zoraUsername: 'gene1799'
    });

    nftLoader.loadAllNFTs().then(result => {
        if (result.zora?.success) {
            nftLoader.renderGallery(result.zora.nfts, 'nft-gallery');
        }
    });
</script>
```

---

## 🔐 GitHub Security <a name="github-security"></a>

### 1. Abilita 2FA

1. Vai https://github.com/settings/security
2. Clicca **Enable two-factor authentication**
3. Scegli **Authenticator app**
4. Usa Google Authenticator o Authy

### 2. Proteggi Branch Main

1. Vai Repository > **Settings > Branches**
2. Clicca **Add rule**
3. Configura:
   - Branch name pattern: `main`
   - ☑ Require pull request reviews
   - ☑ Require status checks to pass
   - ☑ Dismiss stale pull request approvals

### 3. Aggiungi Secrets GitHub

1. Repository > **Settings > Secrets > Actions**
2. Clicca **New repository secret**
3. Aggiungi:
   - `BOT_TOKEN` (Telegram)
   - `CHANNEL_ID`
   - `ADMIN_IDS`
   - `RENDER_API_KEY`

### 4. Verifica .gitignore

Assicurati che contenga:
```
.env
.env.local
node_modules/
dist/
*.log
.DS_Store
```

---

## ✅ Checklist Finale <a name="checklist"></a>

### Telegram Bot
- [ ] Token générés dal @BotFather
- [ ] Comandi configurati
- [ ] Channel ID e Admin ID ottenuti
- [ ] .env completato
- [ ] Bot testato localmente
- [ ] Deployato su Render
- [ ] Notifiche NFT funzionanti
- [ ] Comandi token funzionanti

### WordPress
- [ ] Installazione completata
- [ ] Username NON è `admin`
- [ ] Password 20+ caratteri
- [ ] wp-config.php aggiornato
- [ ] .htaccess caricato
- [ ] Plugin essenziali installati
- [ ] SSL attivo
- [ ] 2FA abilitato
- [ ] Web3 integration caricate
- [ ] NFT Gallery funzionante

### DNS / Porkbun
- [ ] Record A aggiunto
- [ ] SPF record aggiunto
- [ ] DMARC record aggiunto
- [ ] CAA record aggiunto
- [ ] DNSSEC abilitato
- [ ] Domain Lock abilitato
- [ ] SSL certificato attivo

### GitHub
- [ ] 2FA abilitato
- [ ] Branch protection configurato
- [ ] Secrets aggiunti
- [ ] .gitignore verificato
- [ ] Ultimo push completato

### Sicurezza Finale
- [ ] Firewall attivo su Wordfence
- [ ] Scan malware completato
- [ ] Backup automatici configurati
- [ ] Rate limiting abilitato
- [ ] Log monitoring attivo
- [ ] Uptime monitoring setup (UptimeRobot)

---

## 🆘 Troubleshooting

### Bot non risponde
```bash
# Verifica token
curl https://api.telegram.org/botTOKEN/getMe

# Verifica su Render
tail -f render.log
```

### Errore SSL
```bash
# Verifica certificato
openssl s_client -connect gene1799artcorporatione.mom:443
```

### Web3 non carica
Apri **Console Browser** (F12) e verifica:
```javascript
console.log(window.ethers)  // Deve non essere undefined
```

---

**Contatti Supporto:**
- 📧 Email: hello@gene1799.art
- 🐦 Twitter: @gene1799
- 💬 Discord: https://discord.gg/gene1799
- 📱 Telegram: @gene1799_art_bot

---

**Ultima Aggiornamento:** Febbraio 2026
**Versione:** 1.0.0
**Autori:** Marco Antonio Saverio Mazzitelli, Fabio Amedeo Lo Presti