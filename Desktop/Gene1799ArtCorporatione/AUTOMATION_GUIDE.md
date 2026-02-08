# 🚀 GENE1799 Automation Guide

Automatizza completamente il deploy di GENE1799 ART CORPORATIONE.

## 📋 Contenuto

- `setup-automation.ps1` - PowerShell script per setup completo
- `setup.bat` - Windows launcher (per setup.ps1)
- `deploy-render.js` - Node.js script per deploy Render via API
- `.github/workflows/deploy.yml` - GitHub Actions CI/CD

## 🎯 Quick Start

### Windows (Setup Completo)

```bash
# Doppio click su:
setup.bat

# O esegui direttamente:
powershell -ExecutionPolicy Bypass -File setup-automation.ps1 -InteractiveMode $true
```

### macOS / Linux

```bash
# Rendi eseguibile
chmod +x setup-automation.ps1

# Esegui
./setup-automation.ps1
```

## 🤖 Automation Features

### 1. PowerShell Setup Script (`setup-automation.ps1`)

Automatizza:
- ✓ Setup Telegram Bot
- ✓ Configurazione .env
- ✓ Install dependencies npm
- ✓ Push su GitHub
- ✓ Deploy instruction per Render
- ✓ WordPress security setup
- ✓ Monitoring configuration

**Modalità:**

```powershell
# Automatico (no interazioni)
./setup-automation.ps1 -InteractiveMode $false -BotToken "xxx" -ChannelId "-100xxx" -AdminIds "123"

# Interattivo (chiede conferme)
./setup-automation.ps1 -InteractiveMode $true

# Skip Render (solo GitHub)
./setup-automation.ps1 -SkipRender
```

### 2. Render Deployment Script (`deploy-render.js`)

Automatizza deploy a Render via API:

```bash
# Con token
node deploy-render.js --token YOUR_RENDER_API_KEY

# Interattivo (chiede token)
node deploy-render.js --interactive

# In package.json
npm run deploy:render -- --token=YOUR_KEY
```

Features:
- ✓ Autentica con Render API
- ✓ Trova il servizio telegram-bot
- ✓ Triggera il deploy
- ✓ Setta environment variables
- ✓ Monitora lo status

### 3. GitHub Actions CI/CD (`.github/workflows/deploy.yml`)

Attivarsi automaticamente su:
```yaml
- Push su main
- Modifiche in: telegram-bot/, .render.yaml
```

Cosa fa:
- ✓ Test su Node 18.x e 20.x
- ✓ Security audit
- ✓ Build frontend + backend
- ✓ Trigger Render deployment
- ✓ Notifiche Telegram su success/failure

**Configurazione Secrets GitHub:**

Vai a: `Settings > Secrets > Actions`

Aggiungi:
```
TELEGRAM_BOT_TOKEN = (da @BotFather)
TELEGRAM_CHANNEL_ID = (da @getidsbot)
TELEGRAM_ADMIN_ID = (il tuo ID)
RENDER_API_KEY = (da Render dashboard)
```

## 🔄 Workflow Completo

### Scenario 1: Setup da Zero

```bash
# 1. Esegui setup.bat (Windows)
setup.bat
# → Scelta: 2 (Setup Interattivo)

# 2. Rispondi alle domande:
# - BOT_TOKEN da @BotFather
# - CHANNEL_ID da @getidsbot
# - ADMIN_ID il tuo ID

# 3. Script fa automaticamente:
# - Crea .env
# - npm install
# - git add & commit
# - git push su GitHub

# 4. GitHub Actions si attiva:
# - Test su Node versions
# - Trigger Render deploy
# - Notifiche Telegram
```

### Scenario 2: Deploy dopo modifche

```bash
# 1. Modifica telegram-bot/bot.js

# 2. Push su GitHub
git add telegram-bot/bot.js
git commit -m "fix: miglioramento bot"
git push origin main

# 3. GitHub Actions automaticamente:
# - Testa il codice
# - Deploy su Render
# - Notifica su Telegram "✅ Deployment SUCCESS"
```

