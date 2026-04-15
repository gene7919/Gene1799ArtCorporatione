#!/usr/bin/env python3
"""
Sell Engine - Trading Engine per DEX su Solana
Integrazione con DexScreener, Jupiter, e analisi on-chain
"""
import os
import sys
import json
import time
import asyncio
import aiohttp
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from enum import Enum

class TradeAction(Enum):
    HOLD = 'hold'
    SELL = 'sell'
    BUY = 'buy'
    MONITOR = 'monitor'

@dataclass
class PoolData:
    address: str
    token_symbol: str
    token_name: str
    price_usd: float
    volume_24h: float
    liquidity_usd: float
    tx_count_24h: int
    price_change_1h: float
    price_change_24h: float
    market_cap: Optional[float] = None
    holders: Optional[int] = None
    last_updated: str = ''
    
@dataclass
class TradeSignal:
    action: str
    confidence: float  # 0.0 - 1.0
    pool: str
    timestamp: str
    reasons: List[str]
    risk_score: int  # 1-10, 10 = più rischioso
    suggested_slippage: float
    
@dataclass
class TradeExecution:
    signal: TradeSignal
    executed: bool
    tx_hash: Optional[str]
    error: Optional[str]
    execution_time_ms: int

class DexScreenerAPI:
    """Client per DexScreener API."""
    
    BASE_URL = 'https://api.dexscreener.com/latest'
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30))
        return self
        
    async def __aexit__(self, *args):
        if self.session:
            await self.session.close()
            
    async def get_token_pairs(self, token_address: str) -> List[Dict]:
        """Recupera pair per un token specifico."""
        if not self.session:
            raise RuntimeError('Sessione non inizializzata')
            
        url = f'{self.BASE_URL}/dex/tokens/{token_address}'
        
        try:
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('pairs', [])[:10]  # Top 10 pairs
                else:
                    return []
        except Exception as e:
            print(f'Errore DexScreener: {e}')
            return []
            
    async def search_pairs(self, query: str) -> List[Dict]:
        """Cerca pair per simbolo o nome."""
        if not self.session:
            raise RuntimeError('Sessione non inizializzata')
            
        url = f'{self.BASE_URL}/dex/search?q={query}'
        
        try:
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('pairs', [])[:5]
                return []
        except Exception as e:
            print(f'Errore ricerca: {e}')
            return []
            
    def parse_pair_data(self, pair: Dict) -> Optional[PoolData]:
        """Converte dati pair in PoolData."""
        try:
            return PoolData(
                address=pair.get('pairAddress', ''),
                token_symbol=pair.get('baseToken', {}).get('symbol', 'UNKNOWN'),
                token_name=pair.get('baseToken', {}).get('name', 'Unknown Token'),
                price_usd=float(pair.get('priceUsd', 0)),
                volume_24h=float(pair.get('volume', {}).get('h24', 0)),
                liquidity_usd=float(pair.get('liquidity', {}).get('usd', 0)),
                tx_count_24h=int(pair.get('txns', {}).get('h24', {}).get('buys', 0)) + 
                              int(pair.get('txns', {}).get('h24', {}).get('sells', 0)),
                price_change_1h=float(pair.get('priceChange', {}).get('h1', 0)),
                price_change_24h=float(pair.get('priceChange', {}).get('h24', 0)),
                market_cap=float(pair.get('marketCap', 0)) if pair.get('marketCap') else None,
                last_updated=datetime.now().isoformat()
            )
        except (KeyError, ValueError, TypeError) as e:
            print(f'Errore parsing pair: {e}')
            return None

