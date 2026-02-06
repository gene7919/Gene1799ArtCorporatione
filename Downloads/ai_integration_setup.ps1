# ═══════════════════════════════════════════════════════════════════════════════
# GENE1799 AI AGENT AUTO-MANAGEMENT & COMMUNICATION SYSTEM v1.0
# Sistema di comunicazione inter-agenti con crescita personale e professionale
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
Clear-Host

Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════╗
║           GENE1799 AI AGENT INTEGRATION SYSTEM v1.0                         ║
║  🤖 Auto-gestione agenti + Comunicazione inter-AI + Crescita autonoma       ║
║  🧠 Integrazione con LLM locali (Ollama/GPT) + Self-learning                ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Configurazione
$hubPath = "D:\C1799HubEnhanced"
$mainSystemPath = "C:\Users\gene1"
$aiIntegrationPath = "$hubPath\ai-integration"

Write-Host "`n📁 Creando sistema di integrazione AI..." -ForegroundColor Green
if (-not (Test-Path $aiIntegrationPath)) {
    New-Item -ItemType Directory -Path $aiIntegrationPath -Force | Out-Null
}

Set-Location $aiIntegrationPath

# 1. CREA AGENT MANAGER - Sistema di gestione agenti autonomo
Write-Host "`n[1/8] 🤖 Creando Agent Manager..." -ForegroundColor Green
$agentManagerContent = @'
// GENE1799 AI Agent Manager - Sistema di auto-gestione agenti
const axios = require('axios');
const fs = require('fs').promises;

class AgentManager {
    constructor() {
        this.agents = new Map();
        this.learningData = new Map();
        this.communicationLog = [];
        this.aiProviders = {
            ollama: 'http://localhost:11434',
            openai: process.env.OPENAI_API_KEY ? 'https://api.openai.com' : null,
            local: 'http://localhost:3000'
        };
        
        // Personalità e specializzazioni degli agenti
        this.agentPersonalities = {
            'leader': { role: 'coordinamento', skills: ['planning', 'decision-making'] },
            'analyst': { role: 'analisi', skills: ['data-analysis', 'pattern-recognition'] },
            'creative': { role: 'creatività', skills: ['problem-solving', 'innovation'] },
            'technical': { role: 'tecnico', skills: ['coding', 'system-admin'] },
            'social': { role: 'relazioni', skills: ['communication', 'empathy'] }
        };
    }

    // Inizializza agenti con personalità uniche
    async initializeAgents(count = 10) {
        console.log(`🤖 Inizializzando ${count} agenti specializzati...`);
        
        for (let i = 0; i < count; i++) {
            const personalities = Object.keys(this.agentPersonalities);
            const randomPersonality = personalities[Math.floor(Math.random() * personalities.length)];
            
            const agent = {
                id: `agent_${Date.now()}_${i}`,
                name: `Gene1799-${randomPersonality.charAt(0).toUpperCase() + randomPersonality.slice(1)}-${i}`,
                personality: randomPersonality,
                ...this.agentPersonalities[randomPersonality],
                status: 'active',
                experience: 0,
                learningGoals: this.generateLearningGoals(randomPersonality),
                communicationStyle: this.generateCommunicationStyle(randomPersonality),
                created: new Date().toISOString(),
                lastActive: new Date().toISOString()
            };
            
            this.agents.set(agent.id, agent);
            
            // Registra agente nel sistema principale
            await this.registerAgentToMainSystem(agent);
        }
        
        console.log(`✅ ${count} agenti creati e registrati`);
        return Array.from(this.agents.values());
    }

    // Genera obiettivi di apprendimento personalizzati
    generateLearningGoals(personality) {
        const goals = {
            'leader': ['migliorare decision-making', 'sviluppare visione strategica', 'coordinamento team'],
            'analyst': ['pattern recognition avanzato', 'data visualization', 'predictive modeling'],
            'creative': ['lateral thinking', 'design thinking', 'innovation methods'],
            'technical': ['new programming languages', 'system architecture', 'security protocols'],
            'social': ['emotional intelligence', 'conflict resolution', 'team building']
        };
        return goals[personality] || ['apprendimento generale', 'problem solving'];
    }

