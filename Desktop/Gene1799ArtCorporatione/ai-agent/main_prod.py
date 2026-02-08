#!/usr/bin/env python3
"""
Gene1799 AI Agent - Production Startup
"""

import os
import sys
import asyncio
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.getLogger().setLevel(
        logging.INFO if not os.getenv('AGENT_DEBUG') else logging.DEBUG
    ),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from agent import GeneAgent

async def main():
    """Initialize and start AI Agent"""
    
    agent_name = os.getenv('AGENT_NAME', 'Gene1799')
    api_host = os.getenv('API_HOST', 'localhost')
    api_port = os.getenv('API_PORT', '3000')
    debug = os.getenv('AGENT_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"""
╔════════════════════════════════════════╗
║  🤖 Gene1799 AI Agent                  ║
║  Name: {agent_name.ljust(28)}║
║  Backend: {api_host}:{api_port}
║  Debug: {str(debug).ljust(29)}║
║  Python: {sys.version.split()[0].ljust(26)}║
╚════════════════════════════════════════╝
    """)
    
    agent = GeneAgent(
        name=agent_name,
        description="Sistema AI integrato per Gene1799 Art Corporation"
    )
    
    try:
        await agent.initialize()
        logger.info("✅ AI Agent initialized successfully")
        
        # Keep agent running
        while True:
            await asyncio.sleep(60)
            
    except KeyboardInterrupt:
        logger.info("⏹️  Shutting down AI Agent...")
    except Exception as e:
        logger.error(f"❌ Agent Error: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
