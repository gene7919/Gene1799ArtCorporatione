# 🤖 GENE1799 PRO AI - Complete Guide

## ✨ Welcome to Your Advanced AI Platform

**Gene1799 PRO AI** è il tuo sistema completo di intelligenza artificiale con:
- ✅ Interfaccia verde neon professionale
- ✅ Password di accesso sicuro
- ✅ Integrazione AI completa (OpenAI, DALL-E, Runway, ecc.)
- ✅ Gestione agenti specializzati
- ✅ Creazione contenuti (testi, immagini, musica, video)
- ✅ Automazione social media (Twitter, LinkedIn, Instagram, TikTok)
- ✅ Bot Telegram integrato
- ✅ Render.com API integration

---

## 🚀 Quick Start (30 secondi)

```powershell
cd c:\Users\gene1\Desktop\gene1799artcorporatione
python gene1799_pro_ai.py
```

### Login
- **Username**: Qualsiasi nome
- **Password**: Qualsiasi parola (minimo 6 caratteri)

---

## 📊 Sezioni Principali

### 1. 💬 **Chat with AI**
Parla direttamente con l'AI usando diversi modelli:
- **GPT-4** - Model più avanzato per analisi complesse
- **GPT-3.5-Turbo** - Model veloce ed efficiente

**Come usare:**
1. Scrivi la tua domanda
2. Seleziona il modello AI
3. Clicca **SEND**
4. Ricevi la risposta in tempo reale

**Esempi di domande:**
```
- Come creare contenuto virale su TikTok?
- Analizza questa strategia di marketing
- Dammi idee creative per un post Instagram
- Come ottimizzare le campagne pubblicitarie?
```

### 2. 🤖 **Agents** (Agenti Specializzati)
Aggiungi e configura agenti per compiti specifici:

**Tipo di agenti:**
- **Text** - Generazione testi, articoli, copy
- **Image** - Creazione immagini con DALL-E
- **Music** - Composizione musicale automatica
- **Video** - Generazione e editing video
- **Hybrid** - Combina più modalità

**Come aggiungere un agente:**
1. Nome: Dai un nome (es. "Video Creator Pro")
2. Type: Scegli il tipo
3. Model: Seleziona il modello AI
4. Clicca **+ ADD AGENT**

**Agenti di Default:**
- ✓ Anti-Cancer AI [Medical]
- ✓ Drug Discovery [Pharma]
- ✓ ML Orchestrator [DataScience]

### 3. 🔑 **API Keys**
Integra servizi esterni aggiungendo API keys:

**Servizi disponibili:**
- **OpenAI API** - Chat, testi, análisis
- **DALL-E** - Generazione immagini professionali
- **Stability AI** - Generazione immagini HD
- **RunwayML** - Video generation e editing
- **Spotify Music** - Integrazione musica
- **Twitter API** - Automazione tweet
- **Render.com API** - Server integration

**Come aggiungere una API:**
1. Incolla la tua API key nel campo
2. Clicca ✓ per salvare
3. Usa immediatamente nella sezione appropriata

### 4. 📝 **Content Creation**
Crea automaticamente contenuti di qualità:

**Flusso:**
1. Scegli il **Type** (Text/Image/Music/Video)
2. Scrivi il **Prompt** dettagliato
3. Clicca **CREATE**
4. Il contenuto appare a destra
5. Copia o salva l'output

**Esempi di prompt:**

**Testi:**
```
Scrivi un articolo SEO su "AI nel marketing digitale" 
(1500 parole, ottimizzato per Google)
```

**Immagini:**
```
Crea un'immagine professionale di un robot futuristico
che lavora con ologrammi, stile cyberpunk, 4K
```

**Musica:**
```
Componi una traccia lo-fi/hip-hop rilassante
di 3 minuti con vibes estive
```

**Video:**
```
Crea uno short video di 15 secondi per TikTok
su tendenze AI, con effetti dinamici e testo
```

### 5. 📱 **Social Media**
Pubblica automaticamente su tutti i social:

**Piattaforme supportate:**
- **Twitter** - Tweet thread automatici
- **LinkedIn** - Post professionali B2B
- **Instagram** - Carousel e Reels
- **TikTok** - Short video verticale
- **Telegram** - Messaggi e notifiche

**Workflow:**
1. Crea il contenuto (sezione Content Creation)
2. Vai a Social Media
3. Scegli la piattaforma
4. Clicca **POST**
5. Personalizza se necessario
6. Pubblica!

**Smart Features:**
- ✅ Formattazione automatica per ogni piattaforma
- ✅ Hashtag ottimizzati
- ✅ Timing intelligente
- ✅ Scheduling
- ✅ Analytics integrati

