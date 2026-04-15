# =========================
# GENE1799 AGENT INSTALLER
# =========================

Write-Host "🚀 Setup GENE1799 Agent V2..." -ForegroundColor Cyan

# 1. CREA CARTELLA PROGETTO
$projectPath = "$HOME\gene1799_agent"

if (!(Test-Path $projectPath)) {
    New-Item -ItemType Directory -Path $projectPath
    Write-Host "📁 Cartella creata: $projectPath"
}

Set-Location $projectPath

# 2. CREA VIRTUAL ENV
Write-Host "🐍 Creazione virtual environment..."
python -m venv venv

# ATTIVA VENV
Write-Host "⚡ Attivazione ambiente..."
.\venv\Scripts\Activate.ps1

# 3. CREA requirements.txt
@"
requests
python-dotenv
web3
"@ | Out-File -Encoding UTF8 requirements.txt

# 4. INSTALLA DIPENDENZE
Write-Host "📦 Installazione dipendenze..."
pip install --upgrade pip
pip install -r requirements.txt

# 5. CREA FILE .env
@"
TELEGRAM_TOKEN=
CHAT_ID=
BASE_POOL=
GENE1799_CONTRACT=
"@ | Out-File -Encoding UTF8 .env

Write-Host "⚠️ Inserisci i dati nel file .env prima di avviare"

# 6. CREA FILE PYTHON

# config.py
@"
import os
from dotenv import load_dotenv

load_dotenv()

BASE_RPC = "https://mainnet.base.org"

GENE1799_CONTRACT = os.getenv("GENE1799_CONTRACT")
POOL_ADDR = os.getenv("BASE_POOL")

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = os.getenv("CHAT_ID")

ZORA_GRAPHQL = "https://api.zora.co/graphql"
GECKO_API = "https://api.geckoterminal.com/api/v2"
"@ | Out-File -Encoding UTF8 config.py

# zora_module.py
@"
import requests
from config import ZORA_GRAPHQL, GENE1799_CONTRACT

def fetch_nfts():
    query = f'''
    {{
      tokens(
        collectionAddresses: ["{GENE1799_CONTRACT}"],
        first: 20,
        networks: [BASE]
      ) {{
        nodes {{
          tokenId
          name
          owner
        }}
      }}
    }}
    '''

    try:
        r = requests.post(ZORA_GRAPHQL, json={'query': query}, timeout=10)
        data = r.json()
        return data.get('data', {}).get('tokens', {}).get('nodes', [])
    except:
        return []
"@ | Out-File -Encoding UTF8 zora_module.py

# gecko_module.py
@"
import requests
from config import POOL_ADDR, GECKO_API

def fetch_pool():
    url = f"{GECKO_API}/networks/base/pools/{POOL_ADDR}"

    try:
        r = requests.get(url, timeout=10)
        if r.status_code != 200:
            return None

        attr = r.json()['data']['attributes']

        return {
            "price": float(attr.get("base_token_price_usd", 0)),
            "liquidity": float(attr.get("reserve_in_usd", 0)),
            "volume": float(attr.get("volume_usd", {}).get("h24", 0)),
            "tx": attr.get("txns", {}).get("h24", 0)
        }
    except:
        return None
"@ | Out-File -Encoding UTF8 gecko_module.py

# alert_module.py
@"
import requests
from config import TELEGRAM_TOKEN, CHAT_ID

def send_alert(msg):
    if not TELEGRAM_TOKEN or not CHAT_ID:
        return

    try:
        url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
        requests.post(url, data={"chat_id": CHAT_ID, "text": msg})
    except:
        pass
"@ | Out-File -Encoding UTF8 alert_module.py

# ai_module.py
@"
def analyze_market(data):
    if not data:
        return "NO_DATA"

    volume = data["volume"]
    liquidity = data["liquidity"]

    if volume > 5000 and liquidity > 10000:
        return "STRONG_BULL"

    if volume > 1000:
        return "BULL"

    if volume < 200:
        return "DEAD"

    return "NEUTRAL"
"@ | Out-File -Encoding UTF8 ai_module.py

# logger.py
@"
from datetime import datetime

def log(msg):
    print(f"[{datetime.now()}] {msg}")
"@ | Out-File -Encoding UTF8 logger.py

# main.py
@"
import asyncio
from zora_module import fetch_nfts
from gecko_module import fetch_pool
from alert_module import send_alert
from ai_module import analyze_market
from logger import log

async def run_cycle():
    log("🔄 Scan avviato")

    nfts = fetch_nfts()
    market = fetch_pool()

    log(f"NFT trovati: {len(nfts)}")

    if market:
        log(f"Prezzo: {market['price']} | Vol: {market['volume']}")

        signal = analyze_market(market)
        log(f"Segnale AI: {signal}")

        if signal == "STRONG_BULL":
            send_alert(f"🚀 STRONG BULL su GENE1799\nVol: {market['volume']}")

        elif signal == "DEAD":
            send_alert("⚠️ Mercato fermo")

    else:
        log("❌ Market data non disponibile")

async def main():
    while True:
        await run_cycle()
        await asyncio.sleep(300)

if __name__ == "__main__":
    asyncio.run(main())
"@ | Out-File -Encoding UTF8 main.py

# 7. AVVIO
Write-Host ""
Write-Host "✅ INSTALLAZIONE COMPLETA" -ForegroundColor Green
Write-Host "👉 Modifica il file .env e poi avvia con:"
Write-Host "python main.py"