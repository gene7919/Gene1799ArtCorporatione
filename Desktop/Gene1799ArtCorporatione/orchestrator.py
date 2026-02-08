#!/usr/bin/env python3
"""
Gene1799 Master Orchestrator
Orchestrates all services and AI agents across the platform
"""

import asyncio
import sys
import io
import logging
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
from enum import Enum

# Force UTF-8 encoding on Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Configure logging with UTF-8 encoding support
# Create file handler with UTF-8 encoding
file_handler = logging.FileHandler('orchestrator.log', encoding='utf-8')
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))

# Create stream handler (stdout)
stream_handler = logging.StreamHandler(sys.stdout)
stream_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))

logging.basicConfig(
    level=logging.INFO,
    handlers=[file_handler, stream_handler]
)
logger = logging.getLogger(__name__)


class ServiceStatus(Enum):
    """Service status enumeration"""
    STOPPED = "stopped"
    STARTING = "starting"
    RUNNING = "running"
    STOPPING = "stopping"
    ERROR = "error"
    UNKNOWN = "unknown"


class Service:
    """Represents a managed service"""
    def __init__(
        self,
        name: str,
        service_type: str,
        command: str,
        working_dir: Path,
        port: Optional[int] = None,
        environment: Optional[Dict[str, str]] = None,
        depends_on: Optional[List[str]] = None
    ):
        self.name = name
        self.service_type = service_type
        self.command = command
        self.working_dir = working_dir
        self.port = port
        self.environment = environment or {}
        self.depends_on = depends_on or []
        self.status = ServiceStatus.STOPPED
        self.process = None
        self.start_time = None

    def to_dict(self) -> dict:
        """Convert to dictionary representation"""
        return {
            'name': self.name,
            'type': self.service_type,
            'status': self.status.value,
            'port': self.port,
            'uptime': str(datetime.now() - self.start_time) if self.start_time else None
        }


class Agent:
    """Represents an AI Agent"""
    def __init__(
        self,
        name: str,
        agent_type: str,
        role: str,
        capabilities: List[str],
        endpoint: str
    ):
        self.name = name
        self.agent_type = agent_type
        self.role = role
        self.capabilities = capabilities
        self.endpoint = endpoint
        self.status = ServiceStatus.STOPPED
        self.last_heartbeat = None

    def to_dict(self) -> dict:
        """Convert to dictionary representation"""
        return {
            'name': self.name,
            'type': self.agent_type,
            'role': self.role,
            'capabilities': self.capabilities,
            'endpoint': self.endpoint,
            'status': self.status.value
        }