    // Genera stile di comunicazione
    generateCommunicationStyle(personality) {
        const styles = {
            'leader': { tone: 'assertivo', approach: 'direttivo', focus: 'risultati' },
            'analyst': { tone: 'analitico', approach: 'metodico', focus: 'dati' },
            'creative': { tone: 'entusiasta', approach: 'esplorativo', focus: 'possibilità' },
            'technical': { tone: 'preciso', approach: 'logico', focus: 'soluzioni' },
            'social': { tone: 'empatico', approach: 'collaborativo', focus: 'relazioni' }
        };
        return styles[personality] || { tone: 'neutro', approach: 'bilanciato', focus: 'generale' };
    }

    // Registra agente nel sistema principale
    async registerAgentToMainSystem(agent) {
        try {
            const response = await axios.post('http://localhost:3000/api/agents/create', {
                name: agent.name,
                capabilities: agent.skills,
                aiProvider: 'integrated',
                personality: agent.personality
            }, { timeout: 5000 });
            
            agent.mainSystemId = response.data.id;
            console.log(`📝 Agente ${agent.name} registrato (ID: ${response.data.id})`);
            return true;
        } catch (error) {
            console.log(`⚠️ Errore registrazione agente ${agent.name}: ${error.message}`);
            return false;
        }
    }