class JupiterAPI:
    """Client per Jupiter Aggregator (swap routing)."""
    
    BASE_URL = 'https://quote-api.jup.ag/v6'
    
    def __init__(self):
        self.session: Optional[aiohttp.ClientSession] = None
        
    async def __aenter__(self):
        self.session = aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30))
        return self
        
    async def __aexit__(self, *args):
        if self.session:
            await self.session.close()
            
    async def get_quote(self, input_mint: str, output_mint: str, amount: int) -> Optional[Dict]:
        """Ottiene quote per swap."""
        if not self.session:
            raise RuntimeError('Sessione non inizializzata')
            
        params = {
            'inputMint': input_mint,
            'outputMint': output_mint,
            'amount': str(amount),
            'slippageBps': 50  # 0.5%
        }
        
        try:
            async with self.session.get(f'{self.BASE_URL}/quote', params=params) as response:
                if response.status == 200:
                    return await response.json()
                return None
        except Exception as e:
            print(f'Errore Jupiter quote: {e}')
            return None

class RiskAnalyzer:
    """Analisi rischio per token/pool."""
    
    def __init__(self):
        self.risk_factors: Dict[str, Any] = {}
        
    def analyze_pool(self, pool: PoolData) -> Tuple[int, List[str]]:
        """
        Calcola risk score (1-10, 10 = più rischioso).
        Ritorna score e lista di fattori di rischio.
        """
        risk_score = 0
        risk_factors = []
        
        # 1. Liquidità bassa
        if pool.liquidity_usd < 50000:
            risk_score += 3
            risk_factors.append(f'Liquidity troppo bassa: ${pool.liquidity_usd:,.0f}')
        elif pool.liquidity_usd < 100000:
            risk_score += 2
            risk_factors.append(f'Liquidity bassa: ${pool.liquidity_usd:,.0f}')
        elif pool.liquidity_usd < 500000:
            risk_score += 1
            risk_factors.append(f'Liquidity moderata: ${pool.liquidity_usd:,.0f}')
            
        # 2. Volume basso
        if pool.volume_24h < 1000:
            risk_score += 2
            risk_factors.append(f'Volume 24h molto basso: ${pool.volume_24h:,.0f}')
        elif pool.volume_24h < 10000:
            risk_score += 1
            risk_factors.append(f'Volume 24h basso: ${pool.volume_24h:,.0f}')
            
        # 3. Transazioni basse
        if pool.tx_count_24h < 20:
            risk_score += 2
            risk_factors.append(f'Attività scarsa: {pool.tx_count_24h} tx/24h')
        elif pool.tx_count_24h < 100:
            risk_score += 1
            risk_factors.append(f'Attività bassa: {pool.tx_count_24h} tx/24h')
            
        # 4. Price dump
        if pool.price_change_24h < -50:
            risk_score += 3
            risk_factors.append(f'CRASH 24h: {pool.price_change_24h:.1f}%')
        elif pool.price_change_24h < -20:
            risk_score += 2
            risk_factors.append(f'Dump 24h: {pool.price_change_24h:.1f}%')
        elif pool.price_change_1h < -10:
            risk_score += 1
            risk_factors.append(f'Dump 1h: {pool.price_change_1h:.1f}%')
            
        # 5. Pump sospetto
        if pool.price_change_24h > 200:
            risk_score += 2
            risk_factors.append(f'Pump sospetto 24h: +{pool.price_change_24h:.1f}%')
            
        # 6. Market cap basso
        if pool.market_cap and pool.market_cap < 100000:
            risk_score += 2
            risk_factors.append(f'Market cap micro: ${pool.market_cap:,.0f}')
            
        # Cap a 10
        risk_score = min(risk_score, 10)
        
        return risk_score, risk_factors
        
    def get_risk_level(self, score: int) -> str:
        """Restituisce label livello rischio."""
        if score >= 8:
            return 'ESTREMO'
        elif score >= 6:
            return 'ALTO'
        elif score >= 4:
            return 'MEDIO'
        elif score >= 2:
            return 'BASSO'
        return 'MINIMO'

