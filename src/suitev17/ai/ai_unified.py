#!/usr/bin/env python3
"""
SuiteV17 Unified AI Interface v2.0
Dashboard-ready with comprehensive error handling and metrics
"""

import os
import sys
import json
import time
import requests
import argparse
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List, Any
from dataclasses import dataclass, field, asdict
from enum import Enum

sys.path.insert(0, r'C:\SuiteV17')

class AIModule(Enum):
    TEXT = 'text'
    AUDIO = 'audio'
    IMAGE = 'image'
    VIDEO = 'video'
    VOICE = 'voice'
    CODE = 'code'

@dataclass 
class AIRequest:
    module: AIModule
    prompt: str
    output_path: Optional[str] = None
    options: Dict = field(default_factory=dict)
    timestamp: str = field(default_factory=lambda: datetime.now().isoformat())
    
@dataclass
class AIResponse:
    success: bool
    content: str
    module: str
    latency_ms: float
    timestamp: str
    error: Optional[str] = None
    metadata: Dict = field(default_factory=dict)

@dataclass
class AIMetrics:
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    avg_latency_ms: float = 0.0
    last_request: Optional[str] = None
    provider_status: Dict = field(default_factory=dict)

class UnifiedAI:
    """AI unificato con metriche e gestione errori avanzata."""
    
    def __init__(self):
        self.load_env()
        self.groq_client = None
        self.metrics = AIMetrics()
        self.request_history = []
        self.init_groq()
        
    def load_env(self):
        env_path = Path(r'C:\SuiteV17\.env')
        if env_path.exists():
            with open(env_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if '=' in line and not line.startswith('#'):
                        try:
                            key, value = line.strip().split('=', 1)
                            os.environ.setdefault(key, value)
                        except ValueError:
                            continue
    
    def init_groq(self):
        try:
            from groq import Groq
            api_key = os.getenv('GROQ_API_KEY')
            if api_key and 'YOUR' not in api_key:
                self.groq_client = Groq(api_key=api_key)
                self.metrics.provider_status['groq'] = 'connected'
                print('[UnifiedAI] Groq LLM connesso')
            else:
                self.metrics.provider_status['groq'] = 'not_configured'
        except ImportError:
            self.metrics.provider_status['groq'] = 'missing_library'
            print('[UnifiedAI] Libreria groq non installata: pip install groq')
        except Exception as e:
            self.metrics.provider_status['groq'] = f'error: {str(e)}'
            print(f'[UnifiedAI] Errore Groq: {e}')
    
    def _update_metrics(self, success: bool, latency_ms: float):
        self.metrics.total_requests += 1
        self.metrics.last_request = datetime.now().isoformat()
        if success:
            self.metrics.successful_requests += 1
        else:
            self.metrics.failed_requests += 1
        # Aggiorna latenza media
        self.metrics.avg_latency_ms = (
            self.metrics.avg_latency_ms * 0.9 + latency_ms * 0.1
        )
    
    def generate_text(self, prompt, system=None, max_tokens=500) -> AIResponse:
        start = time.time()
        if not self.groq_client:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content=f'[Groq non disponibile] Prompt ricevuto: {prompt[:100]}...',
                module='text',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error='Groq client not initialized'
            )
        try:
            messages = []
            if system:
                messages.append({'role': 'system', 'content': system})
            messages.append({'role': 'user', 'content': prompt})
            model = os.getenv('GROQ_MODEL', 'llama-3.3-70b-versatile')
            response = self.groq_client.chat.completions.create(
                model=model, messages=messages, max_tokens=max_tokens, temperature=0.7
            )
            content = response.choices[0].message.content
            latency = (time.time() - start) * 1000
            self._update_metrics(True, latency)
            
            return AIResponse(
                success=True,
                content=content,
                module='text',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                metadata={'model': model, 'tokens_used': response.usage.total_tokens if response.usage else 0}
            )
        except Exception as e:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content=f'[Errore: {e}]',
                module='text',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def generate_audio(self, prompt, output_path=None, duration=10) -> AIResponse:
        start = time.time()
        api_key = os.getenv('HUGGINGFACE_API_KEY', '')
        if not api_key or 'YOUR' in api_key:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content='ERRORE: HUGGINGFACE_API_KEY non configurata',
                module='audio',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error='API key not configured'
            )
        model = os.getenv('HUGGINGFACE_MODEL_AUDIO', 'facebook/musicgen-small')
        api_url = f'https://api-inference.huggingface.co/models/{model}'
        if not output_path:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_path = f'./outputs/ai_generated/audio_{timestamp}.wav'
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        try:
            headers = {'Authorization': f'Bearer {api_key}'}
            payload = {'inputs': prompt}
            response = requests.post(api_url, headers=headers, json=payload, timeout=120)
            latency = (time.time() - start) * 1000
            if response.status_code == 200:
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                self._update_metrics(True, latency)
                return AIResponse(
                    success=True,
                    content=f'Audio generato: {output_path}',
                    module='audio',
                    latency_ms=latency,
                    timestamp=datetime.now().isoformat(),
                    metadata={'path': output_path}
                )
            else:
                self._update_metrics(False, latency)
                return AIResponse(
                    success=False,
                    content=f'Errore API: {response.status_code}',
                    module='audio',
                    latency_ms=latency,
                    timestamp=datetime.now().isoformat(),
                    error=f'HTTP {response.status_code}'
                )
        except Exception as e:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content=f'Errore: {e}',
                module='audio',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def generate_image(self, prompt, output_path=None) -> AIResponse:
        start = time.time()
        api_key = os.getenv('HUGGINGFACE_API_KEY', '')
        if not api_key or 'YOUR' in api_key:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content='ERRORE: HUGGINGFACE_API_KEY non configurata',
                module='image',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error='API key not configured'
            )
        model = os.getenv('HUGGINGFACE_MODEL_IMAGE', 'stabilityai/stable-diffusion-xl-base-1.0')
        api_url = f'https://api-inference.huggingface.co/models/{model}'
        if not output_path:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_path = f'./outputs/ai_generated/image_{timestamp}.png'
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        try:
            headers = {'Authorization': f'Bearer {api_key}'}
            payload = {'inputs': prompt}
            response = requests.post(api_url, headers=headers, json=payload, timeout=120)
            latency = (time.time() - start) * 1000
            if response.status_code == 200:
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                self._update_metrics(True, latency)
                return AIResponse(
                    success=True,
                    content=f'Immagine generata: {output_path}',
                    module='image',
                    latency_ms=latency,
                    timestamp=datetime.now().isoformat(),
                    metadata={'path': output_path}
                )
            else:
                self._update_metrics(False, latency)
                return AIResponse(
                    success=False,
                    content=f'Errore API: {response.status_code}',
                    module='image',
                    latency_ms=latency,
                    timestamp=datetime.now().isoformat(),
                    error=f'HTTP {response.status_code}'
                )
        except Exception as e:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content=f'Errore: {e}',
                module='image',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def generate_voice(self, text, output_path=None, voice='it-IT-ElsaNeural') -> AIResponse:
        start = time.time()
        try:
            import edge_tts
            if not output_path:
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                output_path = f'./outputs/ai_generated/voice_{timestamp}.mp3'
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            
            async def generate():
                communicate = edge_tts.Communicate(text, voice)
                await communicate.save(output_path)
                
            asyncio.run(generate())
            latency = (time.time() - start) * 1000
            self._update_metrics(True, latency)
            return AIResponse(
                success=True,
                content=f'Voce generata: {output_path}',
                module='voice',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                metadata={'path': output_path, 'voice': voice}
            )
        except ImportError:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content='ERRORE: pip install edge-tts richiesto',
                module='voice',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error='edge-tts not installed'
            )
        except Exception as e:
            latency = (time.time() - start) * 1000
            self._update_metrics(False, latency)
            return AIResponse(
                success=False,
                content=f'Errore: {e}',
                module='voice',
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                error=str(e)
            )
    
    def generate(self, module: str, prompt: str, **kwargs) -> AIResponse:
        if module == 'text':
            return self.generate_text(prompt, kwargs.get('system'))
        elif module == 'audio':
            return self.generate_audio(prompt, kwargs.get('output'), kwargs.get('duration', 10))
        elif module == 'image':
            return self.generate_image(prompt, kwargs.get('output'))
        elif module == 'voice':
            return self.generate_voice(prompt, kwargs.get('output'), kwargs.get('voice', 'it-IT-ElsaNeural'))
        return AIResponse(
            success=False,
            content=f'Modulo {module} non supportato',
            module=module,
            latency_ms=0,
            timestamp=datetime.now().isoformat(),
            error='Unsupported module'
        )
    
    def get_metrics(self) -> Dict:
        return asdict(self.metrics)
    
    def get_status(self) -> Dict:
        return {
            'groq_ready': self.groq_client is not None,
            'metrics': self.get_metrics(),
            'env_configured': {
                'groq': bool(os.getenv('GROQ_API_KEY') and 'YOUR' not in os.getenv('GROQ_API_KEY', '')),
                'huggingface': bool(os.getenv('HUGGINGFACE_API_KEY') and 'YOUR' not in os.getenv('HUGGINGFACE_API_KEY', ''))
            }
        }

def main():
    parser = argparse.ArgumentParser(description='SuiteV17 Unified AI v2.0')
    parser.add_argument('module', choices=['text', 'audio', 'image', 'voice', 'status'])
    parser.add_argument('--prompt', '-p', default='')
    parser.add_argument('--output', '-o')
    parser.add_argument('--duration', '-d', type=int, default=10)
    parser.add_argument('--voice', '-v', default='it-IT-ElsaNeural')
    args = parser.parse_args()
    
    ai = UnifiedAI()
    
    if args.module == 'status':
        print(json.dumps(ai.get_status(), indent=2))
    else:
        result = ai.generate(args.module, args.prompt, output=args.output, 
                           duration=args.duration, voice=args.voice)
        print(json.dumps(asdict(result), indent=2))

if __name__ == '__main__':
    main()
