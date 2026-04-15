# 🚀 CrewAI FREE → Groq + Perplexity!
@'
#!/usr/bin/env python3
"""
McLaren CrewAI Supreme v9.3 FREE
Groq + Perplexity + Ollama → 0 costi!
"""

from fastapi import FastAPI, Request
from pydantic import BaseModel
from crewai import Agent, Task, Crew
from crewai_tools import SerperDevTool
from langchain_groq import ChatGroq
from langchain_perplexity import ChatPerplexity
from datetime import datetime
import os, uvicorn

app = FastAPI(title="SuiteV17 CrewAI FREE")

# 🆓 FREE LLM Config
groq_llm = ChatGroq(
    model="llama3-groq-70b-8192-tool-use-preview",
    api_key=os.getenv("GROQ_API_KEY", "gsk_dummy_free"),
    temperature=0.3
)

pplx_llm = ChatPerplexity(
    model="llama-3.1-sonar-huge-128k-online",
    api_key=os.getenv("PERPLEXITY_API_KEY", "pplx_dummy"),
    temperature=0.3
)

# 🧑‍🔬 FREE AGENTS McLaren
pharma_agent = Agent(
    role="Pharma AI Researcher",
    goal="Analizza brevetti + drug discovery 2026",
    backstory="Esperto AlphaFold3 + brevetti Cina/US",
    llm=groq_llm,  # Groq 70B ultra-fast!
    verbose=True,
    tools=[SerperDevTool()]
)

nft_agent = Agent(
    role="Zora NFT Strategist", 
    goal="Trend Zora + pharma NFT valuation",
    backstory="Blockchain analyst realtime Dune/Zora",
    llm=pplx_llm,  # Perplexity web search!
    verbose=True
)

suite_ceo = Agent(
    role="SuiteV17 CEO", 
    goal="Piano strategico Gene1799 NFT+Pharma",
    backstory="Founder SuiteV17/Gene1799",
    llm=groq_llm,
    verbose=True
)

class CrewQuery(BaseModel):
    query: str = "NFT pharma Zora 2026"

@app.get("/")
async def status():
    return {"crewai_free": True, "llms": ["Groq-70B", "Perplexity-Sonar"], "power": "28.5 THz"}

@app.post("/crewai-free")
async def supreme_crew(q: CrewQuery):
    """CrewAI FREE multi-agent execution"""
    
    # Tasks
    pharma_task = Task(
        description=f"Ricerca: {q.query}",
        agent=pharma_agent
    )
    
    nft_task = Task(
        description=f"NFT analysis: {q.query}",
        agent=nft_agent
    )
    
    ceo_task = Task(
        description="Strategia Gene1799 da dati",
        agent=suite_ceo
    )
    
    # SUPREME CREW
    crew = Crew(
        agents=[pharma_agent, nft_agent, suite_ceo],
        tasks=[pharma_task, nft_task, ceo_task],
        verbose=True
    )
    
    result = crew.kickoff()
    
    return {
        "success": True,
        "query": q.query,
        "result": str(result),
        "llms_used": ["Groq", "Perplexity"],
        "cost": "0€"  # FREE!
    }

if __name__ == "__main__":
    print("🆓 McLaren CrewAI FREE → Groq + Perplexity!")
    uvicorn.run(app, host="127.0.0.1", port=8018)
'@ | Set-Content -Path "ai_supreme_crewai_free.py" -Encoding UTF8

# AVVIA FREE CREWAI
uvicorn ai_supreme_crewai_free:app --port 8018 --reload
