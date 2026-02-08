#!/usr/bin/env python3

"""
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║     🏥 GENE1799 - AZURE AI AGENTS INTEGRATION 🏥                        ║
║                                                                           ║
║  Connect GENE1799 Local System to Azure AI Agents                        ║
║  Multi-Agent Orchestration across Local + Cloud                          ║
║                                                                           ║
║  Endpoint: https://gene1799artcorporatione-resource.services.ai.azure.com║
║  Project: gene1799artcorporatione-3261                                   ║
║  Subscription: f5117908-9b03-4041-a740-87bd287f8c55                     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
"""

import asyncio
import json
import os
import sys
from typing import Optional, Dict, Any, List
from datetime import datetime

# Azure AI Projects SDK
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

# FastAPI for local API
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

AZURE_CONFIG = {
    "endpoint": "https://gene1799artcorporatione-resource.services.ai.azure.com/api/projects/gene1799artcorporatione-3261",
    "project_id": "gene1799artcorporatione-3261",
    "subscription_id": "f5117908-9b03-4041-a740-87bd287f8c55",
    "resource_group": "rg-gene1799artcorporatione-3269",
    "tenant_id": "cfc35dee-c900-4747-b9a1-0c2d6dcd9eda",
}

# Available Azure AI Agents
AZURE_AGENTS = {
    "alMedicochelante": {
        "name": "alMedicochelante",
        "type": "medical",
        "description": "Specializzato in analisi medica e diagnostica",
        "capabilities": [
            "Medical analysis",
            "Tumor classification",
            "Drug targeting",
            "Clinical trial recommendations",
            "Healthcare integration"
        ],
        "language": "Italian/English",
        "version": "1.0"
    },
    # More agents can be added here
}

# ═══════════════════════════════════════════════════════════════════════════
# AZURE AI CLIENT
# ═══════════════════════════════════════════════════════════════════════════

class AzureAIClient:
    """Client for interacting with Azure AI Agents"""

    def __init__(self):
        """Initialize Azure AI Projects client"""
        try:
            self.credential = DefaultAzureCredential()
            self.client = AIProjectClient(
                endpoint=AZURE_CONFIG["endpoint"],
                credential=self.credential,
            )
            self.openai_client = self.client.get_openai_client()
            self.is_connected = True
            print("[OK] Connected to Azure AI Projects")
        except Exception as e:
            print(f"[ERROR] Azure AI connection failed: {e}")
            self.is_connected = False

    async def query_agent(self, agent_name: str, message: str) -> Dict[str, Any]:
        """Query an Azure AI agent with a message"""
        if not self.is_connected:
            return {"error": "Not connected to Azure AI"}

        if agent_name not in AZURE_AGENTS:
            return {"error": f"Agent '{agent_name}' not found"}

        try:
            agent = self.client.agents.get(agent_name=agent_name)

            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "user", "content": message}
                ],
                extra_body={
                    "agent": {
                        "name": agent.name,
                        "type": "agent_reference"
                    }
                }
            )

            return {
                "status": "success",
                "agent": agent_name,
                "message": message,
                "response": response.choices[0].message.content,
                "timestamp": datetime.now().isoformat()
            }

        except Exception as e:
            return {
                "status": "error",
                "agent": agent_name,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

    async def list_agents(self) -> List[Dict[str, Any]]:
        """List all available Azure AI agents"""
        return [
            {
                "name": name,
                "type": config["type"],
                "description": config["description"],
                "capabilities": config["capabilities"]
            }
            for name, config in AZURE_AGENTS.items()
        ]

    async def get_agent_info(self, agent_name: str) -> Optional[Dict[str, Any]]:
        """Get info about a specific agent"""
        if agent_name not in AZURE_AGENTS:
            return None

        config = AZURE_AGENTS[agent_name]
        try:
            agent = self.client.agents.get(agent_name=agent_name)
            return {
                **config,
                "azure_id": agent.id if hasattr(agent, 'id') else None,
                "status": "available"
            }
        except Exception as e:
            return {
                **config,
                "status": "error",
                "error": str(e)
            }

# ═══════════════════════════════════════════════════════════════════════════
# FASTAPI APPLICATION
# ═══════════════════════════════════════════════════════════════════════════

app = FastAPI(
    title="GENE1799 Azure AI Integration",
    description="Local API for Azure AI Agents integration with GENE1799",
    version="1.0.0"
)

# Initialize Azure AI Client
azure_client = AzureAIClient()

# ═══════════════════════════════════════════════════════════════════════════
# MODELS
# ═══════════════════════════════════════════════════════════════════════════

class AgentQuery(BaseModel):
    """Request model for agent queries"""
    agent_name: str
    message: str

class AgentResponse(BaseModel):
    """Response model for agent queries"""
    status: str
    agent: str
    message: str
    response: str
    timestamp: str

# ═══════════════════════════════════════════════════════════════════════════
# API ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/health")
async def health_check():
    """Check Azure AI connection status"""
    return {
        "status": "healthy" if azure_client.is_connected else "disconnected",
        "service": "GENE1799 Azure AI Integration",
        "version": "1.0.0",
        "connection": azure_client.is_connected,
        "endpoint": AZURE_CONFIG["endpoint"],
        "timestamp": datetime.now().isoformat()
    }

@app.get("/agents")
async def list_agents():
    """List all available Azure AI agents"""
    agents = await azure_client.list_agents()
    return {
        "status": "success",
        "count": len(agents),
        "agents": agents
    }

@app.get("/agents/{agent_name}")
async def get_agent(agent_name: str):
    """Get information about a specific agent"""
    info = await azure_client.get_agent_info(agent_name)
    if info is None:
        raise HTTPException(status_code=404, detail=f"Agent '{agent_name}' not found")
    return {
        "status": "success",
        "agent": info
    }

@app.post("/query")
async def query_agent(request: AgentQuery):
    """Query an Azure AI agent"""
    result = await azure_client.query_agent(
        agent_name=request.agent_name,
        message=request.message
    )

    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    return result

@app.post("/agents/{agent_name}/query")
async def query_agent_direct(agent_name: str, request: AgentQuery):
    """Query a specific agent directly"""
    result = await azure_client.query_agent(
        agent_name=agent_name,
        message=request.message
    )

    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])

    return result

