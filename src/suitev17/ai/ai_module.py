#!/usr/bin/env python3
"""
SuiteV17 AI Module - LLM Integration
Supporta Ollama, OpenAI, Anthropic, e modelli locali
"""
import os
import json
import requests
import asyncio
from typing import Dict, List, Optional, Any, AsyncGenerator
from dataclasses import dataclass
from enum import Enum

class AIProvider(Enum):
    OLLAMA = 'ollama'
    OPENAI = 'openai'
    ANTHROPIC = 'anthropic'
    LOCAL = 'local'

@dataclass
class AIMessage:
    role: str
    content: str
    metadata: Optional[Dict] = None

@dataclass
class AIResponse:
    content: str
    model: str
    provider: AIProvider
    tokens_used: Optional[int]
    latency_ms: float
    metadata: Optional[Dict]

class AIClient:
    """Client AI universale per SuiteV17."""
    
    def __init__(self, provider: AIProvider = AIProvider.OLLAMA):
        self.provider = provider
        self.config = self._load_config()
        self.conversation_history: List[AIMessage] = []
        
    def _load_config(self) -> Dict:
        """Carica configurazione AI."""
        return {
            AIProvider.OLLAMA: {
                'base_url': os.getenv('OLLAMA_URL', 'http://localhost:11434'),
                'default_model': os.getenv('OLLAMA_MODEL', 'llama3.1'),
                'timeout': 120
            },
            AIProvider.OPENAI: {
                'api_key': os.getenv('OPENAI_API_KEY', ''),
                'default_model': os.getenv('OPENAI_MODEL', 'gpt-4'),
                'timeout': 60
            },
            AIProvider.ANTHROPIC: {
                'api_key': os.getenv('ANTHROPIC_API_KEY', ''),
                'default_model': os.getenv('ANTHROPIC_MODEL', 'claude-3-opus'),
                'timeout': 60
            }
        }.get(self.provider, {})
        
    def chat(self, message: str, system_prompt: str = None, 
             model: str = None, stream: bool = False) -> AIResponse:
        """Chat completion."""
        if self.provider == AIProvider.OLLAMA:
            return self._chat_ollama(message, system_prompt, model, stream)
        elif self.provider == AIProvider.OPENAI:
            return self._chat_openai(message, system_prompt, model, stream)
        elif self.provider == AIProvider.ANTHROPIC:
            return self._chat_anthropic(message, system_prompt, model, stream)
        else:
            raise ValueError(f'Unknown provider: {self.provider}')
            
    def _chat_ollama(self, message: str, system_prompt: str = None,
                     model: str = None, stream: bool = False) -> AIResponse:
        """Chat con Ollama."""
        import time
        start = time.time()
        
        cfg = self.config
        url = f"{cfg['base_url']}/api/generate"
        
        model = model or cfg['default_model']
        
        # Build prompt with history
        prompt = self._build_prompt(message, system_prompt)
        
        payload = {
            'model': model,
            'prompt': prompt,
            'stream': stream,
            'options': {
                'temperature': 0.7,
                'num_predict': 2048
            }
        }
        
        response = requests.post(url, json=payload, timeout=cfg['timeout'])
        response.raise_for_status()
        
        data = response.json()
        latency = (time.time() - start) * 1000
        
        # Aggiungi a history
        self.conversation_history.append(AIMessage('user', message))
        self.conversation_history.append(AIMessage('assistant', data.get('response', '')))
        
        return AIResponse(
            content=data.get('response', ''),
            model=model,
            provider=AIProvider.OLLAMA,
            tokens_used=data.get('eval_count', 0),
            latency_ms=latency,
            metadata={'total_duration': data.get('total_duration')}
        )
        
    def _chat_openai(self, message: str, system_prompt: str = None,
                     model: str = None, stream: bool = False) -> AIResponse:
        """Chat con OpenAI."""
        import time
        start = time.time()
        
        cfg = self.config
        url = 'https://api.openai.com/v1/chat/completions'
        
        messages = []
        if system_prompt:
            messages.append({'role': 'system', 'content': system_prompt})
        messages.append({'role': 'user', 'content': message})
        
        headers = {
            'Authorization': f"Bearer {cfg['api_key']}",
            'Content-Type': 'application/json'
        }
        
        payload = {
            'model': model or cfg['default_model'],
            'messages': messages,
            'stream': stream,
            'temperature': 0.7
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=cfg['timeout'])
        response.raise_for_status()
        
        data = response.json()
        latency = (time.time() - start) * 1000
        
        return AIResponse(
            content=data['choices'][0]['message']['content'],
            model=data['model'],
            provider=AIProvider.OPENAI,
            tokens_used=data.get('usage', {}).get('total_tokens'),
            latency_ms=latency,
            metadata={'finish_reason': data['choices'][0].get('finish_reason')}
        )
        
    def _chat_anthropic(self, message: str, system_prompt: str = None,
                        model: str = None, stream: bool = False) -> AIResponse:
        """Chat con Anthropic Claude."""
        import time
        start = time.time()
        
        cfg = self.config
        url = 'https://api.anthropic.com/v1/messages'
        
        headers = {
            'x-api-key': cfg['api_key'],
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json'
        }
        
        payload = {
            'model': model or cfg['default_model'],
            'max_tokens': 4096,
            'messages': [{'role': 'user', 'content': message}],
            'system': system_prompt or ''
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=cfg['timeout'])
        response.raise_for_status()
        
        data = response.json()
        latency = (time.time() - start) * 1000
        
        return AIResponse(
            content=data['content'][0]['text'],
            model=data['model'],
            provider=AIProvider.ANTHROPIC,
            tokens_used=data.get('usage', {}).get('input_tokens', 0) + data.get('usage', {}).get('output_tokens', 0),
            latency_ms=latency,
            metadata={'stop_reason': data.get('stop_reason')}
        )
        
    def _build_prompt(self, message: str, system_prompt: str = None) -> str:
        """Costruisce prompt con history."""
        parts = []
        if system_prompt:
            parts.append(f"System: {system_prompt}")
            
        # Aggiungi history recente
        for msg in self.conversation_history[-6:]:
            parts.append(f"{msg.role.capitalize()}: {msg.content}")
            
        parts.append(f"User: {message}")
        parts.append("Assistant:")
        
        return '\n\n'.join(parts)
        
    def clear_history(self):
        """Pulisce history."""
        self.conversation_history = []
        
    def generate_code(self, description: str, language: str = 'python') -> str:
        """Genera codice."""
        prompt = f"""Generate {language} code for:
{description}

Requirements:
- Clean, well-documented code
- Error handling
- Best practices

Output only the code without explanation."""
        
        response = self.chat(prompt)
        return response.content
        
    def analyze_code(self, code: str) -> Dict:
        """Analizza codice."""
        prompt = f"""Analyze this code and provide:
1. Potential bugs
2. Security issues
3. Performance optimizations
4. Code quality suggestions

Code:
```
{code}
```

Return JSON format."""
        
        response = self.chat(prompt)
        try:
            return json.loads(response.content)
        except:
            return {'analysis': response.content}
            
    def summarize_text(self, text: str, max_length: int = 200) -> str:
        """Summarize text."""
        prompt = f"Summarize the following text in {max_length} characters or less:\n\n{text}"
        response = self.chat(prompt)
        return response.content
        
    def extract_entities(self, text: str) -> List[Dict]:
        """Estrae entità da testo."""
        prompt = f"""Extract named entities from this text.
Return JSON array with entity name, type, and confidence.

Text: {text}"""
        
        response = self.chat(prompt)
        try:
            return json.loads(response.content)
        except:
            return [{'error': 'Failed to parse', 'raw': response.content}]

