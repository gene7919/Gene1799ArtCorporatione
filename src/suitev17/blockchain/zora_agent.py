#!/usr/bin/env python3
"""
Zora Agent v2.0 - Solana NFT & DeFi Operations
Integrazione dashboard-ready con endpoint API Flask
"""
import os
import sys
import json
import asyncio
import aiohttp
from datetime import datetime
from typing import Dict, Any, Optional, List
from dataclasses import dataclass, asdict
from flask import Flask, request, jsonify
from flask_cors import CORS

sys.path.insert(0, r'C:\SuiteV17')

@dataclass
class TransactionResult:
    success: bool
    signature: Optional[str] = None
    error: Optional[str] = None
    explorer_url: Optional[str] = None
    timestamp: str = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()

@dataclass
class WalletInfo:
    address: str
    balance_sol: float
    balance_usd: float
    nfts_count: int
    tokens: List[Dict]
    last_update: str

class ZoraAgent:
    """Agente per operazioni Solana con integrazione dashboard."""
    
    def __init__(self, wallet: str = None, rpc: str = None):
        self.wallet = wallet or os.getenv('SOL_WALLET', '')
        self.rpc = rpc or os.getenv('SOLANA_RPC', 'https://api.mainnet-beta.solana.com')
        self.helius_key = os.getenv('HELIUS_API_KEY', '')
        self.jupiter_url = 'https://quote-api.jup.ag/v6'
        self.session = None
        self._balance = 0.0
        self._nfts = []
        self._is_connected = False
        
    async def _init_session(self):
        if self.session is None:
            self.session = aiohttp.ClientSession()
            
    async def get_balance(self) -> Dict:
        """Recupera balance SOL con cache."""
        await self._init_session()
        if not self.wallet:
            return {'error': 'Wallet non configurato', 'balance': 0}
            
        try:
            # Usa Helius API se disponibile
            if self.helius_key:
                url = f'https://mainnet.helius-rpc.com/?api-key={self.helius_key}'
                payload = {
                    'jsonrpc': '2.0',
                    'id': 1,
                    'method': 'getBalance',
                    'params': [self.wallet]
                }
                async with self.session.post(url, json=payload) as resp:
                    data = await resp.json()
                    if 'result' in data:
                        lamports = data['result']['value']
                        self._balance = lamports / 1e9
                        return {
                            'success': True,
                            'balance_sol': self._balance,
                            'balance_lamports': lamports,
                            'wallet': self._wallet_short()
                        }
            return {'error': 'RPC call failed', 'balance': self._balance}
        except Exception as e:
            return {'error': str(e), 'balance': self._balance}
            
    async def get_nfts(self) -> List[Dict]:
        """Recupera NFT del wallet."""
        await self._init_session()
        if not self.wallet or not self.helius_key:
            return []
            
        try:
            url = f'https://mainnet.helius-rpc.com/?api-key={self.helius_key}'
            payload = {
                'jsonrpc': '2.0',
                'id': 1,
                'method': 'getAssetsByOwner',
                'params': {
                    'ownerAddress': self.wallet,
                    'page': 1,
                    'limit': 100
                }
            }
            async with self.session.post(url, json=payload) as resp:
                data = await resp.json()
                if 'result' in data and 'items' in data['result']:
                    self._nfts = [
                        {
                            'name': item.get('content', {}).get('metadata', {}).get('name', 'Unknown'),
                            'image': item.get('content', {}).get('links', {}).get('image', ''),
                            'mint': item.get('id', '')
                        }
                        for item in data['result']['items']
                    ]
                    return self._nfts
                return []
        except Exception as e:
            return [{'error': str(e)}]
            
    async def get_token_price(self, token_mint: str) -> Dict:
        """Recupera prezzo token da Jupiter."""
        await self._init_session()
        try:
            url = f'{self.jupiter_url}/price?ids={token_mint}'
            async with self.session.get(url) as resp:
                data = await resp.json()
                return data.get('data', {}).get(token_mint, {})
        except Exception as e:
            return {'error': str(e)}
            
    def _wallet_short(self) -> str:
        """Restituisce wallet abbreviato."""
        if len(self.wallet) > 12:
            return f'{self.wallet[:6]}...{self.wallet[-4:]}'
        return self.wallet or 'Not set'
        
    def get_wallet_info(self) -> Dict:
        """Restituisce info wallet complete."""
        return {
            'wallet': self._wallet_short(),
            'address_full': self.wallet,
            'balance_sol': self._balance,
            'rpc': self.rpc,
            'helius_connected': bool(self.helius_key),
            'nfts_count': len(self._nfts),
            'is_configured': bool(self.wallet)
        }
        
    async def close(self):
        if self.session:
            await self.session.close()
            self.session = None

# Flask API per dashboard
app = Flask(__name__)
CORS(app)

zora_agent = ZoraAgent()

@app.route('/api/zora/status')
def zora_status():
    return jsonify(zora_agent.get_wallet_info())
    
@app.route('/api/zora/balance')
def zora_balance():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    result = loop.run_until_complete(zora_agent.get_balance())
    loop.close()
    return jsonify(result)
    
@app.route('/api/zora/nfts')
def zora_nfts():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    result = loop.run_until_complete(zora_agent.get_nfts())
    loop.close()
    return jsonify({'nfts': result, 'count': len(result)})
    
@app.route('/api/zora/configure', methods=['POST'])
def zora_configure():
    data = request.json or {}
    global zora_agent
    zora_agent = ZoraAgent(
        wallet=data.get('wallet'),
        rpc=data.get('rpc')
    )
    return jsonify({'success': True, 'message': 'Wallet configurato'})

def get_agent():
    return zora_agent
    
if __name__ == '__main__':
    print('Zora Agent v2.0 - Solana Operations')
    print(json.dumps(zora_agent.get_wallet_info(), indent=2))
    
    # Test mode
    if len(sys.argv) > 1 and sys.argv[1] == 'api':
        print('Starting API server on port 3010...')
        app.run(host='0.0.0.0', port=3010, debug=False)