@app.get("/config")
async def get_config():
    """Get Azure configuration info (non-sensitive)"""
    return {
        "project_id": AZURE_CONFIG["project_id"],
        "endpoint": AZURE_CONFIG["endpoint"],
        "subscription_id": AZURE_CONFIG["subscription_id"],
        "resource_group": AZURE_CONFIG["resource_group"],
        "agents": list(AZURE_AGENTS.keys()),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/status")
async def get_status():
    """Get detailed service status"""
    agents = await azure_client.list_agents()
    return {
        "service": "GENE1799 Azure AI Integration",
        "version": "1.0.0",
        "status": "operational" if azure_client.is_connected else "disconnected",
        "azure_connected": azure_client.is_connected,
        "agents_available": len(agents),
        "agents": agents,
        "configuration": {
            "project": AZURE_CONFIG["project_id"],
            "endpoint": AZURE_CONFIG["endpoint"],
            "subscription": AZURE_CONFIG["subscription_id"]
        },
        "timestamp": datetime.now().isoformat()
    }

# ═══════════════════════════════════════════════════════════════════════════
# STARTUP/SHUTDOWN
# ═══════════════════════════════════════════════════════════════════════════

@app.on_event("startup")
async def startup():
    """Initialize on startup"""
    print("\n" + "="*70)
    print("GENE1799 AZURE AI INTEGRATION SERVICE")
    print("="*70)
    print(f"[OK] Service started")
    print(f"[OK] Endpoint: {AZURE_CONFIG['endpoint']}")
    print(f"[OK] Project: {AZURE_CONFIG['project_id']}")
    if azure_client.is_connected:
        print(f"[OK] Azure AI: Connected")
    else:
        print(f"[WARN] Azure AI: Not connected (check credentials)")
    print("="*70 + "\n")

@app.on_event("shutdown")
async def shutdown():
    """Cleanup on shutdown"""
    print("\nGENE1799 Azure AI service shutting down...\n")

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("""
======================================================================
   GENE1799 AZURE AI AGENTS - LOCAL API SERVER

   Starting on: http://localhost:8001

   Available agents:
     * alMedicochelante - Medical AI specialist

   API Docs: http://localhost:8001/docs
======================================================================
    """)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        reload=False,
        log_level="info"
    )
