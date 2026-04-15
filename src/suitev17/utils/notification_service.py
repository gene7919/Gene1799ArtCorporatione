#!/usr/bin/env python3
"""
SuiteV17 Notification Service - Sistema notifiche unificato multi-canale
Email, SMS, Telegram, Discord, Push, Webhook
"""
import os
import json
import asyncio
import aiohttp
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging

logger = logging.getLogger(__name__)

class NotificationPriority(Enum):
    CRITICAL = 'critical'  # Immediata, tutti i canali
    HIGH = 'high'       # Immediata, canali principali
    NORMAL = 'normal'   # Standard
    LOW = 'low'         # Batch, non urgente

class NotificationChannel(Enum):
    EMAIL = 'email'
    SMS = 'sms'
    TELEGRAM = 'telegram'
    DISCORD = 'discord'
    SLACK = 'slack'
    WEBHOOK = 'webhook'
    PUSH = 'push'

@dataclass
class Notification:
    id: str
    title: str
    message: str
    priority: NotificationPriority
    channels: List[NotificationChannel]
    recipients: List[str]
    metadata: Dict[str, Any]
    created_at: str
    sent_at: Optional[str]
    status: str  # pending, sending, sent, failed

class BaseNotifier:
    """Base class per notificatori."""
    
    def __init__(self, config: Dict = None):
        self.config = config or {}
        self.enabled = self.config.get('enabled', False)
    
    async def send(self, notification: Notification) -> bool:
        """Invia notifica - da implementare nelle subclass."""
        raise NotImplementedError()
    
    def is_configured(self) -> bool:
        """Verifica se il canale è configurato."""
        return self.enabled

class EmailNotifier(BaseNotifier):
    """Notificatore Email."""
    
    async def send(self, notification: Notification) -> bool:
        if not self.is_configured():
            return False
        
        try:
            smtp_host = self.config.get('smtp_host', 'smtp.gmail.com')
            smtp_port = self.config.get('smtp_port', 587)
            username = self.config.get('username')
            password = self.config.get('password')
            from_email = self.config.get('from_email')
            
            if not all([username, password]):
                logger.error('Email credentials not configured')
                return False
            
            # Costruisci email
            msg = MIMEMultipart()
            msg['From'] = from_email
            msg['To'] = ', '.join(notification.recipients)
            msg['Subject'] = f'[{notification.priority.value.upper()}] {notification.title}'
            
            body = f'''SuiteV17 Notification

Title: {notification.title}
Priority: {notification.priority.value}
Time: {notification.created_at}

Message:
{notification.message}

---
Sent by SuiteV17 Notification Service
'''
            msg.attach(MIMEText(body, 'plain'))
            
            # Invia
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self._send_sync, smtp_host, smtp_port, 
                                        username, password, msg)
            
            logger.info(f'Email sent: {notification.title}')
            return True
            
        except Exception as e:
            logger.error(f'Email send failed: {e}')
            return False
    
    def _send_sync(self, host, port, user, pwd, msg):
        with smtplib.SMTP(host, port) as server:
            server.starttls()
            server.login(user, pwd)
            server.send_message(msg)

class TelegramNotifier(BaseNotifier):
    """Notificatore Telegram."""
    
    async def send(self, notification: Notification) -> bool:
        if not self.is_configured():
            return False
        
        try:
            bot_token = self.config.get('bot_token')
            if not bot_token:
                return False
            
            message = f'*[{notification.priority.value.upper()}] {notification.title}*\\n\\n'
            message += notification.message
            
            async with aiohttp.ClientSession() as session:
                for chat_id in notification.recipients:
                    url = f'https://api.telegram.org/bot{bot_token}/sendMessage'
                    payload = {
                        'chat_id': chat_id,
                        'text': message,
                        'parse_mode': 'Markdown'
                    }
                    
                    async with session.post(url, json=payload) as resp:
                        if resp.status != 200:
                            logger.error(f'Telegram send failed: {resp.status}')
                            return False
            
            logger.info(f'Telegram sent: {notification.title}')
            return True
            
        except Exception as e:
            logger.error(f'Telegram error: {e}')
            return False

class DiscordNotifier(BaseNotifier):
    """Notificatore Discord."""
    
    async def send(self, notification: Notification) -> bool:
        if not self.is_configured():
            return False
        
        try:
            webhook_url = self.config.get('webhook_url')
            if not webhook_url:
                return False
            
            embed = {
                'title': notification.title,
                'description': notification.message,
                'color': self._get_color(notification.priority),
                'timestamp': datetime.now().isoformat(),
                'footer': {'text': 'SuiteV17 Notification'}
            }
            
            async with aiohttp.ClientSession() as session:
                payload = {'embeds': [embed]}
                async with session.post(webhook_url, json=payload) as resp:
                    if resp.status != 204:
                        logger.error(f'Discord send failed: {resp.status}')
                        return False
            
            logger.info(f'Discord sent: {notification.title}')
            return True
            
        except Exception as e:
            logger.error(f'Discord error: {e}')
            return False
    
    def _get_color(self, priority: NotificationPriority) -> int:
        colors = {
            NotificationPriority.CRITICAL: 0xff0000,  # Rosso
            NotificationPriority.HIGH: 0xff8800,       # Arancione
            NotificationPriority.NORMAL: 0x00ff00,     # Verde
            NotificationPriority.LOW: 0x808080       # Grigio
        }
        return colors.get(priority, 0x808080)