class AIAgent:
    """Agente AI specializzato per SuiteV17."""
    
    def __init__(self, name: str, role: str, client: AIClient = None):
        self.name = name
        self.role = role
        self.client = client or AIClient()
        self.system_prompt = self._build_system_prompt()
        
    def _build_system_prompt(self) -> str:
        """Costruisce system prompt per agente."""
        prompts = {
            'code_reviewer': 'You are an expert code reviewer. Focus on bugs, security, and performance.',
            'architect': 'You are a system architect. Design scalable, maintainable solutions.',
            'trader': 'You are a crypto trading analyst. Analyze market data and provide insights.',
            'assistant': 'You are a helpful AI assistant for SuiteV17.'
        }
        return prompts.get(self.role, prompts['assistant'])
        
    def ask(self, question: str) -> str:
        """Pone domanda all'agente."""
        response = self.client.chat(question, self.system_prompt)
        return response.content
        
    def review_code(self, code: str, language: str = 'python') -> Dict:
        """Review codice."""
        prompt = f"""Review this {language} code:

```
{code}
```

Provide:
- Summary
- Issues found (severity: critical/high/medium/low)
- Suggested fixes
- Overall rating (1-10)"""

        response = self.client.chat(prompt, self.system_prompt)
        return {
            'review': response.content,
            'model': response.model,
            'latency_ms': response.latency_ms
        }

def main():
    """Test AI module."""
    client = AIClient(provider=AIProvider.OLLAMA)
    
    print('Testing AI module...')
    response = client.chat('Hello, introduce yourself briefly')
    print(f'Response: {response.content[:200]}...')
    print(f'Model: {response.model}')
    print(f'Latency: {response.latency_ms:.0f}ms')

if __name__ == '__main__':
    main()
