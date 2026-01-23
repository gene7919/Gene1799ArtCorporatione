const fs = require("fs");

class MultiAgentManager {
    constructor() {
        this.agents = new Map();
        console.log("🎯 Multi-Agent Manager inizializzato\n");
    }

    registerAgent(name, agent) {
        this.agents.set(name, agent);
        console.log(`✅ ${name} registrato`);
    }

    async executeTask(taskType, params) {
        console.log(`\n🚀 Task: ${taskType}`);
        const results = [];
        
        for (const [name, agent] of this.agents) {
            if (agent.canHandle(taskType)) {
                console.log(`\n🤖 ${name} in esecuzione...`);
                const result = await agent.execute(params);
                results.push({ agent: name, result });
            }
        }

        const scores = results.map(r => r.result.score || 70);
        const avg = scores.reduce((a, b) => a + b, 0) / scores.length;

        return {
            agents_consulted: results.length,
            results: results,
            recommendation: {
                average_score: avg.toFixed(2),
                consensus: avg > 75 ? "Alta priorità" : "Media priorità"
            }
        };
    }
}

module.exports = MultiAgentManager;