class SellEngine:
    """
    Engine principale per decisioni di trading.
    Combina analisi multi-fattore per generare segnali.
    """
    
    # Threshold configurabili
    SELL_VOLUME_THRESHOLD = 1000      # Volume sotto cui vendere
    SELL_LIQUIDITY_THRESHOLD = 50000  # Liquidità sotto cui vendere
    SELL_TRANSACTIONS_THRESHOLD = 20  # Tx sotto cui vendere
    SELL_PRICE_DROP_THRESHOLD = -30   # Drop % sotto cui vendere
    
    # Pesi per scoring
    WEIGHTS = {
        'volume': 2,
        'liquidity': 2,
        'transactions': 1,
        'price_change': 3,
        'risk': 2
    }
    
    def __init__(self, config: Dict = None):
        self.config = config or {}
        self.risk_analyzer = RiskAnalyzer()
        self.decision_history: List[TradeSignal] = []
        self.log_entries: List[str] = []
        
    def log(self, message: str):
        """Log con timestamp."""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        entry = f'[{timestamp}] SELL_ENGINE: {message}'
        self.log_entries.append(entry)
        print(entry)
        
    def should_sell(self, pool_data: Dict) -> bool:
        """
        DEPRECATED: Usare analyze_pool per decisioni complete.
        Mantiene compatibilità con codice esistente.
        """
        signal = self.analyze_pool(pool_data)
        return signal.action == TradeAction.SELL.value
        
    def analyze_pool(self, pool_data: Dict) -> TradeSignal:
        """
        Analisi completa di un pool e generazione segnale trading.
        """
        # Converti in PoolData se necessario
        if isinstance(pool_data, dict):
            pool = PoolData(
                address=pool_data.get('address', ''),
                token_symbol=pool_data.get('token_symbol', pool_data.get('baseToken', {}).get('symbol', 'UNKNOWN')),
                token_name=pool_data.get('token_name', 'Unknown'),
                price_usd=float(pool_data.get('price_usd', pool_data.get('priceUsd', 0))),
                volume_24h=float(pool_data.get('volume_usd', pool_data.get('volume', {}).get('h24', 0))),
                liquidity_usd=float(pool_data.get('reserve_in_usd', pool_data.get('liquidity', {}).get('usd', 0))),
                tx_count_24h=int(pool_data.get('tx_count', pool_data.get('txns', {}).get('h24', {}).get('buys', 0) + pool_data.get('txns', {}).get('h24', {}).get('sells', 0))),
                price_change_1h=float(pool_data.get('priceChange', {}).get('h1', 0)),
                price_change_24h=float(pool_data.get('priceChange', {}).get('h24', 0)),
                last_updated=datetime.now().isoformat()
            )
        else:
            pool = pool_data
            
        self.log(f'Analisi {pool.token_symbol} @ {pool.address[:8]}...')
        
        # Calcola risk score
        risk_score, risk_factors = self.risk_analyzer.analyze_pool(pool)
        
        # Calcola punteggio vendita (0-10)
        sell_score = 0
        reasons = []
        
        # 1. Volume check
        if pool.volume_24h < self.SELL_VOLUME_THRESHOLD:
            sell_score += self.WEIGHTS['volume']
            reasons.append(f'Volume critico: ${pool.volume_24h:,.0f} < ${self.SELL_VOLUME_THRESHOLD:,.0f}')
            
        # 2. Liquidità check
        if pool.liquidity_usd < self.SELL_LIQUIDITY_THRESHOLD:
            sell_score += self.WEIGHTS['liquidity']
            reasons.append(f'Liquidity critica: ${pool.liquidity_usd:,.0f} < ${self.SELL_LIQUIDITY_THRESHOLD:,.0f}')
            
        # 3. Transazioni check
        if pool.tx_count_24h < self.SELL_TRANSACTIONS_THRESHOLD:
            sell_score += self.WEIGHTS['transactions']
            reasons.append(f'Attività critica: {pool.tx_count_24h} tx < {self.SELL_TRANSACTIONS_THRESHOLD}')
            
        # 4. Price dump
        if pool.price_change_24h < self.SELL_PRICE_DROP_THRESHOLD:
            sell_score += self.WEIGHTS['price_change']
            reasons.append(f'Price dump: {pool.price_change_24h:.1f}% < {self.SELL_PRICE_DROP_THRESHOLD}%')
            
        # 5. Risk alto
        if risk_score >= 6:
            sell_score += self.WEIGHTS['risk']
            reasons.append(f'Risk score alto: {risk_score}/10')
            reasons.extend(risk_factors)
            
        # Determina azione
        if sell_score >= 5:
            action = TradeAction.SELL
            confidence = min(sell_score / 8, 1.0)
        elif sell_score >= 3:
            action = TradeAction.MONITOR
            confidence = sell_score / 5
        else:
            action = TradeAction.HOLD
            confidence = 1 - (sell_score / 10)
            reasons.append('Condizioni stabili')
            
        # Calcola slippage suggerito basato su liquidità
        if pool.liquidity_usd < 10000:
            slippage = 5.0
        elif pool.liquidity_usd < 50000:
            slippage = 2.0
        elif pool.liquidity_usd < 100000:
            slippage = 1.0
        else:
            slippage = 0.5
            
        signal = TradeSignal(
            action=action.value,
            confidence=round(confidence, 2),
            pool=pool.address,
            timestamp=datetime.now().isoformat(),
            reasons=reasons,
            risk_score=risk_score,
            suggested_slippage=slippage
        )
        
        self.decision_history.append(signal)
        self.log(f'Segnale: {action.value.upper()} (conf: {confidence:.0%}, risk: {risk_score}/10)')
        
        return signal
        
    async def scan_token(self, token_address: str) -> List[TradeSignal]:
        """Scansiona tutti i pair di un token."""
        self.log(f'Scanning token {token_address[:10]}...')
        signals = []
        
        async with DexScreenerAPI() as dex:
            pairs = await dex.get_token_pairs(token_address)
            self.log(f'Trovati {len(pairs)} pairs')
            
            for pair in pairs:
                pool_data = dex.parse_pair_data(pair)
                if pool_data:
                    signal = self.analyze_pool(pool_data)
                    signals.append(signal)
                    
        return signals
        
    def get_decision_summary(self) -> Dict:
        """Restituisce riepilogo decisioni."""
        if not self.decision_history:
            return {'message': 'Nessuna decisione registrata'}
            
        actions = {}
        for signal in self.decision_history:
            actions[signal.action] = actions.get(signal.action, 0) + 1
            
        return {
            'total_decisions': len(self.decision_history),
            'actions_distribution': actions,
            'high_risk_detected': sum(1 for s in self.decision_history if s.risk_score >= 7),
            'avg_confidence': sum(s.confidence for s in self.decision_history) / len(self.decision_history),
            'last_decision': asdict(self.decision_history[-1]) if self.decision_history else None
        }
        
    def export_report(self, filename: str = None) -> str:
        """Esporta report in JSON."""
        if filename is None:
            filename = f'sell_engine_report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
            
        report = {
            'generated_at': datetime.now().isoformat(),
            'summary': self.get_decision_summary(),
            'decisions': [asdict(s) for s in self.decision_history],
            'config': self.config,
            'logs': self.log_entries[-100:]  # Ultime 100 righe
        }
        
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2, default=str)
            
        return filename

def main():
    """Entry point per testing."""
    print('=' * 60)
    print('SELL ENGINE - SuiteV17 Trading Module')
    print('=' * 60)
    
    # Test con dati simulati
    test_pool = {
        'address': 'test_pool_123',
        'token_symbol': 'TEST',
        'token_name': 'Test Token',
        'price_usd': 0.001,
        'volume_usd': 500,      # Basso
        'reserve_in_usd': 30000,  # Basso
        'tx_count': 15,         # Basso
        'priceChange': {'h24': -45, 'h1': -5}
    }
    
    engine = SellEngine()
    signal = engine.analyze_pool(test_pool)
    
    print(f'\nSegnale generato:')
    print(f'  Azione: {signal.action.upper()}')
    print(f'  Confidenza: {signal.confidence:.0%}')
    print(f'  Risk Score: {signal.risk_score}/10')
    print(f'  Slippage suggerito: {signal.suggested_slippage}%')
    print(f'\nMotivazioni:')
    for reason in signal.reasons:
        print(f'  • {reason}')
        
    print(f'\nSummary: {json.dumps(engine.get_decision_summary(), indent=2)}')

if __name__ == '__main__':
    main()