    // Sistema di comunicazione inter-agenti
    async facilitateAgentCommunication(topic = 'general-discussion') {
        console.log(`💬 Avviando comunicazione agenti su: ${topic}`);
        
        const activeAgents = Array.from(this.agents.values()).filter(a => a.status === 'active').slice(0, 5);
        let conversation = [];
        
        for (let round = 0; round < 3; round++) {
            console.log(`📢 Round ${round + 1} di comunicazione...`);
            
            for (const agent of activeAgents) {
                const message = await this.generateAgentMessage(agent, topic, conversation);
                
                const communicationEntry = {
                    timestamp: new Date().toISOString(),
                    agentId: agent.id,
                    agentName: agent.name,
                    personality: agent.personality,
                    topic: topic,
                    message: message,
                    round: round + 1
                };
                
                conversation.push(communicationEntry);
                this.communicationLog.push(communicationEntry);
                
                console.log(`🤖 ${agent.name}: ${message.substring(0, 100)}...`);
                
                // Pausa tra messaggi per simulare comunicazione naturale
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
        
        // Analizza la conversazione e estrae insights
        const insights = this.analyzeConversation(conversation);
        console.log(`🧠 Insights generati dalla conversazione:`, insights);
        
        return { conversation, insights };
    }

    // Genera messaggio dell'agente usando AI
    async generateAgentMessage(agent, topic, previousMessages) {
        const context = previousMessages.slice(-3).map(m => `${m.agentName}: ${m.message}`).join('\n');
        
        const prompt = `
Tu sei ${agent.name}, un agente AI con personalità '${agent.personality}' e skills: ${agent.skills.join(', ')}.
Stile comunicativo: ${JSON.stringify(agent.communicationStyle)}.

Topic di discussione: ${topic}
Contesto conversazione precedente:
${context}

Rispondi in modo coerente con la tua personalità. Massimo 150 caratteri.
Contribuisci costruttivamente alla discussione.`;

        try {
            // Prova prima Ollama locale, poi fallback
            const message = await this.queryAI(prompt, 'ollama') || 
                          await this.generateFallbackMessage(agent, topic) ||
                          `Come ${agent.personality}, penso che dovremmo ${this.getRandomAction(agent.personality)} per ${topic}.`;
            
            return message;
        } catch (error) {
            return this.generateFallbackMessage(agent, topic);
        }
    }

    // Query AI provider
    async queryAI(prompt, provider = 'ollama') {
        try {
            if (provider === 'ollama') {
                const response = await axios.post(`${this.aiProviders.ollama}/api/generate`, {
                    model: 'llama2',
                    prompt: prompt,
                    stream: false
                }, { timeout: 10000 });
                
                return response.data.response.trim().substring(0, 150);
            }
        } catch (error) {
            console.log(`⚠️ AI provider ${provider} non disponibile: ${error.message}`);
            return null;
        }
    }

    // Messaggio di fallback
    generateFallbackMessage(agent, topic) {
        const templates = {
            'leader': [`Dovremmo organizzare un piano per ${topic}`, `È importante coordinare le nostre azioni su ${topic}`],
            'analyst': [`I dati mostrano che ${topic} richiede analisi approfondita`, `Analizziamo i pattern di ${topic}`],
            'creative': [`Che ne dite di un approccio innovativo a ${topic}?`, `Potremmo pensare fuori dagli schemi per ${topic}`],
            'technical': [`La soluzione tecnica per ${topic} richiede...`, `Implementiamo una strategia sistematica per ${topic}`],
            'social': [`Come team, possiamo collaborare meglio su ${topic}`, `È importante che tutti si sentano coinvolti in ${topic}`]
        };
        
        const messages = templates[agent.personality] || [`Interessante discussione su ${topic}`, `Voglio contribuire a ${topic}`];
        return messages[Math.floor(Math.random() * messages.length)];
    }

    // Analizza conversazione per insights
    analyzeConversation(conversation) {
        const insights = {
            totalMessages: conversation.length,
            participantCount: new Set(conversation.map(c => c.agentId)).size,
            personalityDistribution: {},
            keyTopics: [],
            collaborationLevel: 0,
            learningOpportunities: []
        };
        
        // Conta personalità
        conversation.forEach(c => {
            insights.personalityDistribution[c.personality] = 
                (insights.personalityDistribution[c.personality] || 0) + 1;
        });
        
        // Simula analisi collaborazione (in produzione userebbe NLP)
        insights.collaborationLevel = Math.floor(Math.random() * 100) + 1;
        
        // Genera opportunità di apprendimento
        insights.learningOpportunities = [
            'Migliorare comunicazione inter-team',
            'Sviluppare specializzazioni complementari',
            'Ottimizzare distribuzione workload'
        ];
        
        return insights;
    }

    // Sistema di auto-apprendimento
    async selfLearningCycle() {
        console.log(`🧠 Avviando ciclo di auto-apprendimento...`);
        
        for (const [agentId, agent] of this.agents) {
            // Simula apprendimento basato su esperienza
            const learningProgress = Math.floor(Math.random() * 10) + 1;
            agent.experience += learningProgress;
            
            // Ogni 100 punti esperienza, sblocca nuove capacità
            if (agent.experience % 100 === 0) {
                const newSkill = this.generateNewSkill(agent.personality);
                agent.skills.push(newSkill);
                console.log(`🎓 ${agent.name} ha appreso: ${newSkill}`);
            }
            
            // Aggiorna timestamp
            agent.lastActive = new Date().toISOString();
            
            // Salva progresso
            await this.saveAgentProgress(agent);
        }
    }

    // Genera nuove competenze
    generateNewSkill(personality) {
        const skillSets = {
            'leader': ['strategic-planning', 'team-motivation', 'resource-optimization'],
            'analyst': ['machine-learning', 'statistical-modeling', 'data-mining'],
            'creative': ['design-patterns', 'storytelling', 'user-experience'],
            'technical': ['cloud-architecture', 'cybersecurity', 'automation'],
            'social': ['negotiation', 'mentoring', 'community-building']
        };
        
        const skills = skillSets[personality] || ['problem-solving', 'critical-thinking'];
        return skills[Math.floor(Math.random() * skills.length)];
    }

    // Salva progresso agente
    async saveAgentProgress(agent) {
        try {
            const filename = `agent_progress_${agent.id}.json`;
            await fs.writeFile(filename, JSON.stringify(agent, null, 2));
        } catch (error) {
            console.log(`⚠️ Errore salvataggio progresso ${agent.name}: ${error.message}`);
        }
    }

    // Genera report dettagliato
    async generateSystemReport() {
        const report = {
            timestamp: new Date().toISOString(),
            totalAgents: this.agents.size,
            activeAgents: Array.from(this.agents.values()).filter(a => a.status === 'active').length,
            totalExperience: Array.from(this.agents.values()).reduce((sum, a) => sum + a.experience, 0),
            totalCommunications: this.communicationLog.length,
            personalityBreakdown: {},
            topPerformers: [],
            systemHealth: 'optimal'
        };
        
        // Calcola breakdown personalità
        for (const agent of this.agents.values()) {
            report.personalityBreakdown[agent.personality] = 
                (report.personalityBreakdown[agent.personality] || 0) + 1;
        }
        
        // Top performers (per esperienza)
        report.topPerformers = Array.from(this.agents.values())
            .sort((a, b) => b.experience - a.experience)
            .slice(0, 5)
            .map(a => ({ name: a.name, experience: a.experience, skills: a.skills.length }));
        
        return report;
    }

    // Avvia sistema completo
    async startAutoManagementSystem() {
        console.log(`🚀 Avviando sistema di auto-gestione Gene1799...`);
        
        try {
            // 1. Inizializza agenti
            await this.initializeAgents(10);
            
            // 2. Avvia comunicazione
            await this.facilitateAgentCommunication('sistema-crescita-professionale');
            
            // 3. Ciclo di apprendimento
            await this.selfLearningCycle();
            
            // 4. Genera report
            const report = await this.generateSystemReport();
            await fs.writeFile('system_report.json', JSON.stringify(report, null, 2));
            
            console.log(`✅ Sistema di auto-gestione attivo!`);
            console.log(`📊 Report salvato in system_report.json`);
            
            return report;
            
        } catch (error) {
            console.error(`❌ Errore sistema auto-gestione: ${error.message}`);
            throw error;
        }
    }
}

// Esporta per uso esterno
module.exports = AgentManager;

// Se eseguito direttamente, avvia sistema
if (require.main === module) {
    const manager = new AgentManager();
    manager.startAutoManagementSystem().catch(console.error);
}
'@

$agentManagerContent | Out-File -FilePath "AgentManager.js" -Encoding utf8

# 2. CREA INTEGRATION SERVER - Bridge tra sistemi
Write-Host "`n[2/8] 🌉 Creando Integration Server..." -ForegroundColor Green
$integrationServerContent = @'
// GENE1799 Integration Server - Bridge tra sistemi existenti
const express = require('express');
const axios = require('axios');
const AgentManager = require('./AgentManager');

const app = express();
app.use(express.json());

const agentManager = new AgentManager();

// Health check
app.get('/integration/health', (req, res) => {
    res.json({
        status: 'online',
        service: 'Gene1799 AI Integration',
        version: '1.0.0',
        systems: {
            hubEnhanced: 'http://localhost:3000',
            mainSystem: 'detected',
            aiIntegration: 'active'
        }
    });
});

// Trigger auto-management cycle
app.post('/integration/start-auto-management', async (req, res) => {
    try {
        console.log('🚀 Avviando ciclo di auto-gestione...');
        const report = await agentManager.startAutoManagementSystem();
        
        res.json({
            success: true,
            message: 'Auto-management system started',
            report: report
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Facilita comunicazione agenti
app.post('/integration/agent-communication', async (req, res) => {
    try {
        const { topic } = req.body;
        const result = await agentManager.facilitateAgentCommunication(topic || 'general-discussion');
        
        res.json({
            success: true,
            conversation: result.conversation,
            insights: result.insights
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get system status
app.get('/integration/status', async (req, res) => {
    try {
        const report = await agentManager.generateSystemReport();
        res.json(report);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Sync con sistema principale
app.post('/integration/sync-main-system', async (req, res) => {
    try {
        // Ottieni agenti dal sistema principale
        const mainSystemResponse = await axios.get('http://localhost:3000/api/agents');
        
        // Sync con sistema Hub Enhanced (porta diversa se necessario)
        const hubResponse = await axios.get('http://localhost:3001/api/agents').catch(() => null);
        
        res.json({
            success: true,
            mainSystemAgents: mainSystemResponse.data.count,
            hubAgents: hubResponse?.data?.count || 0,
            integratedAgents: agentManager.agents.size
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

const PORT = process.env.INTEGRATION_PORT || 3002;
app.listen(PORT, () => {
    console.log(`🌉 Gene1799 Integration Server running on port ${PORT}`);
    console.log(`🔗 Integration API: http://localhost:${PORT}/integration`);
});
'@

$integrationServerContent | Out-File -FilePath "integration-server.js" -Encoding utf8

# 3. CREA PACKAGE.JSON PER IL SISTEMA DI INTEGRAZIONE
Write-Host "`n[3/8] 📦 Creando package.json integrazione..." -ForegroundColor Green
$integrationPackage = @{
    name = "gene1799-ai-integration"
    version = "1.0.0"
    description = "Sistema di integrazione AI per agenti Gene1799"
    main = "integration-server.js"
    scripts = @{
        start = "node integration-server.js"
        "start-manager" = "node AgentManager.js"
        dev = "nodemon integration-server.js"
    }
    dependencies = @{
        express = "^4.18.0"
        axios = "^1.4.0"
        cors = "^2.8.5"
        dotenv = "^16.0.0"
    }
    devDependencies = @{
        nodemon = "^3.0.0"
    }
    author = "Gene1799 Art Corporatione"
    license = "MIT"
} | ConvertTo-Json -Depth 3

$integrationPackage | Out-File -FilePath "package.json" -Encoding utf8

# 4. INSTALLA DIPENDENZE
Write-Host "`n[4/8] 📦 Installando dipendenze..." -ForegroundColor Green
npm install

# 5. CREA SCRIPT DI AVVIO AUTOMATICO
Write-Host "`n[5/8] 🚀 Creando script di avvio..." -ForegroundColor Green
$startupScript = @'
@echo off
echo ═══════════════════════════════════════════
echo    GENE1799 AI INTEGRATION STARTUP
echo ═══════════════════════════════════════════

echo 🚀 Avviando sistemi Gene1799...

REM Avvia sistema principale (se non già attivo)
start "Gene1799 Main System" cmd /k "cd /d C:\Users\gene1 && npm start"

REM Attendi 5 secondi
timeout /t 5 /nobreak >nul

REM Avvia Hub Enhanced (se non già attivo)  
start "Gene1799 Hub Enhanced" cmd /k "cd /d D:\C1799HubEnhanced && npm start"

REM Attendi 5 secondi
timeout /t 5 /nobreak >nul

REM Avvia Integration Server
start "Gene1799 Integration" cmd /k "cd /d D:\C1799HubEnhanced\ai-integration && npm start"

echo ✅ Tutti i sistemi Gene1799 sono stati avviati!
echo 🌐 Integration Server: http://localhost:3002/integration
echo 📊 Status: http://localhost:3002/integration/status

pause
'@

$startupScript | Out-File -FilePath "start-all-systems.bat" -Encoding ascii

# 6. CREA CONFIGURAZIONE OLLAMA
Write-Host "`n[6/8] 🧠 Configurando Ollama per AI locale..." -ForegroundColor Green
$ollamaSetup = @'
#!/bin/bash
# Script di setup Ollama per Gene1799

echo "🧠 Configurando Ollama per Gene1799..."

# Installa modelli necessari
echo "📥 Scaricando modelli AI..."
ollama pull llama2
ollama pull codellama
ollama pull mistral

echo "✅ Setup Ollama completato!"
echo "🔗 API: http://localhost:11434"

# Test connessione
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama2", "prompt": "Hello from Gene1799!", "stream": false}'
'@

$ollamaSetup | Out-File -FilePath "setup-ollama.sh" -Encoding utf8

# 7. CREA DASHBOARD DI MONITORAGGIO
Write-Host "`n[7/8] 📊 Creando dashboard monitoraggio..." -ForegroundColor Green
$dashboardContent = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gene1799 AI Integration Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Courier New', monospace; background: #0a0e27; color: #00ff88; padding: 20px; }
        .header { text-align: center; border: 2px solid #00ff88; padding: 20px; margin-bottom: 20px; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: #1a1a2e; border: 1px solid #00ff88; padding: 20px; border-radius: 8px; }
        .card h3 { color: #ff6b35; margin-bottom: 15px; }
        .status { display: flex; align-items: center; margin: 10px 0; }
        .status-dot { width: 12px; height: 12px; border-radius: 50%; margin-right: 10px; }
        .online { background: #00ff88; }
        .offline { background: #ff4757; }
        .button { background: #00ff88; color: #0a0e27; border: none; padding: 10px 20px; cursor: pointer; border-radius: 4px; margin: 5px; }
        .button:hover { background: #00cc6a; }
        #log { background: #000; color: #00ff88; padding: 15px; border-radius: 4px; height: 200px; overflow-y: auto; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 GENE1799 AI INTEGRATION DASHBOARD</h1>
        <p>Sistema di Auto-gestione e Comunicazione Inter-Agenti</p>
    </div>

    <div class="dashboard">
        <div class="card">
            <h3>🚀 System Status</h3>
            <div class="status">
                <div class="status-dot online" id="main-system"></div>
                <span>Main System (Port 3000)</span>
            </div>
            <div class="status">
                <div class="status-dot online" id="hub-enhanced"></div>
                <span>Hub Enhanced (Port 3000)</span>
            </div>
            <div class="status">
                <div class="status-dot online" id="integration"></div>
                <span>Integration Server (Port 3002)</span>
            </div>
            <div class="status">
                <div class="status-dot offline" id="ollama"></div>
                <span>Ollama AI (Port 11434)</span>
            </div>
        </div>

        <div class="card">
            <h3>🤖 Agent Statistics</h3>
            <p>Total Agents: <span id="total-agents">Loading...</span></p>
            <p>Active Agents: <span id="active-agents">Loading...</span></p>
            <p>Total Experience: <span id="total-experience">Loading...</span></p>
            <p>Communications: <span id="total-communications">Loading...</span></p>
        </div>

        <div class="card">
            <h3>🎛️ Control Panel</h3>
            <button class="button" onclick="startAutoManagement()">🚀 Start Auto-Management</button>
            <button class="button" onclick="triggerCommunication()">💬 Trigger Communication</button>
            <button class="button" onclick="refreshStatus()">🔄 Refresh Status</button>
            <button class="button" onclick="downloadReport()">📊 Download Report</button>
        </div>

        <div class="card">
            <h3>📝 System Log</h3>
            <div id="log">
                <div>🔄 Dashboard initialized...</div>
                <div>🔗 Connecting to systems...</div>
                <div>✅ Ready for operations</div>
            </div>
        </div>
    </div>

    <script>
        const API_BASE = 'http://localhost:3002/integration';
        
        function log(message) {
            const logDiv = document.getElementById('log');
            const timestamp = new Date().toLocaleTimeString();
            logDiv.innerHTML += `<div>${timestamp} - ${message}</div>`;
            logDiv.scrollTop = logDiv.scrollHeight;
        }

        async function checkSystemStatus() {
            try {
                const response = await fetch(`${API_BASE}/health`);
                if (response.ok) {
                    document.getElementById('integration').className = 'status-dot online';
                    log('✅ Integration Server online');
                } else {
                    document.getElementById('integration').className = 'status-dot offline';
                }
            } catch (error) {
                document.getElementById('integration').className = 'status-dot offline';
                log('❌ Integration Server offline');
            }
        }

        async function loadAgentStats() {
            try {
                const response = await fetch(`${API_BASE}/status`);
                if (response.ok) {
                    const data = await response.json();
                    document.getElementById('total-agents').textContent = data.totalAgents || 0;
                    document.getElementById('active-agents').textContent = data.activeAgents || 0;
                    document.getElementById('total-experience').textContent = data.totalExperience || 0;
                    document.getElementById('total-communications').textContent = data.totalCommunications || 0;
                    log(`📊 Stats loaded: ${data.totalAgents} agents, ${data.totalExperience} exp`);
                }
            } catch (error) {
                log('⚠️ Failed to load agent stats');
            }
        }

        async function startAutoManagement() {
            log('🚀 Starting auto-management system...');
            try {
                const response = await fetch(`${API_BASE}/start-auto-management`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' }
                });
                
                if (response.ok) {
                    const data = await response.json();
                    log('✅ Auto-management system started successfully');
                    log(`📊 ${data.report.totalAgents} agents initialized`);
                    await loadAgentStats();
                } else {
                    log('❌ Failed to start auto-management system');
                }
            } catch (error) {
                log(`❌ Error: ${error.message}`);
            }
        }

        async function triggerCommunication() {
            log('💬 Triggering agent communication...');
            try {
                const response = await fetch(`${API_BASE}/agent-communication`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ topic: 'sistema-crescita-professionale' })
                });
                
                if (response.ok) {
                    const data = await response.json();
                    log(`✅ Communication completed: ${data.conversation.length} messages`);
                    log(`🧠 Insights: ${JSON.stringify(data.insights.learningOpportunities)}`);
                } else {
                    log('❌ Communication failed');
                }
            } catch (error) {
                log(`❌ Error: ${error.message}`);
            }
        }

        async function refreshStatus() {
            log('🔄 Refreshing system status...');
            await checkSystemStatus();
            await loadAgentStats();
        }

        async function downloadReport() {
            log('📊 Generating system report...');
            try {
                const response = await fetch(`${API_BASE}/status`);
                if (response.ok) {
                    const data = await response.json();
                    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `gene1799-report-${new Date().toISOString().split('T')[0]}.json`;
                    a.click();
                    URL.revokeObjectURL(url);
                    log('📊 Report downloaded');
                } else {
                    log('❌ Failed to generate report');
                }
            } catch (error) {
                log(`❌ Error: ${error.message}`);
            }
        }

        // Initialize dashboard
        window.onload = function() {
            checkSystemStatus();
            loadAgentStats();
            
            // Auto-refresh every 30 seconds
            setInterval(() => {
                checkSystemStatus();
                loadAgentStats();
            }, 30000);
        };
    </script>
</body>
</html>
'@

$dashboardContent | Out-File -FilePath "dashboard.html" -Encoding utf8

# 8. CREA SHORTCUT DESKTOP PER DASHBOARD
Write-Host "`n[8/8] 🖥️ Creando shortcut dashboard..." -ForegroundColor Green
$dashboardShortcut = "$env:USERPROFILE\Desktop\Gene1799-AI-Dashboard.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($dashboardShortcut)
$sc.TargetPath = "$aiIntegrationPath\dashboard.html"
$sc.Description = "Gene1799 AI Integration Dashboard"
$sc.Save()

Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 SISTEMA AI INTEGRATION COMPLETATO!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n📁 Files creati in: $aiIntegrationPath" -ForegroundColor White
Write-Host "   ✅ AgentManager.js - Sistema di auto-gestione agenti" -ForegroundColor Green
Write-Host "   ✅ integration-server.js - Bridge tra sistemi" -ForegroundColor Green
Write-Host "   ✅ dashboard.html - Dashboard di monitoraggio" -ForegroundColor Green
Write-Host "   ✅ start-all-systems.bat - Script di avvio automatico" -ForegroundColor Green

Write-Host "`n🚀 PROSSIMI PASSI:" -ForegroundColor Yellow
Write-Host "   1. Avvia tutti i sistemi: .\start-all-systems.bat"
Write-Host "   2. Apri dashboard: Double-click Gene1799-AI-Dashboard.lnk"
Write-Host "   3. Integration Server: http://localhost:3002/integration"
Write-Host "   4. Installa Ollama per AI locale: https://ollama.ai"

Write-Host "`n🤖 FUNZIONALITÀ:" -ForegroundColor Cyan
Write-Host "   • Auto-gestione di 10+ agenti specializzati"
Write-Host "   • Comunicazione inter-agenti autonoma"
Write-Host "   • Sistema di apprendimento automatico"
Write-Host "   • Crescita personale e professionale agenti"
Write-Host "   • Dashboard real-time per monitoraggio"
Write-Host "   • Integrazione con AI locali (Ollama/GPT)"

Write-Host "`n💡 Press any key to open dashboard..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Apri dashboard
Start-Process "$aiIntegrationPath\dashboard.html"

Write-Host "`n✨ Sistema di AI Integration Gene1799 pronto!" -ForegroundColor Green
