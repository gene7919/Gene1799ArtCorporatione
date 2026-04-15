from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn
from typing import Optional
from datetime import datetime

app = FastAPI(title="SuiteV17 Orchestrator", version="2.0.1")

class Task(BaseModel):
    name: str
    payload: Optional[dict] = None

state = {"agents": {}, "history": [], "started_at": datetime.now().isoformat()}

@app.get("/")
def root():
    return {"status": "online", "version": "2.0.1", "uptime": state["started_at"]}

@app.get("/status")
def status():
    return {"orchestrator": "SuiteV17", "status": "running"}

@app.post("/run_task")
def run_task(task: Task):
    state["history"].append(task.name)
    return {"ok": True, "task": task.name}

@app.get("/agents")
def agents():
    return {"agents": ["Gene1799Agent", "BrowserAgent", "VideoAgent"]}

@app.post("/agents/register")
def register(name: str):
    state["agents"][name] = {"status": "active"}
    return {"ok": True, "registered": name}

if __name__ == "__main__":
    print("Orchestrator starting on port 8000")
    uvicorn.run(app, host="127.0.0.1", port=8000)
