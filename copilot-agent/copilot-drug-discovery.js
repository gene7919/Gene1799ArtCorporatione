const fs = require('fs');
const path = require('path');
const Gene1799CopilotAgent = require('./anticancer-ai-engine');

const metals = ['Cu2+','Fe3+','Pb2+','Hg2+','Cd2+'];
const exposures = ['ingestione','inalazione','cutanea'];
const cancers = ['Neuroblastoma','Leucemia','Polmonare','Epatica','Rene'];

async function runAllScenarios() {
    const engine = new Gene1799CopilotAgent();

    for (const metal of metals) {
        for (const exposure of exposures) {
            for (const cancer of cancers) {

                console.log(\➡️ Scenario: \ | \ | \\);

                const folder = path.join(__dirname,'results',\\_\_\\);
                if (!fs.existsSync(folder)) fs.mkdirSync(folder, { recursive: true });

                const baseChelator = { nome:'TEPA', smiles:'NCCNCCNCCNCCN' };
                const interaction = await engine.simulateInteraction(baseChelator, metal, exposure);
                fs.writeFileSync(path.join(folder,'interaction.json'), JSON.stringify(interaction,null,2));

                const novel = await engine.generateNovelChelator({targetMetal: metal});
                fs.writeFileSync(path.join(folder,'novel-chelator.json'), JSON.stringify(novel,null,2));

                console.log(\✅ Risultati salvati in: \\n\);
            }
        }
    }
    console.log('🎯 Tutti gli scenari completati!');
}

if (require.main === module) {
    runAllScenarios().catch(err => console.error(err));
}