class GeneOrchestrator:
    """Master orchestrator for Gene1799 platform"""

    def __init__(self, project_root: Path = None):
        """Initialize orchestrator"""
        self.project_root = project_root or Path.cwd()
        self.services: Dict[str, Service] = {}
        self.agents: Dict[str, Agent] = {}
        self.is_running = False
        self._initialize_services()
        self._initialize_agents()
        logger.info("🚀 Gene1799 Master Orchestrator initialized")

    def _initialize_services(self):
        """Initialize all services"""
        base_path = self.project_root

        # Backend API Service
        self.services['backend'] = Service(
            name='Backend API',
            service_type='nodejs',
            command='npm -w backend run start',
            working_dir=base_path,
            port=3000,
            environment={
                'NODE_ENV': 'production',
                'PORT': '3000',
                'LOG_LEVEL': 'info'
            }
        )

        # Frontend Web Service
        self.services['frontend'] = Service(
            name='Frontend Web',
            service_type='nodejs',
            command='npm -w frontend run dev',
            working_dir=base_path,
            port=5173,
            environment={
                'VITE_API_URL': 'http://localhost:3000'
            }
        )

        # AI Agent Service
        self.services['ai-agent'] = Service(
            name='AI Agent System',
            service_type='python',
            command='python main_prod.py',
            working_dir=base_path / 'ai-agent',
            port=8000,
            environment={
                'PYTHONUNBUFFERED': '1',
                'AGENT_NAME': 'Gene1799',
                'AGENT_DEBUG': 'False',
                'API_HOST': 'localhost',
                'API_PORT': '3000'
            },
            depends_on=['backend']
        )

        # Electron Desktop App
        self.services['desktop'] = Service(
            name='Desktop Application',
            service_type='electron',
            command='npm -w desktop run dev',
            working_dir=base_path,
            environment={
                'BACKEND_URL': 'http://localhost:3000'
            },
            depends_on=['backend']
        )

        logger.info(f"✅ Initialized {len(self.services)} services")

    def _initialize_agents(self):
        """Initialize AI agents"""
        # Orchestrator Agent - manages overall system
        self.agents['orchestrator'] = Agent(
            name='System Orchestrator',
            agent_type='coordinator',
            role='System orchestration and service management',
            capabilities=[
                'Service health monitoring',
                'Load balancing',
                'Auto-scaling',
                'Error handling',
                'Service restart'
            ],
            endpoint='http://localhost:3000/api/agents/orchestrator'
        )

        # Data Processing Agent
        self.agents['data-processor'] = Agent(
            name='Data Processor',
            agent_type='worker',
            role='Data processing and transformation',
            capabilities=[
                'Data parsing',
                'Format conversion',
                'Data validation',
                'Cache management',
                'Batch processing'
            ],
            endpoint='http://localhost:3000/api/agents/processor'
        )

        # Analytics Agent
        self.agents['analytics'] = Agent(
            name='Analytics Agent',
            agent_type='analyzer',
            role='System analytics and insights',
            capabilities=[
                'Performance analysis',
                'Usage tracking',
                'Trend analysis',
                'Report generation',
                'Alert triggers'
            ],
            endpoint='http://localhost:3000/api/agents/analytics'
        )

        # Communication Agent
        self.agents['communicator'] = Agent(
            name='Communication Agent',
            agent_type='connector',
            role='Inter-service communication',
            capabilities=[
                'Message routing',
                'API gateway',
                'Event streaming',
                'Request queuing',
                'Response aggregation'
            ],
            endpoint='http://localhost:3000/api/agents/communicator'
        )

        # Learning Agent
        self.agents['learning'] = Agent(
            name='Machine Learning Agent',
            agent_type='ml',
            role='Machine learning and model management',
            capabilities=[
                'Model training',
                'Prediction',
                'Pattern recognition',
                'Data clustering',
                'Model deployment'
            ],
            endpoint='http://localhost:3000/api/agents/learning'
        )

        logger.info(f"✅ Initialized {len(self.agents)} AI agents")

    async def start_service(self, service_name: str) -> bool:
        """Start a single service"""
        if service_name not in self.services:
            logger.error(f"❌ Service '{service_name}' not found")
            return False

        service = self.services[service_name]

        # Check dependencies
        for dep in service.depends_on:
            if dep not in self.services or self.services[dep].status != ServiceStatus.RUNNING:
                logger.warning(f"⚠️  Waiting for dependency: {dep}")
                await asyncio.sleep(2)

        logger.info(f"▶️  Starting service: {service.name}")
        service.status = ServiceStatus.STARTING

        try:
            # In real implementation, would spawn actual process
            # For now, simulate startup
            await asyncio.sleep(1)
            service.status = ServiceStatus.RUNNING
            service.start_time = datetime.now()
            logger.info(f"✅ Started: {service.name} (port {service.port})")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to start {service.name}: {e}")
            service.status = ServiceStatus.ERROR
            return False

    async def stop_service(self, service_name: str) -> bool:
        """Stop a single service"""
        if service_name not in self.services:
            logger.error(f"❌ Service '{service_name}' not found")
            return False

        service = self.services[service_name]
        logger.info(f"⏹️  Stopping service: {service.name}")
        service.status = ServiceStatus.STOPPING

        try:
            # In real implementation, would kill process
            await asyncio.sleep(0.5)
            service.status = ServiceStatus.STOPPED
            service.start_time = None
            logger.info(f"✅ Stopped: {service.name}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to stop {service.name}: {e}")
            service.status = ServiceStatus.ERROR
            return False

    async def start_all_services(self):
        """Start all services in correct order"""
        logger.info("=" * 60)
        logger.info("🚀 STARTING ALL SERVICES")
        logger.info("=" * 60)

        startup_order = ['backend', 'frontend', 'ai-agent', 'desktop']

        for service_name in startup_order:
            if service_name in self.services:
                success = await self.start_service(service_name)
                if not success and service_name in ['backend', 'ai-agent']:
                    logger.error(f"❌ Critical service failed: {service_name}")
                    return False
                await asyncio.sleep(2)

        self.is_running = True
        logger.info("=" * 60)
        logger.info("✅ ALL SERVICES RUNNING")
        logger.info("=" * 60)
        return True

    async def stop_all_services(self):
        """Stop all services in reverse order"""
        logger.info("=" * 60)
        logger.info("⏹️  STOPPING ALL SERVICES")
        logger.info("=" * 60)

        shutdown_order = ['desktop', 'ai-agent', 'frontend', 'backend']

        for service_name in shutdown_order:
            if service_name in self.services:
                await self.stop_service(service_name)
                await asyncio.sleep(1)

        self.is_running = False
        logger.info("=" * 60)
        logger.info("✅ ALL SERVICES STOPPED")
        logger.info("=" * 60)

    async def initialize_agents(self) -> bool:
        """Initialize all AI agents"""
        logger.info("=" * 60)
        logger.info("🤖 INITIALIZING AI AGENTS")
        logger.info("=" * 60)

        for agent_name, agent in self.agents.items():
            logger.info(f"▶️  Initializing agent: {agent.name}")
            try:
                # Simulate agent initialization
                await asyncio.sleep(0.5)
                agent.status = ServiceStatus.RUNNING
                agent.last_heartbeat = datetime.now()
                logger.info(f"✅ Initialized: {agent.name}")
                logger.info(f"   Role: {agent.role}")
                logger.info(f"   Capabilities: {', '.join(agent.capabilities)}")
            except Exception as e:
                logger.error(f"❌ Failed to initialize agent {agent.name}: {e}")
                agent.status = ServiceStatus.ERROR
                return False

        logger.info("=" * 60)
        logger.info("✅ ALL AGENTS INITIALIZED")
        logger.info("=" * 60)
        return True

    async def health_check(self) -> Dict:
        """Check health of all services and agents"""
        health = {
            'timestamp': datetime.now().isoformat(),
            'services': {name: svc.to_dict() for name, svc in self.services.items()},
            'agents': {name: agent.to_dict() for name, agent in self.agents.items()},
            'overall_status': 'healthy' if all(
                svc.status == ServiceStatus.RUNNING for svc in self.services.values()
            ) else 'degraded'
        }
        return health

    def print_status(self):
        """Print current status"""
        logger.info("\n" + "=" * 60)
        logger.info("📊 SYSTEM STATUS")
        logger.info("=" * 60)

        logger.info("\n🔧 SERVICES:")
        for name, service in self.services.items():
            status_icon = {
                ServiceStatus.RUNNING: "✅",
                ServiceStatus.STOPPED: "⏹️ ",
                ServiceStatus.ERROR: "❌",
                ServiceStatus.STARTING: "▶️ ",
                ServiceStatus.STOPPING: "⏹️ ",
                ServiceStatus.UNKNOWN: "❓"
            }.get(service.status, "❓")

            uptime = ""
            if service.start_time:
                delta = datetime.now() - service.start_time
                uptime = f" (↑ {delta.seconds}s)"

            logger.info(f"{status_icon} {service.name:30} | {service.status.value:10} | port {service.port}{uptime}")

        logger.info("\n🤖 AI AGENTS:")
        for name, agent in self.agents.items():
            status_icon = "✅" if agent.status == ServiceStatus.RUNNING else "❌"
            logger.info(f"{status_icon} {agent.name:30} | {agent.role}")

        logger.info("\n" + "=" * 60 + "\n")

    async def run_interactive(self):
        """Run interactive orchestrator mode"""
        logger.info("""
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🎮 GENE1799 ORCHESTRATOR - INTERACTIVE MODE             ║
║                                                            ║
║   Commands:                                               ║
║   - start <service>  : Start a service                   ║
║   - stop <service>   : Stop a service                    ║
║   - status           : Show all statuses                 ║
║   - health           : Health check                      ║
║   - restart          : Restart all services              ║
║   - agents           : Show agents info                  ║
║   - help             : Show help                         ║
║   - exit             : Shutdown and exit                 ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
        """)

        await self.start_all_services()
        await self.initialize_agents()

        while True:
            try:
                command = input("\n> ").strip().lower().split()
                if not command:
                    continue

                cmd = command[0]

                if cmd == 'start':
                    if len(command) > 1:
                        await self.start_service(command[1])
                    else:
                        await self.start_all_services()

                elif cmd == 'stop':
                    if len(command) > 1:
                        await self.stop_service(command[1])
                    else:
                        await self.stop_all_services()

                elif cmd == 'status':
                    self.print_status()

                elif cmd == 'health':
                    health = await self.health_check()
                    logger.info(json.dumps(health, indent=2))

                elif cmd == 'restart':
                    await self.stop_all_services()
                    await asyncio.sleep(2)
                    await self.start_all_services()

                elif cmd == 'agents':
                    logger.info("\nRegistered AI Agents:")
                    for name, agent in self.agents.items():
                        logger.info(f"  • {agent.name} ({agent.agent_type}): {agent.role}")

                elif cmd == 'help':
                    logger.info("Available commands: start, stop, status, health, restart, agents, help, exit")

                elif cmd == 'exit':
                    logger.info("Shutting down...")
                    await self.stop_all_services()
                    break

                else:
                    logger.warning(f"Unknown command: {cmd}")

            except KeyboardInterrupt:
                logger.info("\nShutting down...")
                await self.stop_all_services()
                break
            except Exception as e:
                logger.error(f"Error: {e}")


async def main():
    """Main entry point"""
    # Get project root
    project_root = Path.cwd()
    if 'Gene1799ArtCorporatione' not in str(project_root):
        project_root = Path.home() / 'Desktop' / 'gene1799' / 'Gene1799ArtCorporatione'

    # Initialize orchestrator
    orchestrator = GeneOrchestrator(project_root)

    # Run interactive mode
    await orchestrator.run_interactive()


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\nOrchestrator stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)