### Scenario 3: Deploy Manuale da Render API

```bash
# 1. Ottieni API key da: https://dashboard.render.com/account/api-tokens

# 2. Esegui deploy script
node deploy-render.js --token YOUR_API_KEY

# 3. Script automaticamente:
# - Connette a Render API
# - Trova il servizio telegram-bot
# - Triggera deploy
# - Mostra status
```

## 📊 Monitoring Automatico

Ogni deployment automatico:

1. **GitHub Actions Log**
   - Vedi real-time: `Actions > Deploy workflow`

2. **Telegram Notifications**
   - Success: Message nel TELEGRAM_CHANNEL_ID
   - Failure: Alert all'ADMIN_ID
   - Include: commit, branch, link dashboard

3. **Render Dashboard**
   - https://dashboard.render.com
   - Vedi status deploy
   - Monitora logs

## 🔐 Security

**Secrets Management:**
```yaml
# GitHub Secrets (encrypted)
BOT_TOKEN        # Never in code, sempre in Secrets
CHANNEL_ID       # Private IDs
ADMIN_IDS        # Private IDs
RENDER_API_KEY   # API authentication
```

**.gitignore (protegge secrets)**
```
.env
.env.local
.env.*.local
node_modules/
```

**Deploy Verification:**
```bash
# Setup script verifica:
- ✓ File .env creato
- ✓ npm dependencies OK
- ✓ bot.js syntax valid
- ✓ package.json exists
```

## 🆘 Troubleshooting

### GitHub Actions fails

**Checklist:**
```bash
# 1. Verifica Secrets:
# Settings > Secrets > Verifica BOT_TOKEN e CHANNEL_ID

# 2. Verifica node_modules:
npm ci  # Clean install

# 3. Verifica syntax:
node -c telegram-bot/bot.js

# 4. Vedi logs:
# GitHub > Actions > Latest run > Logs
```

### Render deployment fails

```bash
# 1. Verifica root directory
# In .render.yaml: rootDir: telegram-bot

# 2. Verifica build command
# npm install deve essere sufficiente

# 3. Verifica start command
# npm start deve lanciare bot.js

# 4. Verifica env vars su Render dashboard
# Tutti i BOT_TOKEN, CHANNEL_ID, etc.
```

### Bot non risponde dopo deploy

```bash
# 1. Verifica token su Render
# Dashboard > Environment > BOT_TOKEN

# 2. Verifica channel ID
# Usa @getidsbot per ri-verificare

# 3. Vedi logs Render
# Dashboard > Logs tab

# 4. Restart manuale
# Dashboard > Settings > Restart
```

## 📈 Advanced: Custom Workflows

### Auto-backup database

Aggiungi a `.github/workflows/deploy.yml`:

```yaml
- name: Backup database
  run: |
    npm run backup  # Se implementato
  env:
    BACKUP_URL: ${{ secrets.BACKUP_URL }}
```

### Auto-update dependencies

```yaml
- name: Update dependencies
  run: npm audit fix --force
```

### Auto-notify Discord

Aggiungi step:

```yaml
- name: Discord notification
  uses: sarisia/actions-status-discord@v1
  with:
    webhook_url: ${{ secrets.DISCORD_WEBHOOK }}
    status: ${{ job.status }}
```

## 🔗 Links

- **GitHub**: https://github.com/gene7919/Gene1799ArtCorporatione
- **Render**: https://dashboard.render.com
- **Telegram Bot**: @gene1799_art_bot
- **Email**: gene1799artcorporatione@gmail.com
- **Setup Guide**: SETUP_GUIDE.md
- **Deployment Checklist**: DEPLOYMENT_CHECKLIST.txt

## 📝 Versioning

```
v1.0.0 - Initial automation setup
├─ PowerShell setup script
├─ Windows batch launcher
├─ Render deployment script
└─ GitHub Actions CI/CD
```

---

**Autori:**
- Marco Antonio Saverio Mazzitelli
- Fabio Amedeo Lo Presti

**Data:** Febbraio 2026
**Licenza:** MIT
