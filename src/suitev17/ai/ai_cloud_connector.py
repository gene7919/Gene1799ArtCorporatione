#!/usr/bin/env python3
"""
SuiteV17 AI Cloud Connector v3.0
Connettore multi-provider per Groq, OpenAI, Anthropic Claude
Con fallback automatico e load balancing
"""
import os
import json
import time
import asyncio
import aiohttp
import requests
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import random

class AIProvider(Enum):
    GROQ = 'groq'
    OPENAI = 'openai'
    ANTHROPIC = 'anthropic'
    HUGGINGFACE = 'huggingface'
    LOCAL = 'local'

@dataclass
class ProviderStatus:
    name: str
    available: bool = False
    latency_ms: float = 0.0
    last_check: Optional[datetime] = None
    error_count: int = 0
    success_count: int = 0
    rate_limit_remaining: int = 1000

class AICloudConnector:
    """Connettore cloud AI universale con fallback intelligente"""
    
    def __init__(self):
        self.providers: Dict[AIProvider, ProviderStatus] = {}
        self.provider_order = [AIProvider.GROQ, AIProvider.OPENAI, AIProvider.ANTHROPIC]
        self.current_provider = AIProvider.GROQ
        self.request_history = []
        self.max_history = 1000
        self._init_providers()
        
    def _init_providers(self):
        """Inizializza tutti i provider"""
        # Carica configurazioni da env
        self.groq_key = os.getenv('GROQ_API_KEY', '')
        self.openai_key = os.getenv('OPENAI_API_KEY', '')
        self.anthropic_key = os.getenv('ANTHROPIC_API_KEY', '')
        self.hf_key = os.getenv('HUGGINGFACE_API_KEY', '')
        
        # Inizializza stati
        self.providers[AIProvider.GROQ] = ProviderStatus(
            name='Groq',
            available='gsk_' in self.groq_key and 'YOUR' not in self.groq_key
        )
        self.providers[AIProvider.OPENAI] = ProviderStatus(
            name='OpenAI',
            available='sk-' in self.openai_key and 'YOUR' not in self.openai_key
        )
        self.providers[AIProvider.ANTHROPIC] = ProviderStatus(
            name='Claude',
            available='sk-ant' in self.anthropic_key and 'YOUR' not in self.anthropic_key
        )
        self.providers[AIProvider.HUGGINGFACE] = ProviderStatus(
            name='HuggingFace',
            available='hf_' in self.hf_key and 'YOUR' not in self.hf_key
        )
        
        print(f"[AI Cloud] Provider disponibili: {[p.value for p, s in self.providers.items() if s.available]}")
        
    def get_best_provider(self) -> AIProvider:
        """Seleziona il miglior provider disponibile"""
        for provider in self.provider_order:
            if self.providers[provider].available:
                if self.providers[provider].rate_limit_remaining > 10:
                    return provider
        return AIProvider.LOCAL
        
    async def generate_text(self, prompt: str, system: Optional[str] = None, 
                           max_tokens: int = 1000, temperature: float = 0.7,
                           provider: Optional[AIProvider] = None) -> Dict[str, Any]:
        """Genera testo con fallback automatico"""
        
        if provider is None:
            provider = self.get_best_provider()
            
        start_time = time.time()
        
        try:
            if provider == AIProvider.GROQ and self.providers[AIProvider.GROQ].available:
                result = await self._call_groq(prompt, system, max_tokens, temperature)
            elif provider == AIProvider.OPENAI and self.providers[AIProvider.OPENAI].available:
                result = await self._call_openai(prompt, system, max_tokens, temperature)
            elif provider == AIProvider.ANTHROPIC and self.providers[AIProvider.ANTHROPIC].available:
                result = await self._call_anthropic(prompt, system, max_tokens, temperature)
            else:
                result = {"content": f"[Provider {provider.value} non disponibile]", "error": True}
                
            latency = (time.time() - start_time) * 1000
            self._update_provider_stats(provider, True, latency)
            
            return {
                "content": result.get("content", ""),
                "provider": provider.value,
                "latency_ms": latency,
                "timestamp": datetime.now().isoformat(),
                "success": not result.get("error", False)
            }
            
        except Exception as e:
            latency = (time.time() - start_time) * 1000
            self._update_provider_stats(provider, False, latency)
            
            # Fallback al prossimo provider
            if provider != AIProvider.LOCAL:
                next_provider = self._get_next_provider(provider)
                if next_provider:
                    return await self.generate_text(prompt, system, max_tokens, temperature, next_provider)
                    
            return {
                "content": f"[Errore: {str(e)}]",
                "provider": provider.value,
                "error": True,
                "timestamp": datetime.now().isoformat()
            }
            
    async def _call_groq(self, prompt: str, system: Optional[str], 
                        max_tokens: int, temperature: float) -> Dict:
        """Chiama API Groq"""
        from groq import Groq
        
        client = Groq(api_key=self.groq_key)
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        model = os.getenv('GROQ_MODEL', 'llama-3.3-70b-versatile')
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature
        )
        
        return {
            "content": response.choices[0].message.content,
            "tokens": response.usage.total_tokens if response.usage else 0
        }
        
    async def _call_openai(self, prompt: str, system: Optional[str],
                          max_tokens: int, temperature: float) -> Dict:
        """Chiama API OpenAI"""
        import openai
        
        client = openai.OpenAI(api_key=self.openai_key)
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        response = client.chat.completions.create(
            model="gpt-4-turbo-preview",
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature
        )
        
        return {
            "content": response.choices[0].message.content,
            "tokens": response.usage.total_tokens
        }
        
    async def _call_anthropic(self, prompt: str, system: Optional[str],
                             max_tokens: int, temperature: float) -> Dict:
        """Chiama API Anthropic Claude"""
        import anthropic
        
        client = anthropic.Anthropic(api_key=self.anthropic_key)
        
        message = client.messages.create(
            model="claude-3-opus-20240229",
            max_tokens=max_tokens,
            temperature=temperature,
            system=system or "",
            messages=[{"role": "user", "content": prompt}]
        )
        
        return {
            "content": message.content[0].text,
            "tokens": message.usage.input_tokens + message.usage.output_tokens
        }
        
    def _get_next_provider(self, current: AIProvider) -> Optional[AIProvider]:
        """Ottiene il prossimo provider nella lista"""
        try:
            idx = self.provider_order.index(current)
            if idx + 1 < len(self.provider_order):
                return self.provider_order[idx + 1]
        except ValueError:
            pass
        return None
        
    def _update_provider_stats(self, provider: AIProvider, success: bool, latency: float):
        """Aggiorna statistiche provider"""
        status = self.providers[provider]
        status.last_check = datetime.now()
        status.latency_ms = (status.latency_ms * 0.9) + (latency * 0.1)
        
        if success:
            status.success_count += 1
            status.error_count = max(0, status.error_count - 1)
        else:
            status.error_count += 1
            status.rate_limit_remaining = max(0, status.rate_limit_remaining - 50)
            
        # Log richiesta
        self.request_history.append({
            "provider": provider.value,
            "success": success,
            "latency_ms": latency,
            "timestamp": datetime.now().isoformat()
        })
        
        if len(self.request_history) > self.max_history:
            self.request_history = self.request_history[-500:]
            
    def get_stats(self) -> Dict:
        """Restituisce statistiche complete"""
        return {
            "providers": {
                p.value: {
                    "available": s.available,
                    "latency_ms": round(s.latency_ms, 2),
                    "success_rate": s.success_count / max(s.success_count + s.error_count, 1),
                    "last_check": s.last_check.isoformat() if s.last_check else None
                }
                for p, s in self.providers.items()
            },
            "total_requests": len(self.request_history),
            "current_provider": self.current_provider.value
        }
        
    async def batch_generate(self, prompts: List[str], system: Optional[str] = None,
                            max_concurrent: int = 5) -> List[Dict]:
        """Genera batch di richieste con throttling"""
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def bounded_generate(prompt):
            async with semaphore:
                return await self.generate_text(prompt, system)
                
        tasks = [bounded_generate(p) for p in prompts]
        return await asyncio.gather(*tasks)

# Singleton
ai_cloud = AICloudConnector()

if __name__ == "__main__":
    async def test():
        connector = AICloudConnector()
        print("Testing AI Cloud Connector...")
        print(f"Stats: {json.dumps(connector.get_stats(), indent=2)}")
        
        result = await connector.generate_text("Ciao! Come stai?", "Sei un assistente italiano")
        print(f"\nRisultato: {result}")
        
    asyncio.run(test())
