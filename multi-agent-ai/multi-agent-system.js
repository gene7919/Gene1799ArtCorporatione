const MultiAgentManager = require("./agent-manager");
const DrugDiscoveryAgent = require("./drug-discovery-agent");
const ToxicityAgent = require("./toxicity-agent");
const ChelationAgent = require("./chelation-agent");
const ClinicalTrialsAgent = require("./clinical-trials-agent");

class Gene1799MultiAgentSystem {
    constructor() {
        console.log("╔══════════════════════════════════════════════╗");
        console.log("║  Gene1799 Multi-Agent AI System             ║");
        console.log("╚══════════════════════════════════════════════╝\n");

        this.manager = new MultiAgentManager();
        this.manager.registerAgent("DrugDiscovery", new DrugDiscoveryAgent());
        this.manager.registerAgent("Toxicity", new ToxicityAgent());
        this.manager.registerAgent("Chelation", new ChelationAgent());
        this.manager.registerAgent("ClinicalTrials", new ClinicalTrialsAgent());

        console.log("\n✅ 4 agenti AI inizializzati\n");
    }

    async analyzeCompound(compound) {
        console.log("╔══════════════════════════════════════════════╗");
        console.log("║  Analisi Multi-Agente                       ║");
        console.log("╚══════════════════════════════════════════════╝");

        const tasks = ["drug_discovery", "toxicity", "chelation", "clinical"];
        const results = [];

        for (const task of tasks) {
            const result = await this.manager.executeTask(task, compound);
            results.push(result);
        }

        const avgScore = results.reduce((sum, r) => 
            sum + parseFloat(r.recommendation.average_score), 0
        ) / results.length;

        console.log("\n\n╔══════════════════════════════════════════════╗");
        console.log("║  Report Finale                              ║");
        console.log("╚══════════════════════════════════════════════╝\n");
        console.log(`📊 Score Complessivo: ${avgScore.toFixed(2)}/100`);
        console.log(`🎯 Raccomandazione: ${avgScore > 75 ? "PROCEDI" : "OTTIMIZZA"}\n`);

        return { avgScore, results };
    }
}

if (require.main === module) {
    const system = new Gene1799MultiAgentSystem();
    
    system.analyzeCompound({
        name: "Gene1799-TEPA-v2",
        target: "Neuroblastoma"
    }).catch(err => console.error("Errore:", err));
}

module.exports = Gene1799MultiAgentSystem;
