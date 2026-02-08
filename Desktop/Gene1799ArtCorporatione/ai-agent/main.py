"""
Gene1799 AI Agent - Main Module
Integrazione con Microsoft Agent Framework
"""

import asyncio
from agent import GeneAgent

async def main():
    """Avvia il sistema AI Agent"""
    print("🤖 Inizializzazione Gene1799 AI Agent...")
    
    agent = GeneAgent(
        name="Gene1799",
        description="Sistema AI integrato"
    )
    
    await agent.initialize()
    print("✅ AI Agent pronto!")
    
    # Esempio di utilizzo
    response = await agent.process("Ciao, come stai?")
    print(f"Agent Response: {response}")

if __name__ == "__main__":
    asyncio.run(main())