### 6. 📲 **Telegram Bot**
Controlla il sistema da Telegram:

**Setup:**
1. Vai a Telegram (@BotFather)
2. Crea un nuovo bot
3. Copia il **Token**
4. Incolla il token nella sezione Telegram Bot
5. Aggiungi il bot al tuo gruppo
6. Clicca **SETUP BOT**

**Comandi disponibili:**

```
/start              - Inizializza il bot
/ask <domanda>      - Fai una domanda all'AI
/create <tipo>      - Crea contenuto
/post <platform>    - Pubblica su social
/agents             - Lista agenti attivi
/status             - Stato del sistema
/help               - Mostra tutti i comandi
```

**Esempi:**
```
/ask Come aumentare engagement su Instagram?
/create image Crea un'immagine di un sunset
/post twitter Pubblica il mio ultimo contenuto
/agents
```

---

## 🎨 Tema Verde Fluo

Colori del sistema:
- **Accent Verde**: `#00ff41` (Neon Green)
- **Accent Verde Light**: `#39ff14` (Light Green)
- **Cyan Secondario**: `#00ffff`
- **Dark Background**: `#0a0e27`
- **Panel Background**: `#050a1a`

### Customizzare i colori:
Nel file `gene1799_pro_ai.py`, linea 55:
```python
self.colors = {
    'accent': '#00ff41',        # Cambia il verde
    'secondary': '#00ffff',     # Cambia il cyan
    # ... altri colori
}
```

---

## 🔐 Sicurezza & Password

**Hash della password:**
- Minimo 6 caratteri
- Crittografia SHA256
- Nessuna password salvata in plain text
- Login richiesto al start

**Cambiar password:**
Vai a **Settings** e usa **LOGOUT**, poi fai **LOGIN** con una nuova password.

---

## ⚙️ Configurazione Sistema

### Requisiti:
- Python 3.9+
- Tkinter (incluso con Python)
- requests library
- Internet connection

### Installare dipendenze:
```powershell
pip install requests pillow openai -q
```

### File di configurazione:
Crea un file `config.json`:
```json
{
  "api_keys": {
    "openai": "sk-xxxxxxx",
    "dalle": "key-xxxxxxx",
    "render": "key-xxxxxxx"
  },
  "telegram": {
    "token": "xxxxxxx",
    "chat_id": "xxxxxxx"
  },
  "social_accounts": {
    "twitter": "token-xxxxxxx",
    "linkedin": "token-xxxxxxx"
  }
}
```

---

## 🔗 Integrazione Render.com

L'app è già integrata con il tuo server Render:
- **URL**: `https://gene1799-api.onrender.com`
- **Features**: Backup, sincronizzazione, API
- **Status**: Controllato automaticamente

Connessione automatica al server per:
- Cloud backup degli agenti
- Sincronizzazione dati
- API gateway
- Analytics

---

## 📊 Dashboard Statistiche

In **Settings** puoi vedere:
- Numero di agenti attivi
- Numero di contenuti creati
- Post pubblicati per piattaforma
- Query AI elaborate
- Spazio storage utilizzato

---

## 🛠️ Troubleshooting

**App non si avvia:**
```powershell
python -m pip install --upgrade pillow requests
python gene1799_pro_ai.py
```

**Password dimenticata:**
```powershell
# Semplicemente registrati di nuovo con una nuova password
```

**API key non funziona:**
1. Controlla il formato della key
2. Verifica che sia valida
3. Ricopia dalla dashboard del servizio
4. Salva di nuovo

**Telegram bot non risponde:**
1. Verifica il token (@BotFather)
2. Assicurati che il bot sia nel gruppo
3. Mantieni l'app aperta
4. Controlla i logs

---

## 📚 API Integration Details

### OpenAI Integration:
```python
# Automaticamente configurato dall'app
model = "gpt-4"
response = ai.chat.completions.create(...)
```

### Render API:
```python
# Sincronizzazione cloud
POST /api/sync
GET /api/agents
POST /api/publish
```

---

## 🎯 Prossimi Step

1. ✅ Aggiungi le tue API keys
2. ✅ Crea i tuoi agenti specializzati
3. ✅ Collega i tuoi account social
4. ✅ Setup Telegram bot
5. ✅ Inizia a creare contenuti!

---

## 📞 Support

**Problemi?**
- Controlla la sezione Troubleshooting
- Visualizza i logs dell'app
- Connettiti al server Render

---

**Buon lavoro con Gene1799 PRO AI! 🚀**

*Versione: 2.0 Pro | Data: 2026-02-08 | Status: Production Ready*
