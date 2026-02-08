# ⚡ GENE1799 Automation Quick Start

Automazione completa in 3 step.

## 🚀 Step 1: Esegui Setup (Windows)

```bash
# Doppio click su:
setup.bat

# Seleziona: 2 (Setup Interattivo)
# Rispondi alle domande (3 minuti)
```

**Cosa fa automaticamente:**
- ✓ Installa Telegram Bot
- ✓ Crea file .env
- ✓ npm install
- ✓ Push su GitHub
- ✓ Configura GitHub Actions

## 🎯 Step 2: Configura Render (Online)

1. Vai: https://dashboard.render.com
2. Clicca: "New > Background Worker"
3. Connetti GitHub repo
4. Root Directory: `telegram-bot`
5. Build: `npm install`
6. Start: `npm start`
7. Aggiungi Secrets (vedi sotto)

**Environment Variables da Render Dashboard:**
```
BOT_TOKEN = (da @BotFather)
CHANNEL_ID = (da @getidsbot)
ADMIN_IDS = (il tuo ID)
```

## ✅ Step 3: Verifica Deploy

```bash
# GitHub Actions parte automaticamente su push
# Vedi: GitHub > Actions > "Deploy to Render"

# Oppure manual deploy:
npm run deploy:render -- --token=YOUR_RENDER_KEY
```

## 📊 Dopo il Setup

### Auto-Deploy su Ogni Push
```bash
git add .
git commit -m "feat: miglioramento"
git push origin main
# ↓
# GitHub Actions automaticamente:
# - Test codice
# - Deploy a Render
# - Notifica su Telegram ✅
```

### Manual Deploy Render
```bash
npm run deploy:render:interactive
```

### Testa Bot Localmente
```bash
cd telegram-bot
npm start
# Invia /start a @gene1799_art_bot
```

## 🔐 Configura GitHub Secrets

Vai: `Settings > Secrets > Actions > New repository secret`

Aggiungi:
- `TELEGRAM_BOT_TOKEN` = (dari @BotFather)
- `TELEGRAM_CHANNEL_ID` = (dari @getidsbot)
- `TELEGRAM_ADMIN_ID` = (il tuo ID)
- `RENDER_API_KEY` = (da Render dashboard)

## 📖 Documentazione Completa

- **AUTOMATION_GUIDE.md** - Guida dettagliata (tutti i dettagli)
- **SETUP_GUIDE.md** - Setup manuale + PostgreSQL/WordPress
- **DEPLOYMENT_CHECKLIST.txt** - Checklist go-live

## 💡 Comandi Utili

```bash
# Setup moduli
npm run install-all

# Deploy everything
npm run deploy:all

# Solo backend dev
npm run dev:backend

# Solo frontend dev
npm run dev:frontend

# Build + Deploy
npm run build:all && npm run deploy:render
```

## 🆘 Problemi?

**Bot non parte:**
```bash
# Verifica token
grep BOT_TOKEN telegram-bot/.env

# Testa syntax
node -c telegram-bot/bot.js

# Verifica Render secrets
# Dashboard > Environment > BOT_TOKEN
```

**GitHub Actions fails:**
```bash
# 1. Verifica secrets sono configurati
# 2. Verifica branch protection OFF durante test
# 3. Vedi logs: GitHub > Actions > Latest run
```

**Rendernon deploya:**
```bash
# 1. Verifica token è valido
# 2. Verifica rootDir = "telegram-bot"
# 3. Vedi logs Render Dashboard
```

## 📞 Help

- Email: gene1799artcorporatione@gmail.com
- Telegram: @gene1799_art_bot
- GitHub Issues: github.com/gene7919/Gene1799ArtCorporatione/issues

---

**Quick Links:**
- 🌐 Website: gene1799artcorporatione.mom
- 🎨 Zora: zora.co/@gene1799
- 🤖 Bot: @gene1799_art_bot
- 📊 Render: dashboard.render.com

**Versione:** 1.0.0 | **Data:** Feb 2026