class WebhookNotifier(BaseNotifier):
    """Notificatore Webhook generico."""
    
    async def send(self, notification: Notification) -> bool:
        if not self.is_configured():
            return False
        
        try:
            webhook_url = self.config.get('webhook_url')
            if not webhook_url:
                return False
            
            payload = {
                'notification': {
                    'id': notification.id,
                    'title': notification.title,
                    'message': notification.message,
                    'priority': notification.priority.value,
                    'created_at': notification.created_at,
                    'metadata': notification.metadata
                }
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(webhook_url, json=payload) as resp:
                    if resp.status >= 400:
                        logger.error(f'Webhook failed: {resp.status}')
                        return False
            
            logger.info(f'Webhook sent: {notification.title}')
            return True
            
        except Exception as e:
            logger.error(f'Webhook error: {e}')
            return False

class NotificationService:
    """Servizio notifiche unificato."""
    
    def __init__(self):
        self.notifiers: Dict[NotificationChannel, BaseNotifier] = {}
        self.history: List[Notification] = []
        self.max_history = 1000
        
        self._load_config()
    
    def _load_config(self):
        """Carica configurazione da env."""
        # Email
        if os.getenv('SMTP_HOST'):
            self.notifiers[NotificationChannel.EMAIL] = EmailNotifier({
                'enabled': True,
                'smtp_host': os.getenv('SMTP_HOST'),
                'smtp_port': int(os.getenv('SMTP_PORT', 587)),
                'username': os.getenv('SMTP_USER'),
                'password': os.getenv('SMTP_PASS'),
                'from_email': os.getenv('SMTP_FROM')
            })
        
        # Telegram
        if os.getenv('TELEGRAM_BOT_TOKEN'):
            self.notifiers[NotificationChannel.TELEGRAM] = TelegramNotifier({
                'enabled': True,
                'bot_token': os.getenv('TELEGRAM_BOT_TOKEN')
            })
        
        # Discord
        if os.getenv('DISCORD_WEBHOOK_URL'):
            self.notifiers[NotificationChannel.DISCORD] = DiscordNotifier({
                'enabled': True,
                'webhook_url': os.getenv('DISCORD_WEBHOOK_URL')
            })
    
    async def notify(self, title: str, message: str,
                     priority: NotificationPriority = NotificationPriority.NORMAL,
                     channels: List[NotificationChannel] = None,
                     recipients: List[str] = None,
                     metadata: Dict = None) -> Notification:
        """Invia notifica."""
        import uuid
        
        notification = Notification(
            id=str(uuid.uuid4()),
            title=title,
            message=message,
            priority=priority,
            channels=channels or [NotificationChannel.EMAIL],
            recipients=recipients or [],
            metadata=metadata or {},
            created_at=datetime.now().isoformat(),
            sent_at=None,
            status='pending'
        )
        
        # Determina canali in base a priorità
        if priority == NotificationPriority.CRITICAL:
            channels = list(self.notifiers.keys())
        elif priority == NotificationPriority.HIGH:
            channels = [c for c in self.notifiers.keys() 
                       if c in [NotificationChannel.EMAIL, NotificationChannel.TELEGRAM, NotificationChannel.DISCORD]]
        
        # Invia su tutti i canali
        results = []
        for channel in channels:
            notifier = self.notifiers.get(channel)
            if notifier:
                success = await notifier.send(notification)
                results.append({'channel': channel.value, 'success': success})
        
        # Aggiorna stato
        notification.sent_at = datetime.now().isoformat()
        notification.status = 'sent' if any(r['success'] for r in results) else 'failed'
        
        # Salva history
        self.history.append(notification)
        if len(self.history) > self.max_history:
            self.history.pop(0)
        
        return notification
    
    async def notify_critical(self, title: str, message: str, recipients: List[str] = None):
        """Shortcut per notifica critica."""
        return await self.notify(
            title, message,
            priority=NotificationPriority.CRITICAL,
            recipients=recipients
        )
    
    def get_history(self, limit: int = 100) -> List[Notification]:
        """Ritorna storico notifiche."""
        return self.history[-limit:]
    
    def get_stats(self) -> Dict:
        """Statistiche notifiche."""
        total = len(self.history)
        by_priority = {}
        for n in self.history:
            p = n.priority.value
            by_priority[p] = by_priority.get(p, 0) + 1
        
        return {
            'total_sent': total,
            'by_priority': by_priority,
            'available_channels': [c.value for c in self.notifiers.keys()]
        }

# Singleton
notification_service: Optional[NotificationService] = None

def get_notification_service() -> NotificationService:
    global notification_service
    if notification_service is None:
        notification_service = NotificationService()
    return notification_service

def main():
    print('Notification Service Demo')
    print('=' * 50)
    
    service = NotificationService()
    
    print('\\nAvailable channels:')
    for channel in service.notifiers.keys():
        print(f'  - {channel.value}')
    
    print('\\nStats:', service.get_stats())
    
    print('\\nTo send notification:')
    print('  service.notify("Title", "Message", priority=NotificationPriority.HIGH)')

if __name__ == '__main__':
    main()
