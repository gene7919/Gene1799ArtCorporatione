#!/usr/bin/env python3
"""
Gene1799 Orchestrator Monitor
Real-time monitoring dashboard for all services and agents
"""

import asyncio
import json
import sys
from datetime import datetime
from dataclasses import dataclass
from typing import Dict, List
import subprocess
import os

@dataclass
class ServiceStatus:
    name: str
    status: str
    uptime: float
    cpu: float
    memory: str
    port: int
    
class OrchestratorMonitor:
    def __init__(self):
        self.services = {
            'backend': {'port': 3000, 'name': 'Express.js API'},
            'frontend': {'port': 3001, 'name': 'React UI'},
            'ai-agent': {'port': 5000, 'name': 'Python Agent'},
            'desktop': {'port': None, 'name': 'Electron App'}
        }
        self.agents = [
            {'name': 'orchestrator', 'role': 'Coordinator', 'status': 'inactive'},
            {'name': 'data-processor', 'role': 'Worker', 'status': 'inactive'},
            {'name': 'analytics', 'role': 'Analyzer', 'status': 'inactive'},
            {'name': 'communicator', 'role': 'Connector', 'status': 'inactive'},
            {'name': 'learning', 'role': 'ML', 'status': 'inactive'}
        ]
    
    def clear_screen(self):
        """Clear terminal screen"""
        os.system('cls' if sys.platform == 'win32' else 'clear')
    
    def print_header(self):
        """Print dashboard header"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print("\n" + "="*70)
        print("🎼 GENE1799 ORCHESTRATOR MONITOR")
        print("="*70)
        print(f"⏰ {timestamp}")
        print("="*70 + "\n")
    
    def check_port_open(self, port: int) -> bool:
        """Check if port is open"""
        if port is None:
            return False
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            result = sock.connect_ex(('127.0.0.1', port))
            sock.close()
            return result == 0
        except:
            return False
    
    def print_services_status(self):
        """Print services status"""
        print("📦 SERVICES STATUS")
        print("-" * 70)
        print(f"{'Service':<20} {'Status':<15} {'Endpoint':<25} {'Port':<10}")
        print("-" * 70)
        
        for service, info in self.services.items():
            is_running = self.check_port_open(info['port'])
            status = "🟢 RUNNING" if is_running else "🔴 STOPPED"
            endpoint = f"localhost:{info['port']}" if info['port'] else "N/A"
            port_str = str(info['port']) if info['port'] else "N/A"
            
            print(f"{service:<20} {status:<15} {endpoint:<25} {port_str:<10}")
        
        print()
    
    def print_agents_status(self):
        """Print agents status"""
        print("🤖 AI AGENTS STATUS")
        print("-" * 70)
        print(f"{'Agent':<20} {'Role':<20} {'Status':<15}")
        print("-" * 70)
        
        for agent in self.agents:
            status = f"🟡 {agent['status'].upper()}"
            print(f"{agent['name']:<20} {agent['role']:<20} {status:<15}")
        
        print()
    
    def print_commands(self):
        """Print available commands"""
        print("⌨️  COMMANDS")
        print("-" * 70)
        print("Commands to manage orchestrator:")
        print("  start   - Start all services and agents")
        print("  stop    - Stop all services and agents")
        print("  status  - Check system status")
        print("  restart - Restart all services")
        print("  refresh - Refresh monitor display")
        print("  help    - Show this help message")
        print("  exit    - Exit monitor")
        print("-" * 70 + "\n")
    
    def print_system_info(self):
        """Print system information"""
        print("ℹ️  SYSTEM INFORMATION")
        print("-" * 70)
        
        try:
            import platform
            import psutil
            
            print(f"OS: {platform.system()} {platform.release()}")
            print(f"Python: {platform.python_version()}")
            
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            
            print(f"CPU Usage: {cpu_percent}%")
            print(f"Memory Usage: {memory.percent}% ({memory.used / (1024**3):.2f} GB / {memory.total / (1024**3):.2f} GB)")
            
        except ImportError:
            print("(psutil not available for detailed metrics)")
        
        print()
    
    async def run_monitor(self):
        """Run the monitor loop"""
        self.clear_screen()
        
        try:
            while True:
                self.clear_screen()
                self.print_header()
                self.print_services_status()
                self.print_agents_status()
                self.print_system_info()
                self.print_commands()
                
                # Get user input (non-blocking)
                try:
                    command = input("Enter command (or press Enter to refresh): ").strip().lower()
                    
                    if command == 'exit':
                        print("\n👋 Exiting monitor...")
                        break
                    elif command == 'help':
                        self.print_commands()
                        input("Press Enter to continue...")
                    elif command == 'refresh':
                        continue
                    elif command in ['start', 'stop', 'status', 'restart']:
                        print(f"\n⚠️  Command '{command}' requires orchestrator.py to be running")
                        print("   Run 'python orchestrator.py' first")
                        input("Press Enter to continue...")
                    elif command == '':
                        await asyncio.sleep(2)  # Auto-refresh every 2 seconds
                    else:
                        print(f"\n❌ Unknown command: {command}")
                        input("Press Enter to continue...")
                
                except KeyboardInterrupt:
                    print("\n\n👋 Monitor interrupted...")
                    break
                except EOFError:
                    await asyncio.sleep(2)  # Auto-refresh if no input
        
        except KeyboardInterrupt:
            print("\n\n👋 Monitor stopped...")
        
        finally:
            print("\n✅ Monitor closed\n")

async def main():
    """Main entry point"""
    monitor = OrchestratorMonitor()
    await monitor.run_monitor()

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n👋 Monitor stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
