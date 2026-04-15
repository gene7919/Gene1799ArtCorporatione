#!/usr/bin/env python3
"""
SuiteV17 Notification System
Discord, Telegram, Email, SMS, Webhook support
"""
import os
import json
import smtplib
import requests
from datetime import datetime
from typing import Dict, List, Optional, Any
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dataclasses import dataclass
from enum import Enum

class NotificationChannel(Enum):
    DISCORD = 'discord'
    TELEGRAM = 'telegram'
    EMAIL = 'email'
    SMS = 'sms'
    WEBHOOK = 'webhook'
    DESKTOP = 'desktop'

class Priority(Enum):
    LOW = 'low'
    NORMAL = 'normal'
    HIGH = 'high'
    CRITICAL = 'critical'

@dataclass
class Notification:
    title: str
    message: str
    channel: NotificationChannel
    priority: Priority
    timestamp: str
    metadata: Dict[str, Any]

class NotificationManager:
    """Gestore notifiche multi-canale."""
    
    def __init__(self):
        self.config = self._load_config()
        self.history: List[Notification] = []
        
    def _load_config(self) -> Dict:
        """Carica configurazione notifiche."""
        return {
            'discord': {
                'enabled': os.getenv('DISCORD_ENABLED', 'false').lower() == 'true',
                'webhook_url': os.getenv('DISCORD_WEBHOOK_URL', ''),
                'username': 'SuiteV17 Bot',
                'avatar_url': ''
            },
            'telegram': {
                'enabled': os.getenv('TELEGRAM_ENABLED', 'false').lower() == 'true',
                'bot_token': os.getenv('TELEGRAM_BOT_TOKEN', ''),
                'chat_id': os.getenv('TELEGRAM_CHAT_ID', '')
            },
            'email': {
                'enabled': os.getenv('EMAIL_ENABLED', 'false').lower() == 'true',
                'smtp_host': os.getenv('SMTP_HOST', 'smtp.gmail.com'),
                'smtp_port': int(os.getenv('SMTP_PORT', '587')),
                'username': os.getenv('EMAIL_USERNAME', ''),
                'password': os.getenv('EMAIL_PASSWORD', ''),
                'from_addr': os.getenv('EMAIL_FROM', ''),
                'to_addrs': os.getenv('EMAIL_TO', '').split(',')
            },
            'webhook': {
                'enabled': os.getenv('WEBHOOK_ENABLED', 'false').lower() == 'true',
                'url': os.getenv('WEBHOOK_URL', ''),
                'headers': json.loads(os.getenv('WEBHOOK_HEADERS', '{}'))
            }
        }
        
    def send(self, title: str, message: str, 
             channel: NotificationChannel = NotificationChannel.DISCORD,
             priority: Priority = Priority.NORMAL,
             metadata: Dict = None) -> bool:
        """Invia notifica."""
        notification = Notification(
            title=title,
            message=message,
            channel=channel,
            priority=priority,
            timestamp=datetime.now().isoformat(),
            metadata=metadata or {}
        )
        
        self.history.append(notification)
        
        try:
            if channel == NotificationChannel.DISCORD:
                return self._send_discord(notification)
            elif channel == NotificationChannel.TELEGRAM:
                return self._send_telegram(notification)
            elif channel == NotificationChannel.EMAIL:
                return self._send_email(notification)
            elif channel == NotificationChannel.WEBHOOK:
                return self._send_webhook(notification)
            elif channel == NotificationChannel.DESKTOP:
                return self._send_desktop(notification)
            else:
                print(f'Unknown channel: {channel}')
                return False
        except Exception as e:
            print(f'Error sending notification: {e}')
            return False
            
    def _send_discord(self, notification: Notification) -> bool:
        """Invia notifica Discord."""
        config = self.config['discord']
        if not config['enabled'] or not config['webhook_url']:
            return False
            
        # Color based on priority
        colors = {
            Priority.LOW: 0x95a5a6,
            Priority.NORMAL: 0x3498db,
            Priority.HIGH: 0xf39c12,
            Priority.CRITICAL: 0xe74c3c
        }
        
        embed = {
            'title': notification.title,
            'description': notification.message,
            'color': colors.get(notification.priority, 0x3498db),
            'timestamp': notification.timestamp,
            'footer': {
                'text': f'SuiteV17 | Priority: {notification.priority.value}'
            },
            'fields': []
        }
        
        if notification.metadata:
            for key, value in notification.metadata.items():
                embed['fields'].append({
                    'name': key,
                    'value': str(value)[:1000],
                    'inline': True
                })
                
        payload = {
            'username': config['username'],
            'embeds': [embed]
        }
        
        response = requests.post(
            config['webhook_url'],
            json=payload,
            timeout=10
        )
        return response.status_code == 204
        
    def _send_telegram(self, notification: Notification) -> bool:
        """Invia notifica Telegram."""
        config = self.config['telegram']
        if not config['enabled'] or not config['bot_token']:
            return False
            
        # Icone per priorità
        icons = {
            Priority.LOW: 'ℹ️',
            Priority.NORMAL: '✅',
            Priority.HIGH: '⚠️',
            Priority.CRITICAL: '🚨'
        }
        
        text = f"{icons.get(notification.priority, '✅')} *{notification.title}*\n\n"
        text += notification.message
        
        if notification.metadata:
            text += '\n\n*Dettagli:*'
            for key, value in notification.metadata.items():
                text += f'\n• {key}: `{value}`'
                
        url = f"https://api.telegram.org/bot{config['bot_token']}/sendMessage"
        payload = {
            'chat_id': config['chat_id'],
            'text': text,
            'parse_mode': 'Markdown',
            'disable_web_page_preview': True
        }
        
        response = requests.post(url, json=payload, timeout=10)
        return response.status_code == 200
        
    def _send_email(self, notification: Notification) -> bool:
        """Invia email."""
        config = self.config['email']
        if not config['enabled']:
            return False
            
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"[SuiteV17] {notification.title}"
        msg['From'] = config['from_addr']
        msg['To'] = ', '.join(config['to_addrs'])
        
        # HTML version
        priority_colors = {
            Priority.LOW: '#95a5a6',
            Priority.NORMAL: '#3498db',
            Priority.HIGH: '#f39c12',
            Priority.CRITICAL: '#e74c3c'
        }
        
        html = f"""
        <html>
        <body style="font-family: Arial, sans-serif;">
            <div style="background-color: {priority_colors.get(notification.priority, '#3498db')}; 
                        color: white; padding: 20px; border-radius: 5px;">
                <h2>{notification.title}</h2>
                <p>Priority: {notification.priority.value.upper()}</p>
            </div>
            <div style="padding: 20px;">
                <p>{notification.message}</p>
                <hr/>
                <p><strong>Timestamp:</strong> {notification.timestamp}</p>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html, 'html'))
        
        with smtplib.SMTP(config['smtp_host'], config['smtp_port']) as server:
            server.starttls()
            server.login(config['username'], config['password'])
            server.send_message(msg)
            
        return True
        
    def _send_webhook(self, notification: Notification) -> bool:
        """Invia a webhook generico."""
        config = self.config['webhook']
        if not config['enabled'] or not config['url']:
            return False
            
        payload = {
            'title': notification.title,
            'message': notification.message,
            'priority': notification.priority.value,
            'timestamp': notification.timestamp,
            'source': 'SuiteV17',
            'metadata': notification.metadata
        }
        
        response = requests.post(
            config['url'],
            json=payload,
            headers=config['headers'],
            timeout=10
        )
        return response.status_code in [200, 201, 204]
        
    def _send_desktop(self, notification: Notification) -> bool:
        """Notifica desktop nativa."""
        try:
            # Windows
            import ctypes
            ctypes.windll.user32.MessageBoxW(
                0, 
                notification.message, 
                notification.title, 
                0x40  # Info icon
            )
            return True
        except:
            pass
            
        try:
            # Linux (notify-send)
            import subprocess
            subprocess.run([
                'notify-send',
                '-u', notification.priority.value,
                notification.title,
                notification.message
            ])
            return True
        except:
            pass
            
        return False
        
    def broadcast(self, title: str, message: str, 
                   priority: Priority = Priority.NORMAL,
                   metadata: Dict = None) -> Dict[str, bool]:
        """Invia a tutti i canali abilitati."""
        results = {}
        for channel in NotificationChannel:
            results[channel.value] = self.send(
                title, message, channel, priority, metadata
            )
        return results
        
    def send_alert(self, title: str, message: str, 
                   priority: Priority = Priority.HIGH):
        """Invia alert a tutti i canali critici."""
        return self.broadcast(title, message, priority)
        
    def get_history(self, limit: int = 100) -> List[Notification]:
        """Recupera storico notifiche."""
        return self.history[-limit:]
        
    def notify_trade(self, action: str, token: str, amount: float, 
                     price: float, profit: float = None):
        """Notifica trade specifico."""
        title = f"Trade Executed: {action.upper()}"
        message = f"Token: {token}\nAmount: {amount}\nPrice: ${price}"
        
        if profit is not None:
            message += f"\nP&L: ${profit:+.2f}"
            
        priority = Priority.HIGH if profit and profit < 0 else Priority.NORMAL
        
        self.send(title, message, NotificationChannel.DISCORD, priority)
        
    def notify_error(self, error_message: str, source: str = 'system'):
        """Notifica errore."""
        self.send(
            f'Error in {source}',
            error_message,
            NotificationChannel.DISCORD,
            Priority.CRITICAL,
            {'source': source, 'type': 'error'}
        )
        
    def notify_system_status(self, status: str, details: Dict = None):
        """Notifica stato sistema."""
        priority = Priority.NORMAL if status == 'healthy' else Priority.HIGH
        self.send(
            'System Status Update',
            f'Status: {status}',
            NotificationChannel.TELEGRAM,
            priority,
            details
        )

def main():
    """Test notifications."""
    notifier = NotificationManager()
    
    # Test Discord
    print('Sending test notification...')
    success = notifier.send(
        'Test Notification',
        'This is a test message from SuiteV17',
        NotificationChannel.DISCORD,
        Priority.NORMAL,
        {'test': True, 'version': '1.0.0'}
    )
    print(f'Sent: {success}')

if __name__ == '__main__':
    main()
