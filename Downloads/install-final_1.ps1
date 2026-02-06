# ══════════════════════════════════════════════════════════════════
# GENE1799 AI SYSTEM - INSTALLAZIONE FINALE
# Copia TUTTO e incolla in PowerShell
# ══════════════════════════════════════════════════════════════════

$aiPath = "D:\C1799HubEnhanced\ai-integration"
Write-Host "`n[INSTALL] Gene1799 AI System..." -ForegroundColor Green

# 1. Crea cartelle
@("core","agents","providers","config","scripts","dashboard","data","data\agents") | ForEach-Object {
    New-Item -ItemType Directory -Path "$aiPath\$_" -Force | Out-Null
}

# 2. Package.json
@'
{
  "name": "gene1799-ai-integration",
  "version": "2.0.0",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": {
    "axios": "^1.6.0",
    "cors": "^2.8.5", 
    "express": "^4.18.2",
    "ws": "^8.14.2"
  }
}
'@ | Set-Content "$aiPath\package.json" -Encoding UTF8

# 3. SERVER.JS PRINCIPALE (compatibile con la tua dashboard)
@'
const express = require("express");
const cors = require("cors");
const http = require("http");
const WebSocket = require("ws");
const path = require("path");

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(cors());
app.use(express.json());
app.use(express.static(__dirname));

// STATO SISTEMA
const state = {
  agents: [
    { id: 1, name: "TradingAgent", type: "trading", status: "active", experience: 0, communications: 0 },
    { id: 2, name: "NFTAgent", type: "nft", status: "active", experience: 0, communications: 0 },
    { id: 3, name: "WorkflowAgent", type: "workflow", status: "active", experience: 0, communications: 0 },
    { id: 4, name: "SystemAgent", type: "system", status: "active", experience: 0, communications: 0 },
    { id: 5, name: "DataAgent", type: "data", status: "idle", experience: 0, communications: 0 }
  ],
  stats: { totalAgents: 5, activeAgents: 4, totalExperience: 0, communications: 0 },
  startTime: Date.now()
};

// WEBSOCKET
const clients = new Set();
wss.on("connection", ws => {
  console.log("[WS] Client connesso");
  clients.add(ws);
  ws.send(JSON.stringify({ type: "init", agents: state.agents, stats: state.stats }));
  ws.on("close", () => clients.delete(ws));
});

function broadcast(data) {
  const msg = JSON.stringify(data);
  clients.forEach(c => { if(c.readyState === WebSocket.OPEN) c.send(msg); });
}

// API ENDPOINTS
app.get("/integration/health", (req, res) => res.json({ 
  status: "online", 
  service: "Gene1799 AI Integration",
  version: "2.0.0",
  systems: { hubEnhanced: "http://localhost:3000", aiIntegration: "active" }
}));

app.get("/api/status", (req, res) => res.json({ status: "online", ...state, uptime: Date.now() - state.startTime }));
app.get("/api/agents", (req, res) => res.json(state.agents));
app.get("/api/agents/health", (req, res) => res.json({ status: "online", totalAgents: state.agents.length, activeAgents: state.stats.activeAgents, agents: state.agents }));
app.get("/api/agents/stats", (req, res) => res.json(state.stats));

app.post("/api/agents/train", (req, res) => {
  state.agents.forEach(a => { a.experience += 10; a.status = "active"; });
  state.stats.totalExperience += 50;
  state.stats.activeAgents = state.agents.filter(a => a.status === "active").length;
  broadcast({ type: "training", stats: state.stats });
  console.log("[TRAIN] Agenti addestrati! Exp totale:", state.stats.totalExperience);
  res.json({ success: true, message: "Training completato", totalExperience: state.stats.totalExperience });
});

app.post("/api/agents/auto-manage", (req, res) => {
  console.log("[AUTO] Auto-management avviato");
  res.json({ success: true, message: "Auto-management attivo" });
});

app.post("/api/agents/communicate", (req, res) => {
  state.stats.communications++;
  const from = state.agents[Math.floor(Math.random() * state.agents.length)];
  const to = state.agents[Math.floor(Math.random() * state.agents.length)];
  from.communications++;
  broadcast({ type: "communication", from: from.name, to: to.name });
  console.log("[COMM]", from.name, "->", to.name);
  res.json({ success: true, communications: state.stats.communications });
});

app.post("/api/agents/:agent/query", (req, res) => {
  const agent = state.agents.find(a => a.name.toLowerCase().includes(req.params.agent.toLowerCase()));
  if(!agent) return res.status(404).json({ error: "Agent not found" });
  agent.experience++;
  state.stats.totalExperience++;
  console.log("[QUERY]", agent.name, "- Prompt:", req.body.prompt?.substring(0,50));
  res.json({ success: true, agent: agent.name, response: "[" + agent.name + "] Elaborato: " + (req.body.prompt || "ok").substring(0,100) });
});

app.get("/api/report", (req, res) => {
  res.setHeader("Content-Disposition", "attachment; filename=gene1799-report.json");
  res.json({ generated: new Date().toISOString(), stats: state.stats, agents: state.agents });
});

// SERVE DASHBOARD
app.get("/", (req, res) => res.sendFile(path.join(__dirname, "dashboard.html")));

// START
server.listen(3002, () => {
  console.log("");
  console.log("╔════════════════════════════════════════════════════════════════╗");
  console.log("║   GENE1799 AI INTEGRATION SERVER v2.0 - ONLINE                 ║");
  console.log("╚════════════════════════════════════════════════════════════════╝");
  console.log("");
  console.log("[OK] Server:    http://localhost:3002");
  console.log("[OK] Dashboard: http://localhost:3002/dashboard.html");
  console.log("[OK] Health:    http://localhost:3002/integration/health");
  console.log("[OK] WebSocket: ws://localhost:3002");
  console.log("");
});
'@ | Set-Content "$aiPath\server.js" -Encoding UTF8

Write-Host "[OK] File creati!" -ForegroundColor Green

# 4. Installa e avvia
Set-Location $aiPath
Write-Host "[INSTALL] npm install..." -ForegroundColor Cyan
npm install

Write-Host "`n[START] Avvio server..." -ForegroundColor Green
node server.js
