#!/usr/bin/env python3
"""
SuiteV17 Social Automation - Complete Implementation
Twitter/X, Discord, Telegram, Instagram, LinkedIn automation
"""
import os
import json
import requests
import asyncio
from datetime import datetime
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass, asdict
from enum import Enum
import base64
import mimetypes

# GROQ LLM Integration
try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False

class Platform(Enum):
    TWITTER = 'twitter'
    DISCORD = 'discord'
    TELEGRAM = 'telegram'
    INSTAGRAM = 'instagram'
    LINKEDIN = 'linkedin'

@dataclass
class SocialPost:
    id: str
    platform: str
    content: str
    media_urls: List[str]
    scheduled_at: Optional[str]
    posted_at: Optional[str]
    status: str  # scheduled, posted, failed
    engagement: Dict
    external_id: Optional[str]  # ID dal social (tweet_id, message_id, etc.)

class SocialAutomation:
    """Automazione completa per social media con API reali."""
    
    def __init__(self):
        self.config = self._load_config()
        self.posts: List[SocialPost] = []
        self.webhooks: Dict[str, str] = {}
        
        # Initialize Groq LLM
        self.groq_client = None
        self._init_groq()
        
    def _init_groq(self):
        """Initialize Groq LLM client."""
        if not GROQ_AVAILABLE:
            return
        groq_cfg = self.config.get('GROQ', {})
        if groq_cfg.get('enabled') and groq_cfg.get('api_key'):
            try:
                self.groq_client = Groq(api_key=groq_cfg['api_key'])
                print(f"Groq LLM initialized: {groq_cfg['model']}")
            except Exception as e:
                print(f"Groq init error: {e}")
    
    def generate_with_groq(self, prompt, system=None, max_tokens=500):
        """Generate content with Groq."""
        if not self.groq_client:
            return f"[Groq not available] {prompt}"
        try:
            msgs = []
            if system:
                msgs.append({"role": "system", "content": system})
            msgs.append({"role": "user", "content": prompt})
            resp = self.groq_client.chat.completions.create(
                model=self.config['GROQ']['model'],
                messages=msgs,
                max_tokens=max_tokens
            )
            return resp.choices[0].message.content
        except Exception as e:
            return f"[Error: {e}]"
    
    def generate_post(self, topic, platform='twitter', tone='professional'):
        """Generate social post with Groq."""
        system = f"You are a social media expert. Create {tone} content for {platform}."
        prompt = f"Write a {tone} post about: {topic}"
        return self.generate_with_groq(prompt, system, max_tokens=300)
    
    def generate_thread(self, topic, num_tweets=5):
        """Generate Twitter thread with Groq."""
        system = "You are a Twitter expert. Create engaging threads."
        prompt = f"Write a {num_tweets}-tweet thread about: {topic}"
        return self.generate_with_groq(prompt, system, max_tokens=1000)

    def _load_config(self) -> Dict:
        """Carica configurazione da environment variables."""
        return {
            Platform.TWITTER: {
                'enabled': os.getenv('TWITTER_ENABLED', 'false').lower() == 'true',
                'bearer_token': os.getenv('TWITTER_BEARER_TOKEN', ''),
                'api_key': os.getenv('TWITTER_API_KEY', ''),
                'api_secret': os.getenv('TWITTER_API_SECRET', ''),
                'access_token': os.getenv('TWITTER_ACCESS_TOKEN', ''),
                'access_secret': os.getenv('TWITTER_ACCESS_SECRET', ''),
                'base_url': 'https://api.twitter.com/2'
            },
            Platform.DISCORD: {
                'enabled': os.getenv('DISCORD_ENABLED', 'false').lower() == 'true',
                'webhook_url': os.getenv('DISCORD_WEBHOOK_URL', ''),
                'bot_token': os.getenv('DISCORD_BOT_TOKEN', ''),
                'channel_id': os.getenv('DISCORD_CHANNEL_ID', ''),
                'base_url': 'https://discord.com/api/v10'
            },
            Platform.TELEGRAM: {
                'enabled': os.getenv('TELEGRAM_ENABLED', 'false').lower() == 'true',
                'bot_token': os.getenv('TELEGRAM_BOT_TOKEN', ''),
                'channel_id': os.getenv('TELEGRAM_CHANNEL_ID', ''),
                'base_url': 'https://api.telegram.org/bot' + os.getenv('TELEGRAM_BOT_TOKEN', ''),
            },
            Platform.INSTAGRAM: {
                'enabled': os.getenv('INSTAGRAM_ENABLED', 'false').lower() == 'true',
                'access_token': os.getenv('INSTAGRAM_ACCESS_TOKEN', ''),
                'account_id': os.getenv('INSTAGRAM_ACCOUNT_ID', ''),
                'base_url': 'https://graph.facebook.com/v18.0'
            },
            Platform.LINKEDIN: {
                'enabled': os.getenv('LINKEDIN_ENABLED', 'false').lower() == 'true',
                'access_token': os.getenv('LINKEDIN_ACCESS_TOKEN', ''),
                'person_urn': os.getenv('LINKEDIN_PERSON_URN', ''),
                'base_url': 'https://api.linkedin.com/v2'
            },
            'GROQ': {
                'enabled': os.getenv('GROQ_ENABLED', 'false').lower() == 'true',
                'api_key': os.getenv('GROQ_API_KEY', ''),
                'model': os.getenv('GROQ_MODEL', 'llama-3.3-70b-versatile'),
                'base_url': 'https://api.groq.com/openai/v1'
            }
        }
    
    # ==================== TWITTER ====================
    
    def post_to_twitter(self, text: str, media_paths: List[str] = None) -> Dict:
        """Posta su Twitter/X usando API v2."""
        cfg = self.config[Platform.TWITTER]
        if not cfg['enabled']:
            return {'success': False, 'error': 'Twitter not enabled'}
        
        if not all([cfg['api_key'], cfg['api_secret'], cfg['access_token'], cfg['access_secret']]):
            return {'success': False, 'error': 'Twitter credentials not configured'}
        
        try:
            # Importa tweepy se disponibile
            try:
                import tweepy
            except ImportError:
                return {'success': False, 'error': 'tweepy not installed. Run: pip install tweepy'}
            
            # Autenticazione
            auth = tweepy.OAuth1UserHandler(
                cfg['api_key'], cfg['api_secret'],
                cfg['access_token'], cfg['access_secret']
            )
            api = tweepy.API(auth)
            client = tweepy.Client(
                consumer_key=cfg['api_key'],
                consumer_secret=cfg['api_secret'],
                access_token=cfg['access_token'],
                access_token_secret=cfg['access_secret']
            )
            
            # Upload media se presente
            media_ids = []
            if media_paths:
                for media_path in media_paths:
                    if os.path.exists(media_path):
                        media = api.media_upload(media_path)
                        media_ids.append(media.media_id)
            
            # Posta tweet
            if media_ids:
                response = client.create_tweet(text=text, media_ids=media_ids)
            else:
                response = client.create_tweet(text=text)
            
            return {
                'success': True,
                'tweet_id': response.data['id'],
                'text': text,
                'url': f'https://twitter.com/user/status/{response.data["id"]}'
            }
            
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    # ==================== DISCORD ====================
    
    def post_to_discord(self, content: str, channel: str = None, 
                        embeds: List[Dict] = None) -> Dict:
        """Posta su Discord via webhook o bot API."""
        cfg = self.config[Platform.DISCORD]
        if not cfg['enabled']:
            return {'success': False, 'error': 'Discord not enabled'}
        
        try:
            if cfg['webhook_url']:
                # Usa webhook (più semplice)
                payload = {
                    'content': content,
                    'username': 'SuiteV17 Bot',
                    'embeds': embeds or []
                }
                
                response = requests.post(
                    cfg['webhook_url'],
                    json=payload,
                    timeout=10,
                    headers={'Content-Type': 'application/json'}
                )
                
                if response.status_code == 204:
                    return {'success': True, 'platform': 'discord', 'method': 'webhook'}
                else:
                    return {'success': False, 'error': f'HTTP {response.status_code}: {response.text}'}
            
            elif cfg['bot_token'] and cfg['channel_id']:
                # Usa Bot API
                url = f"{cfg['base_url']}/channels/{cfg['channel_id']}/messages"
                payload = {
                    'content': content,
                    'embeds': embeds or []
                }
                
                response = requests.post(
                    url,
                    json=payload,
                    headers={
                        'Authorization': f"Bot {cfg['bot_token']}",
                        'Content-Type': 'application/json'
                    },
                    timeout=10
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return {
                        'success': True,
                        'platform': 'discord',
                        'method': 'bot_api',
                        'message_id': data['id']
                    }
                else:
                    return {'success': False, 'error': f'HTTP {response.status_code}: {response.text}'}
            
            else:
                return {'success': False, 'error': 'Discord webhook or bot credentials not configured'}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    # ==================== TELEGRAM ====================
    
    def post_to_telegram(self, text: str, chat_id: str = None, 
                         parse_mode: str = 'HTML') -> Dict:
        """Posta su Telegram usando Bot API."""
        cfg = self.config[Platform.TELEGRAM]
        if not cfg['enabled']:
            return {'success': False, 'error': 'Telegram not enabled'}
        
        if not cfg['bot_token']:
            return {'success': False, 'error': 'Telegram bot token not configured'}
        
        chat = chat_id or cfg['channel_id']
        if not chat:
            return {'success': False, 'error': 'Telegram chat ID not configured'}
        
        try:
            url = f"https://api.telegram.org/bot{cfg['bot_token']}/sendMessage"
            payload = {
                'chat_id': chat,
                'text': text,
                'parse_mode': parse_mode
            }
            
            response = requests.post(url, json=payload, timeout=10)
            data = response.json()
            
            if data.get('ok'):
                return {
                    'success': True,
                    'platform': 'telegram',
                    'message_id': data['result']['message_id'],
                    'chat_id': data['result']['chat']['id']
                }
            else:
                return {'success': False, 'error': data.get('description', 'Unknown error')}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def send_telegram_photo(self, chat_id: str, photo_path: str, 
                           caption: str = None) -> Dict:
        """Invia foto su Telegram."""
        cfg = self.config[Platform.TELEGRAM]
        if not cfg['enabled'] or not cfg['bot_token']:
            return {'success': False, 'error': 'Telegram not configured'}
        
        try:
            url = f"https://api.telegram.org/bot{cfg['bot_token']}/sendPhoto"
            
            with open(photo_path, 'rb') as photo:
                files = {'photo': photo}
                data = {'chat_id': chat_id or cfg['channel_id']}
                if caption:
                    data['caption'] = caption
                    data['parse_mode'] = 'HTML'
                
                response = requests.post(url, files=files, data=data, timeout=30)
                data = response.json()
                
                if data.get('ok'):
                    return {'success': True, 'message_id': data['result']['message_id']}
                else:
                    return {'success': False, 'error': data.get('description')}
                    
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    # ==================== INSTAGRAM ====================
    
    def post_to_instagram(self, image_path: str, caption: str) -> Dict:
        """Posta su Instagram usando Graph API."""
        cfg = self.config[Platform.INSTAGRAM]
        if not cfg['enabled']:
            return {'success': False, 'error': 'Instagram not enabled'}
        
        if not all([cfg['access_token'], cfg['account_id']]):
            return {'success': False, 'error': 'Instagram credentials not configured'}
        
        try:
            # Step 1: Crea container media
            url = f"{cfg['base_url']}/{cfg['account_id']}/media"
            
            # Per ora supportiamo solo URL immagini (Instagram richiede hosting pubblico)
            payload = {
                'image_url': image_path if image_path.startswith('http') else None,
                'caption': caption,
                'access_token': cfg['access_token']
            }
            
            if not payload['image_url']:
                return {
                    'success': False, 
                    'error': 'Instagram requires publicly hosted images. Upload to cloud first.'
                }
            
            response = requests.post(url, data=payload, timeout=30)
            data = response.json()
            
            if 'id' not in data:
                return {'success': False, 'error': data.get('error', {}).get('message', 'Unknown error')}
            
            creation_id = data['id']
            
            # Step 2: Pubblica container
            publish_url = f"{cfg['base_url']}/{cfg['account_id']}/media_publish"
            publish_payload = {
                'creation_id': creation_id,
                'access_token': cfg['access_token']
            }
            
            publish_response = requests.post(publish_url, data=publish_payload, timeout=30)
            publish_data = publish_response.json()
            
            if 'id' in publish_data:
                return {
                    'success': True,
                    'platform': 'instagram',
                    'media_id': publish_data['id']
                }
            else:
                return {'success': False, 'error': publish_data.get('error', {}).get('message')}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    # ==================== LINKEDIN ====================
    
    def post_to_linkedin(self, text: str, visibility: str = 'PUBLIC') -> Dict:
        """Posta su LinkedIn usando REST API."""
        cfg = self.config[Platform.LINKEDIN]
        if not cfg['enabled']:
            return {'success': False, 'error': 'LinkedIn not enabled'}
        
        if not cfg['access_token']:
            return {'success': False, 'error': 'LinkedIn access token not configured'}
        
        try:
            url = f"{cfg['base_url']}/ugcPosts"
            
            author_urn = cfg['person_urn'] or f"urn:li:person:me"
            
            payload = {
                'author': author_urn,
                'lifecycleState': 'PUBLISHED',
                'specificContent': {
                    'com.linkedin.ugc.ShareContent': {
                        'shareCommentary': {
                            'text': text
                        },
                        'shareMediaCategory': 'NONE'
                    }
                },
                'visibility': {
                    'com.linkedin.ugc.MemberNetworkVisibility': visibility
                }
            }
            
            response = requests.post(
                url,
                json=payload,
                headers={
                    'Authorization': f"Bearer {cfg['access_token']}",
                    'Content-Type': 'application/json',
                    'X-Restli-Protocol-Version': '2.0.0'
                },
                timeout=10
            )
            
            if response.status_code == 201:
                return {
                    'success': True,
                    'platform': 'linkedin',
                    'post_urn': response.headers.get('X-RestLi-Id')
                }
            else:
                return {'success': False, 'error': f'HTTP {response.status_code}: {response.text}'}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    # ==================== UNIFIED API ====================
    
    def broadcast(self, content: str, platforms: List[str] = None,
                  media_paths: List[str] = None) -> Dict[str, Dict]:
        """Broadcast a multiple piattaforme."""
        if platforms is None:
            platforms = ['twitter', 'discord', 'telegram']
        
        results = {}
        
        if 'twitter' in platforms:
            results['twitter'] = self.post_to_twitter(content, media_paths)
        if 'discord' in platforms:
            results['discord'] = self.post_to_discord(content)
        if 'telegram' in platforms:
            results['telegram'] = self.post_to_telegram(content)
        if 'instagram' in platforms:
            if media_paths:
                results['instagram'] = self.post_to_instagram(media_paths[0], content)
        if 'linkedin' in platforms:
            results['linkedin'] = self.post_to_linkedin(content)
        
        return results
    
    def schedule_post(self, content: str, platform: str, 
                     scheduled_time: str, media_paths: List[str] = None) -> str:
        """Schedula un post per pubblicazione futura."""
        import uuid
        post_id = f'post_{uuid.uuid4().hex[:8]}'
        
        post = SocialPost(
            id=post_id,
            platform=platform,
            content=content,
            media_urls=media_paths or [],
            scheduled_at=scheduled_time,
            posted_at=None,
            status='scheduled',
            engagement={},
            external_id=None
        )
        
        self.posts.append(post)
        
        # Qui potresti salvare su database o file
        # Per ora è in memoria
        
        print(f'[SocialAutomation] Post scheduled for {platform} at {scheduled_time}: {post_id}')
        return post_id
    
    def get_analytics(self) -> Dict:
        """Recupera analytics aggregati."""
        by_platform = {}
        for post in self.posts:
            platform = post.platform
            if platform not in by_platform:
                by_platform[platform] = {'total': 0, 'posted': 0, 'scheduled': 0}
            by_platform[platform]['total'] += 1
            by_platform[platform][post.status] += 1
        
        return {
            'total_posts': len(self.posts),
            'by_platform': by_platform,
            'configuration': {
                platform.value: cfg['enabled']
                for platform, cfg in self.config.items()
            }
        }
    
    def test_connections(self) -> Dict:
        """Testa tutte le connessioni configurate."""
        results = {}
        
        for platform, cfg in self.config.items():
            if not cfg['enabled']:
                results[platform.value] = {'status': 'disabled'}
                continue
            
            try:
                if platform == Platform.TWITTER:
                    # Test con bearer token
                    if cfg['bearer_token']:
                        headers = {'Authorization': f"Bearer {cfg['bearer_token']}"}
                        resp = requests.get(
                            'https://api.twitter.com/2/users/me',
                            headers=headers,
                            timeout=10
                        )
                        results['twitter'] = {'status': 'connected' if resp.status_code == 200 else 'auth_failed'}
                    else:
                        results['twitter'] = {'status': 'not_configured'}
                
                elif platform == Platform.DISCORD:
                    if cfg['webhook_url']:
                        # Test webhook
                        resp = requests.post(
                            cfg['webhook_url'],
                            json={'content': 'Test message from SuiteV17'},
                            timeout=10
                        )
                        results['discord'] = {'status': 'connected' if resp.status_code == 204 else 'failed'}
                
                elif platform == Platform.TELEGRAM:
                    if cfg['bot_token']:
                        resp = requests.get(
                            f"https://api.telegram.org/bot{cfg['bot_token']}/getMe",
                            timeout=10
                        )
                        data = resp.json()
                        results['telegram'] = {
                            'status': 'connected' if data.get('ok') else 'failed',
                            'bot_name': data['result']['username'] if data.get('ok') else None
                        }
                
                else:
                    results[platform.value] = {'status': 'not_tested'}
                    
            except Exception as e:
                results[platform.value] = {'status': 'error', 'error': str(e)}
        
        return results

def main():
    """Demo del sistema di automazione social."""
    print('=' * 70)
    print('SOCIAL AUTOMATION - SuiteV17')
    print('=' * 70)
    print()
    
    social = SocialAutomation()
    
    print('Configurazione piattaforme:')
    config = social.config
    for platform, cfg in config.items():
        status = '? Enabled' if cfg['enabled'] else '? Disabled'
        print(f'  {platform.value:12} {status}')
    
    print()
    print('Test connessioni:')
    results = social.test_connections()
    for platform, result in results.items():
        print(f'  {platform:12} {result["status"]}')
    
    print()
    print('Esempio di broadcast:')
    print('  social.broadcast("Hello from SuiteV17!", platforms=["discord", "telegram"])')

if __name__ == '__main__':
    main()
